// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract Xam {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
