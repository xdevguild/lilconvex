elrond_wasm::imports!();

#[elrond_wasm::proxy]
pub trait GovernanceStaking {

    #[payable("*")]
    #[endpoint(increaseAmount)]
    fn increase_amount(
        &self, 
        #[payment_token] payment_token: TokenIdentifier,
        #[payment_amount] payment_amount: BigUint,
    );
}