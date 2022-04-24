elrond_wasm::imports!();

#[elrond_wasm::proxy]
pub trait GovernanceStaking {
    #[payable("*")]
    #[endpoint(myEndpoint)]
    fn my_payable_endpoint(
        &self, 
        #[payment_token] payment_token: TokenIdentifier,
        #[payment_nonce] payment_nonce: u64,
        #[payment_amount] payment_amount: BigUint,
        arg: BigUint) -> BigUint;
}