#![no_std]

elrond_wasm::imports!();

mod governance_proxy;
use governance_proxy::*;

/// An empty contract. To be used as a template when starting a new contract from scratch.
#[elrond_wasm::contract]
pub trait Pool {

    #[proxy]
    fn governance_sc(&self, sc_address: ManagedAddress) -> governance_proxy::Proxy<Self::Api>;

    #[init]
    fn init(
        &self,
        governance_sc_address: ManagedAddress
    ) {
        self.governance_sc_address().set(&governance_sc_address);
    }

    // storage

    #[storage_mapper("governance_sc_address")]
    fn governance_sc_address(&self) -> SingleValueMapper<ManagedAddress>;


}
