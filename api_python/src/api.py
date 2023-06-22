import json
from decouple import config
from web3 import Web3
from web3.middleware import geth_poa_middleware
# from web3.gas_strategies.rpc import rpc_gas_price_strategy


class XamApi:
    def __init__(self, _RPC, _CONTRACT_ADDRESS, _CONTRACT_ABI):
        self.w3 = Web3(Web3.HTTPProvider(_RPC))
        self.contract = self.w3.eth.contract(address = _CONTRACT_ADDRESS, abi = _CONTRACT_ABI)
        self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)

    def balanceOf(self,_address):
        return self.contract.functions.balanceOf(_address).call()

    def getTotalSupply(self):
        return self.contract.functions.totalSupply().call()

    def transferTokens(self, _recipient, _amount, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address
        tx_data = self.contract.functions.transfer(_recipient, _amount).build_transaction(
            {
            'from': caller_address,
            'gas': 100000,
            'gasPrice': self.w3.to_wei('10', 'gwei'),
            'nonce': self.w3.eth.get_transaction_count(caller_address),
            }
        )
        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        # Wait for a transaction to be mined and obtain its receipt
        #   Note that wait_for_transaction_receipt is a blocking function, 
        #   meaning it will pause the execution of your code until the transaction is mined and the receipt is obtained.
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        # print(receipt)
        # return tx_hash.hex()
        return True, receipt

    def allowance(self, _owner, _spender):
        return self.contract.functions.allowance(_owner, _spender).call()

    def approve(self, _spender, _value, _private_key):
        """
        Approve a spender to transfer tokens on behalf of the caller.
        Requires the private key of the caller to sign the transaction.
        """
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address
            
        # Build the transaction
        tx_data = self.contract.functions.approve(_spender, _value).build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })
        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        # print(receipt)
        # return tx_hash.hex()
        return True, receipt

    def transferFrom(self, _from, _to, _value, _private_key):
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.transferFrom(_from, _to, _value).build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })
        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        # print(receipt)
        # return tx_hash.hex()
        return True, receipt

    def burn(self, _value, _private_key):
        """
        Burn tokens by calling the `burn` function of the ERC-20 contract.
        Requires the private key of the caller to sign the transaction.
        """
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.burn(_value).build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt

    def buyTokens(self, _value, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.buyTokens().build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'value': _value,  # Value to send with the transaction (in wei)
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt

    def setTokensPerMatic(self, _tokensPerMatic, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.setTokensPerMatic(_tokensPerMatic).build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt

    def withdraw(self, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.withdraw().build_transaction({
            'from': caller_address,
            'gas': 200000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt


    # #######################
    # #### XAM MECHANICS ####
    # #######################

    def getLatestPrice(self):
        """
        Get the latest price from Chainlink's getLatestPrice function.
        """
        # Call the getLatestPrice function
        latest_price = self.contract.functions.getLatestPrice().call()
        return latest_price

    def getHistoricalPrice(self, _roundId):
        historical_price = self.contract.functions.getHistoricalPrice(_roundId).call()
        return historical_price

    def getUserNumBets(self, _address):
        tx_data = self.contract.functions.getUserNumBets().call({
            'from': _address,
        })
        return tx_data

    def getUserUnresolvedNum(self, _address):
        address_bets = self.contract.functions.getUserUnresolvedNum(_address).call()
        return address_bets

    def placeBet(self, _betValue, _betDirection, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.placeBet(_betValue, _betDirection).build_transaction({
            'from': caller_address,
            'gas': 350000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt

    def checkBetPublic(self, _address, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.checkBetPublic(_address).build_transaction({
            'from': caller_address,
            'gas': 350000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt

    def checkAllBets(self, _private_key):
        # Get the caller's account address from the private key
        caller_address = self.w3.eth.account.from_key(_private_key).address

        # Build the transaction
        tx_data = self.contract.functions.checkAllBets().build_transaction({
            'from': caller_address,
            'gas': 450000,  # Adjust the gas limit as needed
            'nonce': self.w3.eth.get_transaction_count(caller_address),
        })

        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx_data, _private_key)

        # Send the signed transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return True, receipt
