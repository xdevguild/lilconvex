#![no_std]

elrond_wasm::imports!();

mod stable_swap;
mod farm;
mod pair;

pub type SwapTokensFixedInputResultType<BigUint> = EsdtTokenPayment<BigUint>;
pub type EnterFarmResultType<BigUint> = EsdtTokenPayment<BigUint>;
pub type ClaimRewardsResultType<BigUint> =
    MultiValue2<EsdtTokenPayment<BigUint>, EsdtTokenPayment<BigUint>>;

// compound contract on shard 0 : erd1qqqqqqqqqqqqqpgqk4ettjn427uylpatu0hpzksjckecletgc3vqlyu4wd

#[elrond_wasm::contract]
pub trait CompoundContract {

    #[proxy]
    fn stableswap_contract(&self, sc_address: ManagedAddress) -> stable_swap::Proxy<Self::Api>;

    #[proxy]
    fn farm_contract(&self, sc_address: ManagedAddress) -> farm::Proxy<Self::Api>;

    #[proxy]
    fn pair_contract(&self, sc_address: ManagedAddress) -> pair::Proxy<Self::Api>;

    #[init]
    fn init(
        &self,
        ash_id: TokenIdentifier,
        governance_sc_address: ManagedAddress,
        sc: ManagedAddress
    ) {
        self.governance_sc_address().set(&governance_sc_address);
        self.ash_id().set(&ash_id);
        self.sc().set(&sc);

        self.reward_token_infos().set_if_empty(
            &EsdtTokenPayment::new(
                ash_id,
                0,
                BigUint::zero()
            )
        );
    }

    #[only_owner]
    #[endpoint(harvest)]
    fn harvest(
        &self,
        token_to_harvest: TokenIdentifier,
        nonce: u64
    ) {
        self.send()
            .direct(
                &self.blockchain().get_caller(),
                &token_to_harvest,
                nonce.clone(),
                &self.blockchain().get_sc_balance(
                    &token_to_harvest,
                    nonce
                ),
                &[]
            );
    }

    #[payable("*")]
    #[endpoint(addLiquidityAndEnterFarm)]
    fn add_liquidity_and_enter_farm(
        &self,
        swap_sc: ManagedAddress,
        target_farm_sc: ManagedAddress,
        lp_token_id: TokenIdentifier,
    ) {

        // you receive the tokens only for AddingLiquidity 
        let payments = self.call_value().all_esdt_transfers();
        let first_payment_token = payments.get(0);
        let second_payment_token = payments.get(1);

        // add liquidity to stableswap with USDC and USDT balance of the sc
        self.stableswap_contract(swap_sc)
            .add_liquidity(
                self.blockchain().get_sc_balance(
                    &first_payment_token.token_identifier,
                    0),
                self.blockchain().get_sc_balance(
                    &second_payment_token.token_identifier,
                    0),
                self.sc().get())
            .with_multi_token_transfer(payments)   
            .execute_on_dest_context();

        // enter farm with LPUSDCUSDT
        // you have to send the amount of LP you want to enterFarm with 
        // + the amount of FUU-0cf97f you have 

        let mut payments_enter_farm: ManagedVec<EsdtTokenPayment<Self::Api>> = ManagedVec::new();

        // create payment tokens for entering farm
        let lp_token_clone = lp_token_id.clone();
        payments_enter_farm.push(
            EsdtTokenPayment::new(
                lp_token_id,
                0,
                self.blockchain().get_sc_balance(
                    &lp_token_clone,
                    0
                )
            )
        );

        // retrieve the token that have been sent to you before for entering farm
        // set a farm token for the specific farm address if empty, does not have to be the correct ticker but nonce should be zero
        // with nonce zero, it will NOT be pushed as a payment token
        self.farm_token_infos(target_farm_sc.clone()).set_if_empty(
            &EsdtTokenPayment::new(
                TokenIdentifier::from_esdt_bytes("FUU-0cf97f".as_bytes()),
                0,
                BigUint::zero()
            )
        );

        // get the farm token informations
        let farm_token = self.farm_token_infos(target_farm_sc.clone()).get();

        // only push this paymentToken if the nonce is != 0 (nonce at the contract deployment)
        if farm_token.token_nonce != 0 {
            payments_enter_farm.push(farm_token);
        }

        // enter farm with LPT and send FUU to the contract
        let result_farm_entering: EnterFarmResultType<Self::Api> = self.farm_contract(target_farm_sc.clone())
            .enter_farm()
            .with_multi_token_transfer(payments_enter_farm)
            .execute_on_dest_context_custom_range(|_, after| (after - 1, after));
        
        // store new farm token
        self.farm_token_infos(target_farm_sc.clone()).set(&result_farm_entering);
    }

