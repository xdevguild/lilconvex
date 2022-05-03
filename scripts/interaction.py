import os
import logging
from pathlib import Path
from erdpy import utils

from erdpy.accounts import Account, Address
from erdpy.contracts import CodeMetadata, SmartContract, 
from erdpy.proxy.core import ElrondProxy

logger = logging.getLogger("lilconvex")

if __name__ == "__main__":
    
    """
    python3 scripts/deploy.py 
    """

    proxy_url = "https://testnet-gateway.elrond.com"
    

    logging.basicConfig(level=logging.DEBUG)

    proxy = ElrondProxy(proxy_url)
    network = proxy.get_network_config()
    owner = Account(pem_file=os.environ["PEM"])

 #erd1qqqqqqqqqqqqqpgqkntm842lagcc2h0nyrynqd5f6ncpwdx07fyst5dmag
    contract = SmartContract(address=Address("erd1qqqqqqqqqqqqqpgq9menvfhd2ufdwexllrr4yrscudg0z4ma7fys3t40y8"))

    owner.sync_nonce(proxy)

    # ASH-76f082 -> 4153482d373666303832
    # 1000000000000000000 -> 0de0b6b3a7640000
    # increase_amount -> 696e6372656173655f616d6f756e74

    tx = contract.execute(
        caller=owner,
        function="addLiquidity",
        arguments=[
            10, 
            10,
            EsdtTokenPayment ],
        gas_price=network.min_gas_price,
        gas_limit=20000000,
        value=0,
        chain=network.chain_id,
        version=network.min_tx_version
    )

    tx_on_network = tx.send_wait_result(proxy, 5000)

    logger.info(f"Deployment transaction: {tx_on_network.get_hash()}")