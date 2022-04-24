import os
import logging
from pathlib import Path
from erdpy import utils

from erdpy.accounts import Account, Address
from erdpy.contracts import CodeMetadata, SmartContract
from erdpy.proxy.core import ElrondProxy

logger = logging.getLogger("lilconvex")

# current address: erd1qqqqqqqqqqqqqpgqffdmjd2de3757yl3pf2g0mydteuzzrn57fysjn2e97

if __name__ == "__main__":
    
    """
    python3 scripts/deploy.py 
    """

    proxy_url = "https://testnet-gateway.elrond.com"
    

    logging.basicConfig(level=logging.DEBUG)

    proxy = ElrondProxy(proxy_url)
    network = proxy.get_network_config()
    owner = Account(pem_file=os.environ["PEM"])

    bytecode_path = Path("pool/output/pool.wasm").absolute()
    bytecode = utils.read_binary_file(bytecode_path).hex()
    code_metadata = CodeMetadata(upgradeable=True, payable=True)
    contract = SmartContract(bytecode=bytecode, metadata=code_metadata)

    owner.sync_nonce(proxy)

    #print("0x" + Address("erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta").hex())

    tx = contract.deploy(
        owner=owner,
        arguments=["0x" + Address("erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta").hex()], # erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta -> 0x0000000000000000050060f0f33d5ac26b5b5978f4aeed6d0b0f0ada61ca9157 
        gas_price=network.min_gas_price,
        gas_limit=20000000,
        value=0,
        chain=network.chain_id,
        version=network.min_tx_version
    )

    tx_on_network = tx.send_wait_result(proxy, 5000)

    logger.info(f"Deployment transaction: {tx_on_network.get_hash()}")
    logger.info(f"Contract address: {contract.address.bech32()}")

