// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract Xam {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalWon;
    // uint256 public priceThreshold = 1000000;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint8 public tokensPerMatic = 100;

    constructor() {
        name = "XAM2";
        symbol = "XAM2";
        decimals = 18;
        totalSupply = 1000000000000000000000; //1000 Ether in Wei
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
        require(balances[msg.sender] >= _value);

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
    function mint(address _to, uint _value) burnMintModifier(_value) private returns (bool success) {
        // require(msg.sender == owner); // TODO: ?

        balances[_to] += _value;
        totalSupply += _value;

        emit Transfer(address(0), _to, _value);
        return true;    
    }

    /**
     * @notice Will cause a certain `_value` of coins burned, and deducted from total supply.
     * @param _value The amount of coin to be burned.
     */
    function burn(uint256 _value) burnMintModifier(_value) private {
        require(_value <= balances[msg.sender], "Not enough tokens in balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);
    }

    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Not enough MATIC on account balance");
        require(tokenAmount > 0, "Token amount to buy must be higher.");

        uint256 amountToBuy = msg.value * tokensPerMatic;

        // Mint tokens
        (bool minted) = mint(msg.sender, amountToBuy);
        require(minted, "Failed to mint tokens to user");

        // // Commented out below - instead minting is used
        // // // Check if the Vendor Contract has enough amount of tokens for the transaction
        // uint256 vendorBalance = xam.balanceOf(address(this));
        // require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

        // // // Transfer token to the msg.sender
        // (bool sent) = xam.transfer(msg.sender, amountToBuy);
        // require(sent, "Failed to transfer token to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        return amountToBuy;
    }

    function setTokensPerMatic(uint8 _tokensPerMatic) public {
        require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner
        require(_tokensPerMatic > 0, "Value must be higher than 0!");
        tokensPerMatic = _tokensPerMatic;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner
        
        uint256 ownerBalance = balanceOf(msg.sender);
        require(ownerBalance > 0, "No MATIC present on contract");
        (bool sent, ) = msg.sender.call{value: balanceOf(msg.sender)}("");
        require(sent, "Failed to withdraw");
    }

}
