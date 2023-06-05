// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./Main.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract XamMechanics is Xam {
    Xam xam;
    AggregatorV3Interface internal priceFeed;

    struct BetsDetails {
        uint80 roundIdOpen;
        int256 priceOpen;

        int8 betDirection;
        bool isResolved;

        uint80 roundIdClose;
        int256 priceClose;
    }

    struct UserBets {
        uint[] unresolvedIndexes;
        mapping(uint => BetsDetails[]) betsDetails;
    }

    mapping(address => UserBets) userBets;
    mapping(address => uint) numUserBets;
    uint256 totalNumPlacedBets = 0;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * Events of the contract
     */
    event BetPlaced(address indexed _from, uint256 _betValue, int8 _betDirection);

    /**
     * Returns the latest price based on Chainlink nodes network
     */
    function getLatestPrice() public view returns (uint80, int, uint) {
        (
            uint80 roundID,
            int price,
            /* uint startedAt */,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return (roundID, price, timeStamp);
    }

    function getHistoricalPrice(uint80 _roundId) public view returns (int, uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.getRoundData(_roundId);
        require(timeStamp > 0, "Round not complete");
        return (price, timeStamp);
    }

    /**
     * @notice Will cause a certain `_value` of coins minted to `_to` address.
     * The minting uses address
     * @param _to The address that will receive the coin.
     * @param _value The amount of coin they will receive.
     */
    function betMint(address _to, uint _value) burnMintModifier(_value) private returns (bool success) {
        // require(_value >= 0); // uint handles this req

        balances[_to] += _value;
        totalSupply += _value;

        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**
     * @notice Will cause a certain `_value` of coins burned, and deducted from total supply.
     * @param _value The amount of coin to be burned.
     */
    function betBurn(uint _value) burnMintModifier(_value) private returns (bool success) {
        // require(_value >= 0); // uint handles this req
        require(xam.balanceOf(msg.sender) >= _value, "Not enough tokens in balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function getUserNumBets() public view returns (uint) {
        return numUserBets[msg.sender];
    }

    function getUserUnresolvedNum() public view returns (uint) {
        return userBets[msg.sender].unresolvedIndexes.length;
    }

    /**
     * @notice Will cause a certain amount `_betValue` of coins bet.
     * @param _betValue The bet value in XAM tokens.
     * @param _betDirection The prediction of price: -1 short (decrease); 0 stays the same; 1 long (increase).
     * Checking if the user won is being perfermed in checkBet function - by doing so, there's no need to
     * introduce upkeep.
     */
    function placeBet(uint _betValue, int8 _betDirection) public returns (bool success) {
        require(xam.balanceOf(msg.sender) >= _betValue, "Not enough XAM to place a bet.");
        require(_betDirection >= -1 && _betDirection <= 1, "Incorrect bet direction, must be: -1 for short, 0 or 1 for long.");

        betBurn(_betValue);

        uint80 entryRoundID;
        int entryPrice;
        uint entryTimeStamp;
        (entryRoundID, entryPrice, entryTimeStamp) = getLatestPrice(); // check current block ID from chainlink and price roundID, price, timeStamp

        uint80 _roundIdClose = entryRoundID + 1; // Time after which it is possible to determine bet

        // store entry data in userBets struct
        userBets[msg.sender].betsDetails[getUserNumBets()+1].push(BetsDetails(
            {
                roundIdOpen: entryRoundID,
                priceOpen: entryPrice,
                betDirection: _betDirection,
                isResolved: false,
                roundIdClose: _roundIdClose,
                priceClose: 0 // !! To be checked in further steps !!
            }
        ));
        userBets[msg.sender].unresolvedIndexes[getUserUnresolvedNum()+1] = getUserNumBets()+1;

        // Increase total number of bets
        totalNumPlacedBets++;
        numUserBets[msg.sender]++;

        // event bet placed
        emit BetPlaced(msg.sender, _betValue, _betDirection);
        return true;
    }

    /**
     * 
     */
    // function checkBet() public returns (bool success) {
    //     // final price check
    // }

    /**
     * 
     */
    // function checkAllBets() public returns (bool success) {
    //     require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner

    // }

    // function getBlockNumber() private returns (uint256) {
    //     return block.number;
    // }

    // uint256 lastRun;
    // function sleep() private {
    //     require(block.timestamp - lastRun > 5 minutes, "Need to wait 5min");

    //     // TODO Perform the action
    //     lastRun = block.timestamp;
    // }

}
