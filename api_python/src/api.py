import json
from decouple import config
from web3 import Web3
from web3.gas_strategies.rpc import rpc_gas_price_strategy

# Replace the RPC endpoint with the appropriate one for the Polygon network you want to connect to
# w3 = Web3(Web3.HTTPProvider('https://rpc-mainnet.maticvigil.com'))
w3 = Web3(Web3.HTTPProvider('https://polygon-mumbai-bor.publicnode.com'))

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

def getBalance(_address):
    return contract.functions.balanceOf(_address).call()

def getTotalSupply():
    return contract.functions.totalSupply().call()

# def setSenderGas(_address, _gas):
#     return {
#         'from': _address,
#         'gas': _gas,
#         'gasPrice': w3.to_wei('10', 'gwei'),
#         'nonce': w3.eth.get_transaction_count(_address),
#         }

# def transferTokens(_recipient, _amount, _sender, _gas=1000000):
#     return contract.functions.transfer(_recipient, _amount).build_transaction(setSenderGas(_sender, _gas))

# def sendTransaction(_transaction, _private_key):
#     # Sign the transaction
#     signed_txn = w3.eth.account.sign_transaction(_transaction, _private_key)

#     # Send the transaction
#     tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)

#     receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
#     print(receipt)

print('balance owner: ', getBalance(owner_address))

w3.eth.set_gas_price_strategy(rpc_gas_price_strategy)
chain_id = w3.eth.chain_id
estimate = w3.eth.estimate_gas({'to': second_address, 'from': owner_address, 'value': 100})

transaction = contract.functions.transfer(second_address, 100)
unsigned_txn = transaction.build_transaction({ 'gas' : estimate, 'nonce' : w3.eth.get_transaction_count(owner_address) })
signed_tx = w3.eth.account.sign_transaction(unsigned_txn, owner_pvkey)
txn_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
# print(f'Transaction successful with hash: { txn_hash.transactionHash.hex() }')

getBalance(second_address)
