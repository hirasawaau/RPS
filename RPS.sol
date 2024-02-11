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
    mapping (uint => bytes32) public choices;
    uint public numInput = 0;
    uint public numReveal = 0;

    constructor() {
        choices[0] = "Rock"; 
        choices[1] = "Paper"; 
        choices[2] = "Scissors"; 
    }
    

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 3;
        numPlayer++;
    }

    function input(bytes32 hashedAnswer , uint idx) public  {
        require(numPlayer == 2);
        require(numInput < 2);
        require(msg.sender == player[idx].addr);
        commit(hashedAnswer);
        player[idx].hashedChoice = hashedAnswer;
        numInput++;
    }

    function revealRequest(bytes32 salt, uint choice , uint idx) public {
      require(numInput == 2);
      require(choice == 0 || choice == 1 || choice == 2);
      require(msg.sender == player[idx].addr);
      reveal(player[idx].hashedChoice);
      revealAnswer(choices[choice] , salt);
      player[idx].choice = choice;
      numReveal++;
      if (numReveal == 2) {
          _checkWinnerAndPay();
      }
    }

    function _getChoiceBase(uint32 choice) private pure returns(bytes32) {
        if(choice == 0) {
            return "R";
        } else if (choice == 1) {
            return "P";
        } else {
            return "S";
        }
    }

    function getChoiceHash(uint32 choice, bytes32 salt) public view returns(bytes32) {
        require(choice == 0 || choice == 1 || choice == 2);
        return getSaltedHash(_getChoiceBase(choice), salt);
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
