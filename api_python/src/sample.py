from api import balanceOf, placeBet, checkBetPublic, getUserNumBets, getUserUnresolvedNum

import json
from decouple import config
from web3 import Web3
from web3.gas_strategies.rpc import rpc_gas_price_strategy
import time

# Replace the RPC endpoint with the appropriate one for the Polygon network you want to connect to
# w3 = Web3(Web3.HTTPProvider('https://rpc-mumbai.maticvigil.com/'))
w3 = Web3(Web3.HTTPProvider((config('RPC'))))

# Check connection status
print(w3.net.version)

# Read smart contract address from config file .env
CONTRACT_ADDRESS = config('CONTRACT_ADDRESS')
print('CONTRACT ADDRESS: ',CONTRACT_ADDRESS)

# Read compiled smart contract ABI to interact with
with open('../../backend/artifacts/contracts/Mechanics.sol/XamMechanics.json') as compiled_contract_file:
    compiled_contract = json.load(compiled_contract_file)
    contract_abi = compiled_contract['abi']

contract = w3.eth.contract(address = CONTRACT_ADDRESS, abi = contract_abi)

owner_address = Web3.to_checksum_address(config('OWNER_ADDR'))
second_address = Web3.to_checksum_address(config('SEC_ADDR'))
third_address = Web3.to_checksum_address(config('THIRD_ADDR'))
owner_pvkey = (config('OWNER_PRIVATE_KEY'))
second_pvkey = (config('SEC_PRIVATE_KEY'))
third_pvkey = (config('THIRD_PRIVATE_KEY'))

init_balance = balanceOf(owner_address)
init_no_bets = getUserNumBets(owner_address)
print('init balanceOf(owner_address): ',init_balance)
print('--init getUserNumBets(owner_pvkey): ', init_no_bets)

# Place bets from owner address
placeBet(10000000, 1, owner_pvkey)
print('1 getUserUnresolvedNum(owner_address)', getUserUnresolvedNum(owner_address))
print('1 Sleep start')
time.sleep(11)
print('1 Sleep end')
checkBetPublic(owner_address, owner_pvkey)
print('2 Sleep start')
time.sleep(11)
print('2Sleep end')
print('Checking bet')
checkBetPublic(owner_address, owner_pvkey)
print('finished.')
print('--final getUserNumBets(owner_pvkey): ', getUserNumBets(owner_address))
print('--final getUserUnresolvedNum(owner_address)', getUserUnresolvedNum(owner_address))
print('final balanceOf(owner_address): ',balanceOf(owner_address))
print('init  balanceOf(owner_address): ',init_balance)
