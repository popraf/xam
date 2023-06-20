// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract Xam {
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
        name = "XAM";
        symbol = "XAM";
        decimals = 18;
        totalSupply = 1000000000000000000000; //1000 Ether in Wei according to decimals (1e18), Ether=Wei*decimals
        totalWon = 0;
        owner = msg.sender;

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier burnMintModifier(uint _value) {
        require(_value > 0, "Amount must be greater than zero");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event BuyTokens(address _buyer, uint256 _amountOfMATIC, uint256 _amountOfTokens);

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough tokens");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Will cause a certain `_value` of coins minted to `_to` address.
     * The minting uses address
     * @param _to The address that will receive the coin.
     * @param _value The amount of coin they will receive.
     */
    function mint(address _to, uint _value) burnMintModifier(_value) internal returns (bool success) {
        balances[_to] += _value;
        totalSupply += _value;

        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**
     * @notice Will cause a certain `_value` of coins burned, and deducted from total supply.
     * @param _value The amount of coin to be burned.
     */
    function burn(uint256 _value) burnMintModifier(_value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough tokens in balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Not enough MATIC on account balance or MATIC not sent.");

        uint256 amountToBuy = msg.value * tokensPerMatic;

        // Mint tokens
        (bool minted) = mint(msg.sender, amountToBuy);
        require(minted, "Failed to mint tokens to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        return amountToBuy;
    }

    function setTokensPerMatic(uint8 _tokensPerMatic) public {
        require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner
        require(_tokensPerMatic > 0, "Value must be higher than 0!");
        require(_tokensPerMatic < tokensPerMatic, "Value must be smaller than it is now.");
        tokensPerMatic = _tokensPerMatic;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "No MATIC present in Vendor");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }
}
