#![no_std]

elrond_wasm::imports!();

mod governance_proxy;

// governance testnet address : erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta

#[elrond_wasm::contract]
pub trait Pool {

    #[proxy]
    fn governance_sc_proxy(&self, sc_address: ManagedAddress) -> governance_proxy::Proxy<Self::Api>;

    #[init]
    fn init(
        &self,
        governance_sc_address: ManagedAddress
    ) {
        self.governance_sc_address().set(&governance_sc_address);
    }

    #[payable("*")]
    #[endpoint(increaseAmount)]
    fn increase_amount(
        &self,
        #[payment_token] payment_token: TokenIdentifier,
        #[payment_amount] payment_amount: BigUint,
        timestamp: u64
    ) -> SCResult<()> {
        let governance_sc_address = self.governance_sc_address().get();
        self.governance_sc_proxy(governance_sc_address)
            .increase_amount(
                payment_token,
                payment_amount,
                timestamp
            )
            .transfer_execute();
        Ok(())
    }

    // storage

    #[storage_mapper("governance_sc_address")]
    fn governance_sc_address(&self) -> SingleValueMapper<ManagedAddress>;
}
