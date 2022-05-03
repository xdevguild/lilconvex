from pathlib import Path

from erdpy.contracts import SmartContract
from erdpy.accounts import Account, Address
from erdpy.environments import TestnetEnvironment
from erdpy.projects import ProjectRust
from erdpy.proxy import ElrondProxy
from erdpy.transactions import Transaction
from eth_typing import Address

# from Python_libraries.const import *
# from Python_libraries.formatter import Formatter
# from Python_libraries.Users import get_users

class Interaction:

    def __init__(self, address) : 

        # self.formatter = Formatter()

        proxy_address = "https://testnet-gateway.elrond.com"
        self.proxy = ElrondProxy(proxy_address)
        self.network = self.proxy.get_network_config()
        self.chain = self.network.chain_id
        self.gas_price = self.network.min_gas_price
        self.tx_version = self.network.min_tx_version

        self.environment = TestnetEnvironment(proxy_address)
        self.user = Account(address).sync_nonce(self.proxy)

        # Users
        # users = get_users()
        # for user in users.values() : 
        #     user.sync_nonce(self.proxy)
     
        # self.users = users

    def deploy(self) : 

        print(self.user)
        
        project = ProjectRust(Path(__file__).parent.parent)
        bytecode = project.get_bytecode()        

        # To deploy, we initialize the smart contract with the compiled bytecode
        self.contract = SmartContract(bytecode=bytecode)

        tx, self.contract_address = self.environment.deploy_contract(
            contract=self.contract,
            owner=self.user,
            arguments=[
                Address("erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta"),
                Address("erd1qqqqqqqqqqqqqpgqaphkarlvclh2c3v0hq2em73gcuxkh5yxj9ts6s5dt2")],
            gas_price=self.gas_price,
            gas_limit=50000000,
            value="0",
            chain=self.chain,
            version=self.tx_version
        )

        print("\nContract address: ", self.contract_address.bech32())

    def use_deployed_SC(self, deployed_SC_address) : 

        self.contract = SmartContract(address=deployed_SC_address)
        self.contract_address = self.contract.address

        print("\nContract address: ", self.contract_address.bech32())


    def authorized_token(self, id) : 

        owner = self.users["owner"]
        payload = "addAuthorizedToken@" + self.formatter.text_to_hex(id) 


        self.transaction(owner, self.contract, payload, value = "0")
        owner.nonce += 1 



    def query_tx_id(self, user):

        address_user = "0x" + user.address.hex()

        tx_id = self.environment.query_contract(self.contract, "getTxId", arguments=[address_user])

        return tx_id


    def query_tx_infos(self, tx_id):

        tx_id_num = [str(tx_id[0].number)]

        tx_infos = self.environment.query_contract(self.contract, "getTxInfos", arguments=tx_id_num)[0].hex

        infos_parsed = self.formatter.tx_infos_parser(tx_infos)
           
        return infos_parsed


    def transaction(self, sender, receiver, payload, value = "0") : 
        
        tx = Transaction()
        tx.nonce = sender.nonce
        tx.value = value
        tx.sender = sender.address.bech32()
        tx.receiver = receiver.address.bech32()
        tx.gasPrice = self.gas_price
        tx.gasLimit = 250000000
        tx.data = payload
        tx.chainID = self.chain
        tx.version = self.tx_version

        tx.sign(sender)
        tx_hash = tx.send(self.proxy)
        return tx_hash   


    def lock(self, user, order): 



        payload = "@".join(["MultiESDTNFTTransfer", self.contract_address.hex(), self.formatter.num_to_hex(len(order["lock"])), \
                            "@".join(["@".join([token["id"], token["nonce"], token["amount"]]) for token in order["lock"]]), \
                            self.formatter.text_to_hex("lock"), \
                            self.formatter.swap_info_input(order["swap"])])
        

        return self.transaction(user, user, payload) 

     

    def format_before_swap(self, swap_tokens) : 

        for token in swap_tokens : 

            token["id"] = self.formatter.text_to_hex(token["id"])
            token["amount"] = self.formatter.num_to_hex(token["amount"])
            token["nonce"] = self.formatter.num_to_hex(token["nonce"])            

        return swap_tokens



    def swap(self, user, tx_id): 

        tx_id_hex = tx_id[0].hex

        try : 
            infos_parsed = self.query_tx_infos(tx_id)
        except: 
            print("Tx not valid : Buyer has withdrawn his funds or the swap has been made")
            return


        swap_tokens = self.format_before_swap(infos_parsed["desired_tokens"])

        payload = "@".join(["MultiESDTNFTTransfer", self.contract_address.hex(), self.formatter.num_to_hex(len(swap_tokens)), \
                            "@".join(["@".join([token["id"], \
                                                token["nonce"], \
                                                token["amount"]]) for token in swap_tokens]), \
                            self.formatter.text_to_hex("swap"), str(tx_id_hex)])


        return self.transaction(user, user, payload) 
 



    def unlock(self, user): 

        return self.transaction(user, self.contract, "unlock") 


 