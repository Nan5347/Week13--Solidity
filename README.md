# Week13--Solidity
 learning how to upload website to github
ปฏิบัติการการเขียน smart contract
อธิบายโค้ดที่ป้องกันการ lock เงินไว้ใน contract

function _checkWinnerAndPay() private {
    uint p0Choice = player_choice[players[0]];
    uint p1Choice = player_choice[players[1]];
    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);

    if (_isWinner(p0Choice, p1Choice)) {
        account0.transfer(reward);  // ผู้เล่น 0 ชนะ รับเงินทั้งหมด
    } else if (_isWinner(p1Choice, p0Choice)) {
        account1.transfer(reward);  // ผู้เล่น 1 ชนะ รับเงินทั้งหมด
    } else {
        account0.transfer(reward / 2);  // เสมอ แบ่งเงินกัน
        account1.transfer(reward / 2);
    }

    // รีเซ็ตค่า เพื่อให้เริ่มเกมใหม่ได้
    numPlayer = 0;
    reward = 0;
    delete players;
}
ปัญหาคือ ถ้าผู้เล่นเลือกตัวเลือกไม่ครบ หรือเกมไม่จบ เงินอาจติดอยู่ใน Contract
หลังจากเกมจบ ต้องคืนเงินให้ผู้ชนะ หรือแบ่งให้ทั้งสองคนถ้าเสมอ รีเซ็ตค่าเพื่อให้สามารถเริ่มเกมใหม่ได้

อธิบายโค้ดส่วนที่ทำการซ่อน choice และ commit
mapping(address => bytes32) public commitments;

function commitChoice(bytes32 commitment) public {
    require(numPlayer == 2, "Game is not full");
    require(commitments[msg.sender] == bytes32(0), "Already committed");

    commitments[msg.sender] = commitment;  // บันทึกค่า Hash ของ Choice + Random Number
}
ปัญหาของโค้ดนี้เลยคือ ผู้เล่นที่สองสามารถดูตัวเลือกของผู้เล่นแรกก่อนเลือกของตัวเอง (Front-running Attack)ผู้เล่นต้องส่ง ค่า Hash (bytes32) ของ Choice + Random Number แทนการส่งตัวเลือกตรงๆเก็บค่า Hash ไว้ก่อน แล้วให้ผู้เล่นเปิดเผยค่า (Reveal) ภายหลัง


อธิบายโค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที
mapping(address => uint) public lastActivity;

function withdrawIfTimeout(uint timeoutPeriod) public {
    require(numPlayer == 1, "Game already started");
    require(block.timestamp - lastActivity[players[0]] >= timeoutPeriod, "Not timed out yet");

    payable(players[0]).transfer(reward);  // คืนเงินให้ผู้เล่นที่รอนานเกินไป
    numPlayer = 0;
    reward = 0;
    delete players;
}
ถ้ามีผู้เล่นเข้ามาแค่ 1 คน แล้วไม่มีผู้เล่นที่สอง เงินจะติดอยู่ใน Contract ตั้งเวลา Timeout ถ้าผู้เล่นคนที่สองไม่มาอนุญาตให้ผู้เล่นที่เข้ามาก่อน ถอนเงินคืน ได้

อธิบายโค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ 
function revealChoice(uint choice, uint randomValue) public {
    require(numPlayer == 2, "Game is not full");
    require(commitments[msg.sender] != bytes32(0), "No commitment found");

    bytes32 expectedHash = keccak256(abi.encodePacked(choice, randomValue));
    require(commitments[msg.sender] == expectedHash, "Invalid reveal");

    player_choice[msg.sender] = choice;

    if (player_choice[players[0]] != 0 && player_choice[players[1]] != 0) {
        _checkWinnerAndPay();
    }
}
ผู้เล่นอาจเปลี่ยนตัวเลือกหลังจาก Commit เพื่อโกง ตรวจสอบว่า Hash ของ Choice + Random Number ที่เปิดเผย ตรงกับ Commit เดิมถ้าผู้เล่นทั้งสองเปิดเผยค่า → คำนวณผู้ชนะ
