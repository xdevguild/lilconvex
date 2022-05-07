elrond_wasm::imports!();

use crate::SwapTokensFixedInputResultType;

#[elrond_wasm::proxy]
pub trait Pair {

    #[payable("*")]
    #[endpoint(swapTokensFixedInput)]
    fn swap_tokens_fixed_input(
        &self, 
        token_out: TokenIdentifier,
        amount_out_min: BigUint
    ) -> SwapTokensFixedInputResultType<Self::Api>;

    #[view(getAmountOut)]
    fn get_amount_out_view(&self, token_in: TokenIdentifier, amount_in: BigUint) -> BigUint;

}