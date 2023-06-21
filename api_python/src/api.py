import json
from decouple import config
from web3 import Web3
from web3.gas_strategies.rpc import rpc_gas_price_strategy

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

def getBalance(_address):
    return contract.functions.balanceOf(_address).call()

def getTotalSupply():
    return contract.functions.totalSupply().call()

def setSenderGas(_address, _gas):
    return {
        'from': _address,
        'gas': _gas,
        'gasPrice': w3.to_wei('10', 'gwei'),
        'nonce': w3.eth.get_transaction_count(_address),
        }

def transferTokens(_recipient, _amount, _sender, _gas=1000000):
    return contract.functions.transfer(_recipient, _amount).build_transaction(setSenderGas(_sender, _gas))

def sendTransaction(_transaction, _private_key):
    # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(_transaction, _private_key)

    # Send the transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)

    # Wait for a transaction to be mined and obtain its receipt
    #   Note that wait_for_transaction_receipt is a blocking function, 
    #   meaning it will pause the execution of your code until the transaction is mined and the receipt is obtained.
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(receipt)
    return True, receipt





# ##################
# #### EXAMPLES ####
# ##################
# # Transfer
# print('balance owner: ', getBalance(owner_address))
# unsigned_txn = transferTokens(second_address, 10000, owner_address, 1000000)
# sendTransaction(unsigned_txn, owner_pvkey)
# print('balane second_address: ', getBalance(second_address))
