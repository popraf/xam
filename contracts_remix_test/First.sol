// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract First {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalWon;

    uint8 public tokensPerMatic = 100;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        name = "XAM2";
        symbol = "XAM2";
        decimals = 18;
        totalSupply = 1000000000000000000000; //1000 Ether in Wei according to decimals (1e18), Ether=Wei*decimals
        totalWon = 0;
        owner = msg.sender;

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
