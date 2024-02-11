// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RPS is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        bytes32 hashedChoice;
        address addr;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numInput = 0;
    uint public numReveal = 0;

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 3;
        numPlayer++;
    }

    function input(uint hashedAnswer , uint idx) public  {
        require(numPlayer == 2);
        require(numInput < 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2);
        player[idx].hashedChoice = hashedAnswer;
        commit(hashedAnswer);
    }

    function revealRequest(bytes32 salt, uint choice , uint idx) public {
      require(numInput == 2);
      require(choice == 0 || choice == 1 || choice == 2);
      require(msg.sender == player[idx].addr);
      reveal(player[idx].hashedChoice);
      revealAnswer(choice , salt);
      player[idx].choice = choice;
      numReveal++;
      if (numReveal == 2) {
          _checkWinnerAndPay();
      }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 3 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 3 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