    #[endpoint(addLiquidityAndEnterFarmWhenCompounding)]
    fn add_liquidity_and_enter_farm_when_compounding(
        &self,
        swap_sc: ManagedAddress,
        target_farm_sc: ManagedAddress,
        lp_token_id: TokenIdentifier,
        first_token: TokenIdentifier,
        second_token: TokenIdentifier,
    ) {

        let mut payments = ManagedVec::new();
        // push first token that is the token out when swapping from ash (is likely USDT)
        payments.push(
            EsdtTokenPayment::new(
                first_token.clone(),
                0,
                self.blockchain().get_sc_balance(&first_token, 0)
            )
        );
        // add USDC
        payments.push(
            EsdtTokenPayment::new(
                second_token.clone(),
                0,
                self.blockchain().get_sc_balance(&second_token, 0)
            )
        );

        // add liquidity to stableswap with USDC and USDT balance of the sc
        self.stableswap_contract(swap_sc)
            .add_liquidity(
                self.blockchain().get_sc_balance(
                    &first_token,
                    0),
                self.blockchain().get_sc_balance(
                    &second_token,
                    0),
                self.sc().get())
            .with_multi_token_transfer(payments)   
            .execute_on_dest_context();

        // enter farm with LPUSDCUSDT
        // you have to send the amount of LP you want to enterFarm with 
        // + the amount of FUU-0cf97f you have 

        let mut payments_enter_farm: ManagedVec<EsdtTokenPayment<Self::Api>> = ManagedVec::new();

        // create payment tokens for entering farm
        let lp_token_clone = lp_token_id.clone();
        payments_enter_farm.push(
            EsdtTokenPayment::new(
                lp_token_id,
                0,
                self.blockchain().get_esdt_balance(
                    &self.blockchain().get_sc_address(),
                    &lp_token_clone,
                    0
                )
            )
        );

        // retrieve the token that have been sent to you before for entering farm
        // set a farm token for the specific farm address if empty, does not have to be the correct ticker but nonce should be zero
        // with nonce zero, it will NOT be pushed as a payment token
        self.farm_token_infos(target_farm_sc.clone()).set_if_empty(
            &EsdtTokenPayment::new(
                lp_token_clone,
                0,
                BigUint::zero()
            )
        );

        // get the farm token informations
        let farm_token = self.farm_token_infos(target_farm_sc.clone()).get();

        // only push this paymentToken if the nonce is != 0 (nonce at the contract deployment)
        if farm_token.token_nonce != 0 {
            payments_enter_farm.push(farm_token);
        }

        // enter farm with LPT and send FUU to the contract
        let result_farm_entering: EnterFarmResultType<Self::Api> = self.farm_contract(target_farm_sc.clone())
            .enter_farm()
            .with_multi_token_transfer(payments_enter_farm)
            .execute_on_dest_context_custom_range(|_, after| (after - 1, after));
        
        // store new farm token
        self.farm_token_infos(target_farm_sc.clone()).set(&result_farm_entering);
    }

    #[endpoint(claimRewardsInContract)]
    fn claim_rewards_in_contract(
        &self,
        target_farm_sc: ManagedAddress, // we provide the farm sc in args in order to create versatile functions
    ) {
        // harvest informations about farm token in order to send `lp_amount` of tokens to farm contract and receive reward
        let farm_token_infos = self.farm_token_infos(target_farm_sc.clone()).get();

        let claim_farm_result: ClaimRewardsResultType<Self::Api> = self.farm_contract(target_farm_sc.clone())
            .claim_rewards()
            .add_token_transfer(
                farm_token_infos.token_identifier,
                farm_token_infos.token_nonce,
                farm_token_infos.amount,
            )
            .execute_on_dest_context_custom_range(|_, after| (after - 2, after));

        let (new_staking_farm_token, reward_token) = claim_farm_result.into_tuple();

        self.farm_token_infos(target_farm_sc).set(new_staking_farm_token);
        self.reward_token_infos().set(reward_token);
    }

