// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    uint256 public totalFunds;
    address public payee;
    bool public isReleased;

    constructor(address _payee) payable Ownable(msg.sender) {
        require(_payee != address(0), "Payee cannot be zero address");
        totalFunds = msg.value;
        // totalFunds = 25; // Replace with msg.value in real deployment
        payee = _payee;
        isReleased = false;
    }

    function releaseFunds() public onlyOwner {
        require(!isReleased, "Funds already released");
        isReleased = true;
        payable(payee).transfer(totalFunds);
    }
}
