// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract RPSLS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper, 2 - Scissors, 3 - Lizard, 4 - Spock
    mapping(address => bool) public player_not_played;
    address[] public players;

    address[4] public allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyAllowedPlayers() {
        bool isAllowed = false;
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (msg.sender == allowedPlayers[i]) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed, "Player not authorized");
        _;
    }

    modifier gameNotFull() {
        require(numPlayer < 2, "Game is full");
        _;
    }

    modifier hasSentEther() {
        require(msg.value == 1 ether, "Player must send 1 ether to join");
        _;
    }

    function addPlayer() public payable onlyAllowedPlayers gameNotFull hasSentEther {
        players.push(msg.sender);
        player_not_played[msg.sender] = true;
        reward += msg.value;
        numPlayer++;
    }

    function input(uint choice) public {
        require(numPlayer == 2, "Game is not full");
        require(player_not_played[msg.sender], "Player has already chosen");
        require(choice >= 0 && choice <= 4, "Invalid choice");

        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;

        if (!player_not_played[players[0]] && !player_not_played[players[1]]) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        // กำหนดว่าใครชนะโดยดูจากกฎ RPSLS
        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
        } else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        // รีเซ็ตเกมเพื่อให้เล่นใหม่ได้
        numPlayer = 0;
        reward = 0;
        delete players;
    }

    function _isWinner(uint choice1, uint choice2) private pure returns (bool) {
        return (choice1 == 0 && (choice2 == 2 || choice2 == 3)) || // Rock crushes Scissors, Rock crushes Lizard
               (choice1 == 1 && (choice2 == 0 || choice2 == 4)) || // Paper covers Rock, Paper disproves Spock
               (choice1 == 2 && (choice2 == 1 || choice2 == 3)) || // Scissors cuts Paper, Scissors decapitates Lizard
               (choice1 == 3 && (choice2 == 1 || choice2 == 4)) || // Lizard eats Paper, Lizard poisons Spock
               (choice1 == 4 && (choice2 == 0 || choice2 == 2));   // Spock vaporizes Rock, Spock smashes Scissors
    }
}
