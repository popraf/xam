import json
from decouple import config
from web3 import Web3
from web3.gas_strategies.rpc import rpc_gas_price_strategy
from web3.middleware import geth_poa_middleware

# Replace the RPC endpoint with the appropriate one for the Polygon network you want to connect to
# w3 = Web3(Web3.HTTPProvider('https://rpc-mumbai.maticvigil.com/'))
w3 = Web3(Web3.HTTPProvider((config('RPC'))))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

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

def balanceOf(_address):
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

def transferTokens(_recipient, _amount, _sender, _gas=1000000):
    return contract.functions.transfer(_recipient, _amount).build_transaction(setSenderGas(_sender, _gas))

def allowance(_owner, _spender):
    return contract.functions.allowance(_owner, _spender).call()

def approve(_spender, _value, _private_key):
    """
    Approve a spender to transfer tokens on behalf of the caller.
    Requires the private key of the caller to sign the transaction.
    """
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address
        
    # Build the transaction
    tx_data = contract.functions.approve(_spender, _value).build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })
    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(receipt)
    # return tx_hash.hex()
    return True, receipt

def transferFrom(_from, _to, _value, _private_key):
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.transferFrom(_from, _to, _value).build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })
    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(receipt)
    # return tx_hash.hex()
    return True, receipt

def burn(_value, _private_key):
    """
    Burn tokens by calling the `burn` function of the ERC-20 contract.
    Requires the private key of the caller to sign the transaction.
    """
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.burn(_value).build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt

def buyTokens(_value, _private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.buyTokens().build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'value': _value,  # Value to send with the transaction (in wei)
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt

def setTokensPerMatic(_tokensPerMatic, _private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.setTokensPerMatic(_tokensPerMatic).build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt

def withdraw(_private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.withdraw().build_transaction({
        'from': caller_address,
        'gas': 200000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt


# #######################
# #### XAM MECHANICS ####
# #######################

def getLatestPrice():
    """
    Get the latest price from Chainlink's getLatestPrice function.
    """
    # Call the getLatestPrice function
    latest_price = contract.functions.getLatestPrice().call()
    return latest_price

def getHistoricalPrice(_roundId):
    historical_price = contract.functions.getHistoricalPrice(_roundId).call()
    return historical_price

def getUserNumBets(_address):
    # Get the caller's account address from the private key
    # caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.getUserNumBets().call({
        'from': _address,
        # 'gas': 200000,  # Adjust the gas limit as needed
        # 'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # # Sign the transaction
    # signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # # Send the signed transaction
    # tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    # receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_data

def getUserUnresolvedNum(_address):
    address_bets = contract.functions.getUserUnresolvedNum(_address).call()
    return address_bets

def placeBet(_betValue, _betDirection, _private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.placeBet(_betValue, _betDirection).build_transaction({
        'from': caller_address,
        'gas': 350000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    contract.functions.handle_offchain_lookup(tx_data).call(ccip_read_enabled=False)

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt

def checkBetPublic(_address, _private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.checkBetPublic(_address).build_transaction({
        'from': caller_address,
        'gas': 350000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt

def checkAllBets(_private_key):
    # Get the caller's account address from the private key
    caller_address = w3.eth.account.from_key(_private_key).address

    # Build the transaction
    tx_data = contract.functions.checkAllBets().build_transaction({
        'from': caller_address,
        'gas': 450000,  # Adjust the gas limit as needed
        'nonce': w3.eth.get_transaction_count(caller_address),
    })

    # Sign the transaction
    signed_tx = w3.eth.account.sign_transaction(tx_data, _private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return True, receipt



# ##################
# #### EXAMPLES ####
# ##################
# # Transfer
# print('balance owner: ', getBalance(owner_address))
# unsigned_txn = transferTokens(second_address, 10000, owner_address, 1000000)
# sendTransaction(unsigned_txn, owner_pvkey)
# print('balane second_address: ', getBalance(second_address))