    #[endpoint(compound)]
    fn compound(
        &self,
        target_farm_sc: ManagedAddress,
        pair_sc: ManagedAddress,
        token_out: TokenIdentifier,
        swap_sc: ManagedAddress,
        token_to_receive: TokenIdentifier, // the token that you will exchange from usdt (so USDC)
        lp_token_id: TokenIdentifier
    ) {
        // 1. claim rewards
        self.claim_rewards_in_contract(target_farm_sc.clone());

        // 2. swap ash to usdt

        let ash_id = self.ash_id().get();
        let ash_amount = self.blockchain().get_sc_balance(&ash_id, 0);

        // we retrieve the payment token (USDT during BoY)
        self.pair_contract(pair_sc)
            .swap_tokens_fixed_input(token_out.clone(), BigUint::from(1u64)) // 1 in order to avoid slippage errors
            .add_token_transfer(
                self.ash_id().get(),
                0,
                ash_amount
            )
            .execute_on_dest_context();

        // 3. swap usdt to usdc
        // take half of the USDT
        let mut payment_amount = self.blockchain().get_sc_balance(&token_out, 0) * BigUint::from(495u64);
        payment_amount = payment_amount / BigUint::from(1000u64); // 49.5 %

        
        // // swap the usdt to usdc
        self.stableswap_contract(swap_sc.clone())
            .exchange(token_to_receive.clone(), 0)
            .add_token_transfer(
                token_out.clone(),
                0,
                payment_amount
            )
            .execute_on_dest_context();

        // 4. add liquidity and enter farm

        // usdc BEFORE usdt when adding liquidity
        self.add_liquidity_and_enter_farm_when_compounding(swap_sc, target_farm_sc, lp_token_id, token_to_receive, token_out);
    }

    #[endpoint(compoundUsdcWusdc)]
    fn compound_usdc_wusdc(
        &self,
        target_farm_sc: ManagedAddress,
        pair_sc: ManagedAddress,
        token_out: TokenIdentifier,
        swap_sc: ManagedAddress,
        token_to_receive: TokenIdentifier, // the token that you will exchange from usdt (so USDC)
        second_swap: ManagedAddress,
        wusdc_id: TokenIdentifier,
        lp_token_id: TokenIdentifier
    ) {
        // 1. claim rewards
        self.claim_rewards_in_contract(target_farm_sc.clone());

        // 2. swap ash to usdt

        let ash_id = self.ash_id().get();
        let ash_amount = self.blockchain().get_sc_balance(&ash_id, 0);

        // we retrieve the payment token (USDT during BoY)
        self.pair_contract(pair_sc)
            .swap_tokens_fixed_input(token_out.clone(), BigUint::from(1u64)) // 1 in order to avoid slippage errors
            .add_token_transfer(
                self.ash_id().get(),
                0,
                ash_amount
            )
            .execute_on_dest_context();

        // 3. swap usdt to usdc
        // take all the usdt
        let payment_amount = self.blockchain().get_sc_balance(&token_out, 0);

        // // swap the usdt to usdc
        self.stableswap_contract(swap_sc.clone())
            .exchange(token_to_receive.clone(), 0)
            .add_token_transfer(
                token_out.clone(),
                0,
                payment_amount
            )
            .execute_on_dest_context();

        // 4. swap usdc to  wusdc
        // take half of the USDC
        let mut payment_amount_wusdc = self.blockchain().get_sc_balance(&token_to_receive, 0) * BigUint::from(495u64);
        payment_amount_wusdc = payment_amount_wusdc / BigUint::from(1000u64); // 49.5 %

        // // swap the usdc to wusdc
        self.stableswap_contract(second_swap.clone())
            .exchange(wusdc_id.clone(), 0)
            .add_token_transfer(
                token_to_receive.clone(),
                0,
                payment_amount_wusdc
            )
            .execute_on_dest_context();
        
        // 5. add liquidity and enter farm

        // usdc BEFORE usdt when adding liquidity
        self.add_liquidity_and_enter_farm_when_compounding(second_swap, target_farm_sc, lp_token_id, token_to_receive, wusdc_id);
    }

