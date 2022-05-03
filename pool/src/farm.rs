elrond_wasm::imports!();

use crate::{EnterFarmResultType, ClaimRewardsResultType};

// address: erd1qqqqqqqqqqqqqpgqrn64ujp5m8c6l2k58v7qgtn8f48u6d29j9ts27qugg
#[elrond_wasm::proxy]
pub trait Farm {
    // USDC USDT Farm

    #[payable("*")]
    #[endpoint(enterFarm)]
    fn enter_farm<M: ManagedTypeApi>(
        &self
    ) -> EnterFarmResultType<M>;

    #[payable("*")]
    #[endpoint(exitFarm)]
    fn exit_farm(
        &self
    );

    #[payable("*")]
    #[endpoint(claimRewards)]
    fn claim_rewards<M: ManagedTypeApi>(
        &self
    ) -> ClaimRewardsResultType<M>;
}