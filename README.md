# xam

### About
This is just a gambling coin.

### How does it work
1 XAM equals 1 MATIC * tokensPerMatic var (default tokensPerMatic = 100).
Using XAM bet against price of ETH in next (at least) 5 seconds - short, long, no change.
If predicted correctly, you receive doubled bet price, otherwise bet is lost. 
The lost bet means that the token is burned.

### Token economy
Each transfer to another wallet costs 10% of sent amount, except for staking addresses.
The price of XAM for each MATIC might be changed in future.

===

### Technical Stuff
#### ETH Price checking
The price is checked directly in the smart contract by requesting the Chainlink node network.

#### ETC
Deployment: npx hardhat run --network mumbai scripts/deployMumbai.js, before deployment set privateKey and polygonMumbaiRPC (used `https://polygon-mumbai-bor.publicnode.com`)
Tests: 1. npx node run, 2. npx hardhat test
Interaction with contract: use python api, remember to define keys in .env
