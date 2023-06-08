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
        uint256 timestampOpen;

        int8 betDirection;
        bool isResolved;

        uint80 roundIdClose;
        int256 priceClose;
        int256 timestampClose;
    }

    struct UserBets {
        uint[] unresolvedIndexes;
        BetsDetails[] betsDetails;
    }

    mapping(address => UserBets) userBets;
    mapping(address => uint) numUserBets;
    uint totalNumPlacedBets = 0;
    uint latestTimestamp;
    uint80 latestRoundId;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Network: Mumbai Testnet
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Network: Mumbai Testnet
     * Aggregator: ETH/USD
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Network: Polygon Mainnet
     * Aggregator: ETH/USD
     * Address: 0xF9680D99D6C9589e2a93a78A04A279e509205945
     */

    constructor()  {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    /**
     * Events of the contract
     */
    event BetPlaced(address indexed _from, uint256 _betValue, int8 _betDirection);
    event BetChecked(address indexed _to);
    event BetResult(address indexed _to, int8 _betWonTieLost);

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

    function getUserNumBets() public view returns (uint) {
        require(numUserBets[msg.sender]>0, "No bets placed!");
        return numUserBets[msg.sender];
    }

    function getUserUnresolvedNum() public view returns (uint) {
        require(userBets[msg.sender].unresolvedIndexes.length>0, "No bets awaiting resolve!");
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
        require(balanceOf(msg.sender) >= _betValue, "Not enough XAM to place a bet.");
        require(_betDirection >= -1 && _betDirection <= 1, "Incorrect bet direction, must be: -1 for short, 0 or 1 for long.");

        burn(_betValue);

        (uint80 entryRoundID, int entryPrice, uint entryTimeStamp) = getLatestPrice(); // check current block ID from chainlink and price roundID, price, timeStamp

        uint80 _roundIdClose = entryRoundID + 1; // Time after which it is possible to determine bet
        uint _getUserNumBets = getUserNumBets();

        BetsDetails memory newBet = BetsDetails({
                    roundIdOpen: entryRoundID,
                    priceOpen: entryPrice,
                    timestampOpen: entryTimeStamp,
                    betDirection: _betDirection,
                    isResolved: false,
                    roundIdClose: _roundIdClose,
                    priceClose: 0,
                    timestampClose: 0
                });

        // store entry data in userBets struct
        userBets[msg.sender].betsDetails.push(newBet);
        userBets[msg.sender].unresolvedIndexes.push(_getUserNumBets);

        // Increase total number of bets
        totalNumPlacedBets++;
        numUserBets[msg.sender]++;

        // event bet placed
        emit BetPlaced(msg.sender, _betValue, _betDirection);
        return true;
    }

    function checkBlockTiming() private {
        // Function overrides global variables determining latest round ID and timestamp
        // require(block.timestamp - lastRun > 5 minutes, "Need to wait 5min");
        (latestRoundId, , latestTimestamp) = getLatestPrice();
    }

    // function removeFirstIndex(uint256 _index) external {
    //     require(array.length > _index, "Out of bounds");
    //     // move all elements to the left, starting from the `index + 1`
    //     for (uint256 i = _index; i < _index.length - 1; i++) {
    //         array[i] = array[i+1];
    //     }
    //     array.pop(); // delete the last item
    // }

    function getUnresolvedBet() private view returns (BetsDetails memory) {
        // Function returns the first struct containing unresolved bets
        require(getUserUnresolvedNum()>0, "No bets awaiting resolve!");
        uint unresolvedIndex = userBets[msg.sender].unresolvedIndexes[0];
        return userBets[msg.sender].betsDetails[unresolvedIndex];
    }

    function checkWinningCondition(int256 _entryPrice, int256 _closePrice) private returns (bool success) {
        emit BetResult();
        return true;
    }

    /**
     * 
     */
    function checkBet() public returns (bool success) {
        // final price check
        require(getUserUnresolvedNum()>0, "No unresolved bets!");
        checkBlockTiming();
        BetsDetails memory selectedBet = getUnresolvedBet();
        require(selectedBet.isResolved == false, "Critical error! Bet already resolved");
        require(latestTimestamp > (selectedBet.timestampOpen+60) && latestRoundId > selectedBet.roundIdClose, "Try to check bet again later");
        (int histPrice, uint histTimestamp) = getHistoricalPrice(selectedBet.roundIdClose);
        
        // + check current block timestamp and round id
        // + get data by using unresolvedBets arr - first record
        // + check if timestamp and round id is higher than those from bet
        // + if yes, check by getHistoricalPrice
        // execute checkWinningCondition
        // pop from unresolvedBets arr first record
        // set isResolved, timestampClose and price close
        emit BetChecked();
        return true;
    }

    /**
     * 
     */
    // function checkAllBets() public returns (bool success) {
    //     require(msg.sender == owner, "Not a contract owner"); // Ensure that function is called by the owner

    // }
    


}