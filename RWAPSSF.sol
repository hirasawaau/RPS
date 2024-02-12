// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RWAPSSF is CommitReveal {
    struct Player {
        uint8 choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        bytes32 hashedChoice;
        bool isCommited;
        bool isRevealed;
        address addr;
    }
    uint8 public numPlayer = 0;
    uint256 public reward = 0;
    mapping(uint8 => Player) public players;
    uint8 public numInput = 0;
    uint8 public numReveal = 0;
    uint256 public deadline = type(uint256).max;
    uint256 public constant DURATION = 5 minutes;
    uint256 public constant PRICE = 2 ether;

    function addPlayer() public payable {
        require(numPlayer < 2 , "Error(RWAPSSF::addPlayer): Full Player");
        require(msg.value == PRICE, "Error(RWAPSSF::addPlayer): Ether is not enough.");
        reward += msg.value;
        deadline = block.timestamp + DURATION;
        uint8 idx = numPlayer++;
        players[idx].addr = msg.sender;
        emit PlayerJoin(msg.sender, numPlayer++);
    }

    event PlayerJoin(address addr, uint256 idx);

    function input(bytes32 hashedAnswer, uint8 idx) public {
        require(
            players[idx].addr == msg.sender,
            "Error(RWAPSSF::input): You are not owner of this player"
        );
        require(
            !players[idx].isCommited,
            "Error(RWAPSSF::input): You are commited"
        );
        require(numPlayer == 2, "Error(RWAPSSF::input): Player not enough");
        require(
            numInput < 2,
            "Error(RWAPSSF::input): All player inputed, Please revealRequest"
        );
        commit(hashedAnswer);
        players[idx].hashedChoice = hashedAnswer;
        players[idx].isCommited = true;
        numInput++;
        deadline += 3 minutes;
        emit PlayerCommited(msg.sender);
    }

    event PlayerCommited(address player);

    // If player not answered for
    function requestRefund(uint8 idx) public {
        require(
            players[idx].addr == msg.sender,
            "Error(RWAPSSF::requestRefund): You are not owner of this player"
        );
        require(
            block.timestamp > deadline,
            "Error(RWAPSSF::requestRefund): Time not enough"
        );
        require(numPlayer > 0, "Error: No Player!!");
        address payable account = payable(msg.sender);
        // Case: Player waiting long time
        if (numPlayer == 1) {
            account.transfer(reward);
        } else {
            // Case: Player waiting commit long time
            if (numInput < 2) {
                require(
                    players[idx].isCommited,
                    "Error(RWAPSSF::requestRefund): You have not commited pls commit if not your money will return to another player."
                );
                account.transfer(reward);
                // Case: Player waiting reveal long time
            } else {
                require(
                    numReveal < 2,
                    "Error(RWAPSSF::requestRefund): All player revealed"
                );
                require(
                    players[idx].isRevealed,
                    "Error(RWAPSSF::requestRefund): You have not revealed pls reveal if not your money will return to another player."
                );
                account.transfer(reward);
            }
        }

        emit RefundCompleted(idx);
    }

    event RefundCompleted(uint8 idx);

    function revealRequest(
        string memory salt,
        uint8 choice,
        uint8 idx
    ) public {
        require(numInput == 2);
        require(choice >= 0 || choice < 7);
        require(msg.sender == players[idx].addr);
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));

        revealAnswer(bChoice, bSalt);
        players[idx].choice = choice;
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function getChoiceHash(uint8 choice, string memory salt)
        public
        view
        returns (bytes32)
    {
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));
        return getSaltedHash(bChoice, bSalt);
    }

    function _checkWinnerAndPay() private {
        uint256 p0Choice = players[0].choice;
        uint256 p1Choice = players[1].choice;
        address payable account0 = payable(players[0].addr);
        address payable account1 = payable(players[1].addr);

        if (p0Choice == p1Choice) {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        } else {
            for (uint8 i = 1; i <= 3; i++) {
                if ((p0Choice + i) % 7 == p1Choice) {
                    account0.transfer(reward);
                    break;
                } else if ((p1Choice + i) % 7 == p0Choice) {
                    account1.transfer(reward);
                    break;
                }
            }
        }
    }
}