    #[endpoint(compoundBtc)]
    fn compound_btc(
        &self,
        target_farm_sc: ManagedAddress,
        pair_sc: ManagedAddress,
        token_out: TokenIdentifier,
        swap_sc: ManagedAddress,
        token_to_receive: TokenIdentifier, // the token that you will exchange from usdt (so USDC)
        second_pair_sc: ManagedAddress,
        wbtc_id: TokenIdentifier,
        btc_swap: ManagedAddress,
        btc_id: TokenIdentifier,
        lp_token_id: TokenIdentifier
    ) {
        // 1. claim rewards
        self.claim_rewards_in_contract(target_farm_sc.clone());

        // 2. swap ash to usdt
        let ash_id = self.ash_id().get();
        let ash_amount = self.blockchain().get_sc_balance(&ash_id, 0);

        // we retrieve the payment token (USDT during BoY)
        self.pair_contract(pair_sc)
            .swap_tokens_fixed_input(token_out.clone(), BigUint::from(1u64)) // 1 in order to avoid slippage errors
            .add_token_transfer(
                self.ash_id().get(),
                0,
                ash_amount
            )
            .execute_on_dest_context();

        // 3. swap usdt to usdc
        // take all the usdt
        let payment_amount = self.blockchain().get_sc_balance(&token_out, 0);

        // // swap the usdt to usdc
        self.exchange(
            swap_sc.clone(), 
            token_to_receive.clone(), 
            0, 
            token_out.clone(),
            payment_amount);

        // 4. swap usdc to  wbtc
        // sell all usdc to WBTC
        let payment_amount_wbtc = self.blockchain().get_sc_balance(&token_to_receive, 0);

        // // swap the usdc to wbtc
        // self.swap_tokens(
        //     second_pair_sc.clone(), 
        //     wbtc_id.clone(), 
        //     BigUint::zero(), 
        //     token_to_receive.clone(), 
        //     payment_amount_wbtc);
        
        self.pair_contract(second_pair_sc.clone())
            .swap_tokens_fixed_input(wbtc_id.clone(), BigUint::from(1u64))
            .add_token_transfer(
                token_to_receive.clone(),
                0,
                payment_amount_wbtc
            )
            .execute_on_dest_context();

        // 5. Swap half of wbtc to btc
        let mut payment_amount_btc = self.blockchain().get_sc_balance(&wbtc_id, 0) * BigUint::from(495u64);
        payment_amount_btc = payment_amount_btc / BigUint::from(1_000u64); // 49.5% 

        // swap the wbtc to btc
        self.exchange(
            btc_swap.clone(), 
            btc_id.clone(), 
            0, 
            wbtc_id.clone(), 
            payment_amount_btc);

        // 6. add liquidity and enter farm

        // usdc BEFORE usdt when adding liquidity
        self.add_liquidity_and_enter_farm_when_compounding(btc_swap, target_farm_sc, lp_token_id, btc_id, wbtc_id);
    }

    #[endpoint(compoundAll)]
    fn compound_all(
        &self,
        farm_usdc_usdt: ManagedAddress,
        farm_usdc_wusdc: ManagedAddress,
        farm_btc: ManagedAddress,
        pair_ash_usdt: ManagedAddress,
        pair_wbtc_usdc: ManagedAddress,
        usdt_id: TokenIdentifier,
        usdc_id: TokenIdentifier, 
        wusdc_id: TokenIdentifier,
        wbtc_id: TokenIdentifier,
        btc_id: TokenIdentifier,
        swap_usdc_usdt: ManagedAddress,
        swap_usdc_wusdc: ManagedAddress,
        btc_swap: ManagedAddress,
        lp_usdc_usdt_id: TokenIdentifier,
        lp_usdc_wusdc_id: TokenIdentifier,
        lp_btc_id: TokenIdentifier
    ) {
        self.compound(
            farm_usdc_usdt, 
            pair_ash_usdt.clone(), 
            usdt_id.clone(), 
            swap_usdc_usdt.clone(), 
            usdc_id.clone(), 
            lp_usdc_usdt_id);

        self.compound_usdc_wusdc(
            farm_usdc_wusdc, 
            pair_ash_usdt.clone(), 
            usdt_id.clone(), 
            swap_usdc_usdt.clone(), 
            usdc_id.clone(), 
            swap_usdc_wusdc, 
            wusdc_id, 
            lp_usdc_wusdc_id);

        self.compound_btc(
            farm_btc, 
            pair_ash_usdt, 
            usdt_id, 
            swap_usdc_usdt,
            usdc_id, 
            pair_wbtc_usdc, 
            wbtc_id, 
            btc_swap, 
            btc_id, 
            lp_btc_id);
    }

