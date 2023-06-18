// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./Main.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Automation:
// LINK on polygon testnet contract address: https://docs.chain.link/resources/link-token-contracts
// Get test LINK: https://faucets.chain.link/mumbai
// Best practices: https://docs.chain.link/chainlink-automation/compatible-contract-best-practice
// Managing upkeep: https://docs.chain.link/chainlink-automation/manage-upkeeps

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
    mapping(address => bool) isAddrBeingChecked;
    address[] addrToCheck;
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
    event BetResult(address indexed _from, int8 _betWonTieLost, int8 _betDirection);

    /**
     * @notice Chainlink's interface: Returns the latest price based on Chainlink nodes network
     * @return roundID The round ID, refers to the unique identifier assigned to a specific price update or round in an oracle network.
     * @return price The price.
     * @return timeStamp Unix timestamp associated with a specific historical price data point retrieved from the oracle.
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

    /**
     * @notice Chainlink's interface: Returns the price at certain `_roundId` based on Chainlink nodes network
     * @param _roundId The round ID, refers to the unique identifier assigned to a specific price update or round in an oracle network.
     * @return price The price at certain `_roundId` retrieved from the oracle.
     * @return timeStamp Unix timestamp associated with a specific historical price data point retrieved from the oracle.
     */
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
     * @notice Function returns total number of user bets ever placed. 
     * Works only for `msg.sender`.
     * @return `numUserBets[msg.sender]` Returns total number of user bets.
     */
    function getUserNumBets() public view returns (uint) {
        return numUserBets[msg.sender];
    }

    /**
     * @notice Function returns number of user bets, which can be checked (resolved).
     * @param _from Address to lookup for unresolved bets.
     * @return `numUserBets[msg.sender]` Returns number of unresolved bets.
     */
    function getUserUnresolvedNum(address _from) public view returns (uint) {
        require(userBets[_from].unresolvedIndexes.length>0, "No bets awaiting resolve!");
        return userBets[_from].unresolvedIndexes.length;
    }

    /**
     * @notice Main betting function to place bet. Causes a certain amount `_betValue` to be burned along with storing bet data in struct.
     * Bet must be checked (resolved) afterwards in order to determine if user won.
     * @param _betValue The bet value in XAM tokens.
     * @param _betDirection The prediction of price: -1 short (decrease); 0 stays the same; 1 long (increase).
     * Checking if the user won is being perfermed in checkBet function.
     * @return success Returns true at the end of the function runtime.
     */
    function placeBet(uint _betValue, int8 _betDirection) public returns (bool success) {
        require(balanceOf(msg.sender) >= _betValue, "Not enough XAM to place a bet.");
        require(_betDirection >= -1 && _betDirection <= 1, "Incorrect bet direction, must be: -1 for short, 0 for no change, 1 for long.");

        burn(_betValue);

        (uint80 entryRoundID, int entryPrice, uint entryTimeStamp) = getLatestPrice(); // check current block ID from chainlink and price roundID, price, timeStamp

        uint80 _roundIdClose = entryRoundID + 1; // Time after which it is possible to determine bet - next round
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

        // Increase total number of bets, set flag isAddrBeingChecked, push to addrToCheck arr in order to automate checking
        totalNumPlacedBets++;
        numUserBets[msg.sender]++;
        isAddrBeingChecked[msg.sender] = false;
        addrToCheck.push(msg.sender);

        // event bet placed
        emit BetPlaced(msg.sender, _betValue, _betDirection);
        return true;
    }

    /**
     * @notice Function overrides global variables determining latest round ID and timestamp by calling getLatestPrice.
     */
    function checkBlockTiming() private {
        (latestRoundId, , latestTimestamp) = getLatestPrice();
    }

    /**
     * @notice Function removes first entry (0 index) of unresolvedIndexes array for certain address. 
     * @param _from Address to remove first entry of unresolvedIndexes.
     * @dev Must be called after checking (resolving) a first bet from this array.
     */
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

    /**
     * @notice Function returns the first struct containing unchecked bets for a certain address.
     * @param _from Address to lookup.
     * @return Returns storage struct `BetsDetails`.
     * @dev Any changes to this function returns are permanently stored as function returns `storage` data.
     */
    function getUnresolvedBet(address _from) private view returns (BetsDetails storage) {
        require(getUserUnresolvedNum(_from)>0, "No bets awaiting resolve!");
        uint unresolvedIndex = userBets[_from].unresolvedIndexes[0];
        return userBets[_from].betsDetails[unresolvedIndex];
    }

    /**
     * @notice Function checks if the bet is a winning or loosing one.
     * Rewards for winning are granted in this function by token minting.
     * @param _to Address placing bet.
     * @param _betValue Bet value.
     * @param _entryPrice ETH (or other token, specified in `priceFeed`) price at bet placing.
     * @param _closePrice ETH (or other token, specified in `priceFeed`) price at next round id.
     * @param _betDirection The prediction of price: -1 short (decrease); 0 stays the same; 1 long (increase). Must be -1 or 0 or 1.
     * @return success Returns true at the end of the function runtime.
     */
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

        emit BetResult(_to, betWonTieLost, _betDirection);
        return true;
    }

    /**
     * @notice Main function to check bet of specific address. Function checks a single bet every call.
     * @param _from Address to check (resolve) bet of.
     * @return success Returns true at the end of the function runtime.
     * @dev Important: `require(latestTimestamp > (selectedBet.timestampOpen+60))` makes sure to not check the prices
     * while the round is still ongoing. Depending on average block time, hardcoded value 60 can be changed and adjusted to needs.
     */
    function checkBet(address _from) public returns (bool success) {
        checkBlockTiming();

        require(isAddrBeingChecked[_from] == false, "Bet is being checked!");
        isAddrBeingChecked[_from] = true;
        
        require(getUserUnresolvedNum(_from)>0, "No unresolved bets!");
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

        isAddrBeingChecked[_from] = false;
        
        emit BetChecked(_from);
        return true;
    }

    /**
     * @notice Function removes checked address from addrToCheck array.
     * @param _index The index in array of the address to delete.
     * @return success Returns true at the end of the function runtime.
     */
    function addrChecked(uint _index) private returns (bool success) {
        require(_index < addrToCheck.length, "Index out of bounds");

        for (uint i = _index; i < addrToCheck.length-1; i++) {
            addrToCheck[i] = addrToCheck[i + 1];
        }

        addrToCheck.pop();
        return true;
    }

/**
 * @notice Function to automate bets checking. 
 * Loops through array of addresses with unresolved bets.
 * @return success Returns true at the end of the function runtime.
 */
    function checkAllBets() external returns (bool success) {
        require(addrToCheck.length>0,"No addresses pending check");

        for (uint i = 0; i < addrToCheck.length-1; i++) {
            checkBet(addrToCheck[i]);

            // Remove address from addrToCheck array if all user bets are checked
            if(getUserUnresolvedNum(addrToCheck[i]) == 0) {
                addrChecked(i);
                i--;
            }
        }

        return true;
    }
}