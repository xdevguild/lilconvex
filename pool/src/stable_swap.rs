elrond_wasm::imports!();

#[elrond_wasm::proxy]
pub trait StableSwap {

    // WBTC renBTC pool - erd1qqqqqqqqqqqqqpgq79zadfzu2gxdug2ztue6q6aa8xret9qszh0qzx5ncc on devnet

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
    
}