    #[endpoint(exitFarm)]
    fn exit_farm(
        &self,
        farm_sc: ManagedAddress
    ) {
        // exit farm and receive ash in contract
        let farm_token_infos = self.farm_token_infos(farm_sc.clone()).get();
        let mut new_farm_token_infos = farm_token_infos.clone();
        self.farm_contract(farm_sc.clone())
            .exit_farm()
            .add_token_transfer(
                farm_token_infos.token_identifier,
                farm_token_infos.token_nonce,
                farm_token_infos.amount,
            )
            .execute_on_dest_context();
        
        // update the nonce to zero in order to trigger addLiquidityAndEnterFarm again
        // new NFT data sender issue if not doing this
        new_farm_token_infos.token_nonce = 0;
        self.farm_token_infos(farm_sc).set(&new_farm_token_infos);
    }

    #[payable("*")]
    #[endpoint(increaseAmount)]
    fn increase_amount(
        &self,
        #[payment_token] payment_token: TokenIdentifier,
        #[payment_amount] payment_amount: BigUint
    ) {
        let governance_sc_address = self.governance_sc_address().get();

        self.send().direct_with_gas_limit(
            &governance_sc_address,
            &payment_token,
            0,
            &payment_amount,
            100_000_000,
            ManagedBuffer::new_from_bytes("increaseAmount".as_bytes()),
            &[]
        )
    }

    // view 

    #[view(getFarmTokenAmount)]
    fn get_farm_token_amount(&self, target_farm_sc: ManagedAddress) -> BigUint {
        let farm_token_infos = self.farm_token_infos(target_farm_sc).get();
        farm_token_infos.amount
    }

    // private

    fn exchange(
        &self,
        swap_sc: ManagedAddress,
        token_to_receive: TokenIdentifier,
        index: u64,
        payment_token_id: TokenIdentifier,
        payment_token_amount: BigUint
    ) {
        self.stableswap_contract(swap_sc)
            .exchange(token_to_receive, index)
            .add_token_transfer(
                payment_token_id,
                0,
                payment_token_amount
            )
            .execute_on_dest_context();
    }

    fn swap_tokens(
        &self,
        pair_sc: ManagedAddress,
        token_out: TokenIdentifier,
        amount_out_min: BigUint,
        payment_token_id: TokenIdentifier,
        payment_token_amount: BigUint
    ) {
        self.pair_contract(pair_sc)
            .swap_tokens_fixed_input(token_out, amount_out_min)
            .add_token_transfer(
                payment_token_id,
                0,
                payment_token_amount
            )
            .execute_on_dest_context();
    }
    
    // storage

    #[storage_mapper("governance_sc_address")]
    fn governance_sc_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("ash_id")]
    fn ash_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[storage_mapper("sc")]
    fn sc(&self) -> SingleValueMapper<ManagedAddress>;

    #[view(getFarmTokenInfos)]
    #[storage_mapper("farm_token_infos")]
    fn farm_token_infos(&self, addr: ManagedAddress) -> SingleValueMapper<EsdtTokenPayment<Self::Api>>;

    #[view(getRewardTokenInfos)]
    #[storage_mapper("reward_token_infos")]
    fn reward_token_infos(&self) -> SingleValueMapper<EsdtTokenPayment<Self::Api>>;

    #[view(getA)]
    #[storage_mapper("a")]
    fn a(&self) -> SingleValueMapper<BigUint>;

    #[view(getB)]
    #[storage_mapper("b")]
    fn b(&self) -> SingleValueMapper<BigUint>;

}
