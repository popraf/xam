from decouple import config

CONTRACT_ADDRESS = config('CONTRACT_ADDRESS')
print(CONTRACT_ADDRESS)

from web3 import Web3

# Replace the RPC endpoint with the appropriate one for the Polygon network you want to connect to
w3 = Web3(Web3.HTTPProvider('https://polygon-mumbai-bor.publicnode.com'))

# Check connection status
print(w3.net.version)

# print('Balance: ', w3.eth.balanceOf())
import json

