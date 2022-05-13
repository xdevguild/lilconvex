elrond_wasm::imports!();

#[elrond_wasm::proxy]
pub trait StableSwap {

    #[payable("*")]
    #[endpoint(addLiquidity)]
    fn add_liquidity(
        &self, 
        first_token_amount_min: BigUint,
        second_token_amount_min: BigUint,
        sc: ManagedAddress
    );

    #[payable("*")]
    #[endpoint(exchange)]
    fn exchange(
        &self,
        token_to_receive: TokenIdentifier,
        index: u64);

    #[payable("*")]
    #[endpoint(removeLiquidity)]
    fn remove_liquidity(
        &self,
        min_first_token_out: BigUint,
        min_second_token_out: BigUint
    );
    
}