// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./Main.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract XamMechanics is Xam {
    Xam xam;
    AggregatorV3Interface internal priceFeed;

    struct BetsDetails {
        uint betValue;

        uint80 roundIdOpen;
        int256 priceOpen;
        uint256 timestampOpen;

        int8 betDirection;
        bool isResolved;

        uint80 roundIdClose;
        int256 priceClose;
        uint256 timestampClose;
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
    event BetChecked(address indexed _from);
    event BetResult(address indexed _from, int8 _betWonTieLost);

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
        return numUserBets[msg.sender];
    }

    function getUserUnresolvedNum(address _from) public view returns (uint) {
        require(userBets[_from].unresolvedIndexes.length>0, "No bets awaiting resolve!");
        return userBets[_from].unresolvedIndexes.length;
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
                    betValue: _betValue,
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

    function removeFirstUnresolvedIndex(address _from) private {
        require(getUserUnresolvedNum(_from) > 0, "Out of bounds");
        
        if (getUserUnresolvedNum(_from) == 1) {
            userBets[_from].unresolvedIndexes.pop();
        } else {
            for(uint i = 0; i < getUserUnresolvedNum(_from)-1; i++) {
                userBets[_from].unresolvedIndexes[i] = userBets[_from].unresolvedIndexes[i+1];
            }
            userBets[_from].unresolvedIndexes.pop();
        }
    }

    function getUnresolvedBet(address _from) private view returns (BetsDetails storage) {
        // Function returns the first struct containing unresolved bets
        require(getUserUnresolvedNum(_from)>0, "No bets awaiting resolve!");
        uint unresolvedIndex = userBets[_from].unresolvedIndexes[0];
        return userBets[_from].betsDetails[unresolvedIndex];
    }

    function checkWinningCondition(address _to, uint _betValue, int256 _entryPrice, int256 _closePrice, int8 _betDirection) private returns (bool success) {
        int8 betWonTieLost = 0;

        if (_betDirection == 1) {
            // Long
            if (_closePrice <= _entryPrice) {
                // Lost bet
                // Value is already burned
                betWonTieLost = -1;
            } else {
                // Won bet
                // Mint tokens
                betWonTieLost = 1;
                mint(_to, (_betValue*2)); // TODO: 1.8 + round
            }

        } else if (_betDirection == -1) {
            // Short
            if (_closePrice >= _entryPrice) {
                // Lost bet
                // Value is already burned
                betWonTieLost = -1;
            } else {
                // Won bet
                // Mint tokens
                betWonTieLost = 1;
                mint(_to, (_betValue*2)); // TODO: 1.8 + round
            }

        } else {
            // Stays the same
            if (_closePrice == _entryPrice) {
                // Won bet
                // Mint tokens
                betWonTieLost = 1;
                mint(_to, (_betValue*2)); // TODO: 1.8 + round
            } else {
                // Lost bet
                betWonTieLost = -1;
            }
        }

        emit BetResult(_to, betWonTieLost);
        return true;
    }

    /**
     * 
     */
    function checkBet(address _from) public returns (bool success) {
        // final price check
        require(getUserUnresolvedNum(_from)>0, "No unresolved bets!");
        checkBlockTiming();
        BetsDetails storage selectedBet = getUnresolvedBet(_from);
        require(selectedBet.isResolved == false, "Critical error! Bet already resolved");
        require(latestTimestamp > (selectedBet.timestampOpen+60) && latestRoundId > selectedBet.roundIdClose, "Try to check bet again later");

        (int histPrice, /* uint histTimestamp */) = getHistoricalPrice(selectedBet.roundIdClose);
        
        checkWinningCondition(_from, selectedBet.betValue, selectedBet.priceOpen, histPrice, selectedBet.betDirection); // Check bet
        removeFirstUnresolvedIndex(_from); // Remove checked index from array containing items to be checked

        // Override existing data in struct
        selectedBet.isResolved = true;
        selectedBet.timestampClose = latestTimestamp;
        selectedBet.priceClose = histPrice;
        
        emit BetChecked(_from);
        return true;
    }

}