import json
from web3 import Web3
from decouple import config
from api import XamApi

# Replace the RPC endpoint with the appropriate one for the Polygon network you want to connect to
RPC = config('RPC') # e.g. RPC = 'https://rpc-mumbai.maticvigil.com/'
CONTRACT_ADDRESS = config('CONTRACT_ADDRESS') # Read smart contract address from config file .env

owner_address = Web3.to_checksum_address(config('OWNER_ADDR'))
second_address = Web3.to_checksum_address(config('SEC_ADDR'))
third_address = Web3.to_checksum_address(config('THIRD_ADDR'))
owner_pvkey = (config('OWNER_PRIVATE_KEY'))
second_pvkey = (config('SEC_PRIVATE_KEY'))
third_pvkey = (config('THIRD_PRIVATE_KEY'))

with open('../../backend/artifacts/contracts/Mechanics.sol/XamMechanics.json') as compiled_contract_file:
    compiled_contract = json.load(compiled_contract_file)
    CONTRACT_ABI = compiled_contract['abi']

# Instantinate API object
api_instance = XamApi(RPC, CONTRACT_ADDRESS, CONTRACT_ABI)

# Check balance
print(api_instance.balanceOf(owner_address))

# Place bets from owner address
api_instance.placeBet(10000000, 1, owner_pvkey)

# Check user's # of bets
print("User's # of bets", api_instance.getUserNumBets(owner_address))

# User's # of unchecked bets
print("User's # of unchecked bets", api_instance.getUserUnresolvedNum(owner_address))

# Check user's bets
api_instance.checkBetPublic(owner_address, owner_pvkey)