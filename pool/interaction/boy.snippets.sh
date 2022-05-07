WALLET_PEM="~/Elrond/pems/yum0e0.pem"
MY_ADDRESS="erd1wx7h5rnyxre7avl5pkgj3c2fha9aknrwms8mspelfcapwvjac3vqncm7nm"

PROXY="https://devnet-gateway.elrond.com"
CHAIN="D"
ADDRESS=$(erdpy data load --key=address-BoY)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-BoY)

BYTECODE="./output/pool.wasm"

# holder : https://devnet-explorer.elrond.com/accounts/erd12ndzew55nheac4xfzmuvqp8tzwd42d54c60s4t2saya2kflczh0qgxdzna/tokens
###########################################
GOV_ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta"

SWAP_BTC="erd1qqqqqqqqqqqqqpgqla72lhk8szfdh2l2nt9vflt803uz3prsrmcq2w885d" # OK
SWAP_USDC_USDT="erd1qqqqqqqqqqqqqpgqzxcjxnxsw99lzdjqtcak5x8x39pkxkz0rmcqyl76wx" #OK
SWAP_USDC_WUSDC="erd1qqqqqqqqqqqqqpgq9wj92y9sfw0dua57664hdc5gd656h95yrmcqtnqv5l" # OK

FARM_BTC="erd1qqqqqqqqqqqqqpgqsxwkxy0eqzm30zx0cd0shk47kg3fe4drrmcqhekhv7" # OK
FARM_USDC_USDT="erd1qqqqqqqqqqqqqpgqjynk4kc89vhn8wg42fn6j6ny3t4k87nurmcqne35um" # OK
FARM_USDC_WUSDC="erd1qqqqqqqqqqqqqpgqsn5d6l90xnml6gh3lr2d8gft5kjssx85rmcqlexapt" # OK

PAIR_ASH_USDT="erd1qqqqqqqqqqqqqpgq9efzwnujjm6f75pccujr2jp4j5csym0vrmcqg9r3ff" # OK
PAIR_WBTC_USDC="erd1qqqqqqqqqqqqqpgqkec4u8tkq4tztu30vvk889dnnddex5k8rmcqqnw6a4" # OK
###########################################

sc="0x$(erdpy wallet bech32 --decode erd1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq6gq4hu)"
gov_sc_address="0x$(erdpy wallet bech32 --decode ${GOV_ASHSWAP_SC})"
swap_btc="0x$(erdpy wallet bech32 --decode ${SWAP_BTC})"
swap_usdc_usdt="0x$(erdpy wallet bech32 --decode ${SWAP_USDC_USDT})" 
swap_usdc_wusdc="0x$(erdpy wallet bech32 --decode ${SWAP_USDC_WUSDC})" 

farm_btc="0x$(erdpy wallet bech32 --decode ${FARM_BTC})"
farm_usdc_usdt="0x$(erdpy wallet bech32 --decode ${FARM_USDC_USDT})" 
farm_usdc_wusdc="0x$(erdpy wallet bech32 --decode ${FARM_USDC_WUSDC})" 

pair_ash_usdt="0x$(erdpy wallet bech32 --decode ${PAIR_ASH_USDT})" 
pair_wbtc_usdc="0x$(erdpy wallet bech32 --decode ${PAIR_ASH_USDC})" 
###########################################
btc_id="0x$(echo -n 'RENBTC-0b6973' | xxd -p -u | tr -d '\n')" # OK
wbtc_id="0x$(echo -n 'WBTC-9bdb9b' | xxd -p -u | tr -d '\n')" # OK
usdc_id="0x$(echo -n 'USDC-d5181d' | xxd -p -u | tr -d '\n')" # OK
wusdc_id="0x$(echo -n 'WUSDC-3124eb' | xxd -p -u | tr -d '\n')" # OK
usdt_id="0x$(echo -n 'USDT-a55fa7' | xxd -p -u | tr -d '\n')" # OK
ash_id="0x$(echo -n 'ASH-4ce444' | xxd -p -u | tr -d '\n')" # OK

lp_btc_id="0x$(echo -n 'LPT-8860c3' | xxd -p -u | tr -d '\n')" # OK
lp_usdc_usdt_id="0x$(echo -n 'LPT-999601' | xxd -p -u | tr -d '\n')" # OK
lp_usdc_wusdc_id="0x$(echo -n 'LPT-ea941a' | xxd -p -u | tr -d '\n')" # OK

deploy() {

    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --arguments $ash_id $gov_sc_address $sc \
    --send \
    --outfile="deploy-BoY.interaction.json" || return

    TRANSACTION=$(erdpy data parse --file="deploy-BoY.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-BoY.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-BoY --value=${ADDRESS}
    erdpy data store --key=deployTransaction-BoY --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    erdpy --verbose contract upgrade ${ADDRESS} --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=400000000 \
    --arguments $ash_id $gov_sc_address $sc \
    --outfile="deploy-devnet.interaction.json" \
    --send || return
}

# source interaction/boy.snippets.sh && addLiquidityAndEnterFarmBtc 1000000 10000000 
addLiquidityAndEnterFarmBtc() {
    # add_liquidity to renBTC / WBTC pool and enterFarm with lp token provided

    # $1 first_token_amount_min
    # $2 second_token_amount_min

    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"
    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${btc_id} 00 $1 ${wbtc_id} 00 $2 ${method} ${swap_btc} ${farm_btc} ${lp_btc_id}  \
    --send || return
}

# source interaction/boy.snippets.sh && addLiquidityAndEnterFarmUsdcUsdt 1000000 10000000 
addLiquidityAndEnterFarmUsdcUsdt() {
    # add_liquidity to USDC/USDT pool and enterFarm with lp token provided

    # $1 first_token_amount_min
    # $2 second_token_amount_min

    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"
    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${usdc_id} 00 $1 ${usdt_id} 00 $2 ${method} ${swap_usdc_usdt} ${farm_usdc_usdt} ${lp_usdc_usdt_id}  \
    --send || return
}

# source interaction/boy.snippets.sh && addLiquidityAndEnterFarmUsdcWusdc 1000000 10000000 
addLiquidityAndEnterFarmUsdcWusdc() {
    # add_liquidity to USDC/USDT pool and enterFarm with lp token provided

    # $1 first_token_amount_min
    # $2 second_token_amount_min

    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"
    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${usdc_id} 00 $1 ${wusdc_id} 00 $2 ${method} ${swap_usdc_wusdc} ${farm_usdc_wusdc} ${lp_usdc_wusdc_id}  \
    --send || return
}

compoundUsdcUsdt() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --function="compound" \
    --arguments ${farm_usdc_usdt} ${pair_ash_usdt} ${usdt_id} ${swap_usdc_usdt} ${usdc_id} ${lp_usdc_usdt_id} \
    --send || return
}

compoundUsdcWusdc() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50061012 \
    --function="compoundUsdcWusdc" \
    --arguments ${farm_usdc_wusdc} ${pair_ash_usdt} ${usdt_id} ${swap_usdc_usdt} ${usdc_id} ${swap_usdc_wusdc} ${wusdc_id} ${lp_usdc_wusdc_id} \
    --send || return
}

exitFarmBtc() {
    
     erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="exitFarm" \
        --arguments $farm_btc \
        --send || return
}

exitFarmUsdcUsdt() {
    
     erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="exitFarm" \
        --arguments $farm_usdc_usdt \
        --send || return
}

harvest() {
    # harvest all I got from the sc regarding the token_id and the nonce
    # $1 nonce
    id="0x$(echo -n 'FBW-1c60a3' | xxd -p -u | tr -d '\n')"
     erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="harvest" \
        --arguments $id $1 \
        --send || return
}

testPair() {
    # $1 token_in
    # $2 amount_min_out
    method="0x$(echo -n 'swapTokensFixedInput' | xxd -p -u | tr -d '\n')"
     erdpy --verbose contract call ${PAIR_ASH_USDT} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="ESDTTransfer" \
        --arguments $ash_id $1 $method $usdt_id $2 \
        --send || return
}

claimRewardsInContract() {

    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="claimRewardsInContract"  \
    --arguments ${farm_usdc_usdt} \
    --send || return
}

exchange_btc1() {
    # exchange WBTC to renBTC
    # $1 amount to exchange
    
    token_to_pay_with="0x$(echo -n 'BTC-573344' | xxd -p -u | tr -d '\n')" # DDAY WBTC-027977
    method="0x$(echo -n 'exchange' | xxd -p -u | tr -d '\n')"
    token_to_receive="0x$(echo -n 'WBTC-3a02ea' | xxd -p -u | tr -d '\n')"  # DDAY RENBTC-8cd185

    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="ESDTTransfer" \
        --arguments $token_to_pay_with $1 $method $token_to_receive 0 \
        --send || return
}

exchange_btc2() {
    # exchange renBTC to WBTC
    # $1 amount to exchange
    token_to_pay_with="0x$(echo -n 'WBTC-3a02ea' | xxd -p -u | tr -d '\n')" # DDAY RENBTC-8cd185
    method="0x$(echo -n 'exchange' | xxd -p -u | tr -d '\n')"
    token_to_receive="0x$(echo -n 'BTC-573344' | xxd -p -u | tr -d '\n')" # DDAY WBTC-027977

    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="ESDTTransfer" \
        --arguments $token_to_pay_with $1 $method $token_to_receive 0 \
        --send || return
}

increaseAmount() {

    # $1 amount
    token_id="$(echo -n 'ASH-76f082' | xxd -p -u | tr -d '\n')"
    method="$(echo -n 'increaseAmount' | xxd -p -u | tr -d '\n')"

    erdpy --verbose tx new --receiver=${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=600000000 \
    --value=0 \
    --data="ESDTTransfer@${token_id}@$1@${method}" \
    --send
}

supply() {
    erdpy contract query ${GOV_ASHSWAP_SC} --proxy=$PROXY --function=supply
}

totalLock() {
    erdpy contract query ${GOV_ASHSWAP_SC} --proxy=$PROXY --function=totalLock
}

balanceOfAtBlock() {
    erdpy contract query ${GOV_ASHSWAP_SC} --proxy=$PROXY --function=balanceOfAtBlock
}

getTransferExecGasLimit() {
    erdpy contract query ${GOV_ASHSWAP_SC} --proxy=$PROXY --function=getTransferExecGasLimit
}

getLpTokenIdentifier() {
    erdpy contract query ${SWAP_ASHSWAP_SC} --proxy=$PROXY --function=getLpTokenIdentifier # for USDC/USDT
}

# FARM

getFarmTokenId() {
    erdpy contract query ${FARM_ASHSWAP_SC} --proxy=$PROXY --function=getFarmTokenId # FUU-0cf97f
}

getFarmTokenSupply() {
    erdpy contract query ${FARM_ASHSWAP_SC} --proxy=$PROXY --function=getFarmTokenSupply 
}

getFarmingTokenId() {
    erdpy contract query ${FARM_ASHSWAP_SC} --proxy=$PROXY --function=getFarmingTokenId # LPT-89ce1b
}

getRewardTokenId() {
    erdpy contract query ${FARM_ASHSWAP_SC} --proxy=$PROXY --function=getRewardTokenId # ASH-76f082
}

getFarmResult() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=farmResult # ASH-76f082
}

getRewardPerShare() {
    erdpy contract query ${FARM_ASHSWAP_SC} --proxy=$PROXY --function=getRewardPerShare
}

# MINE

getFarmTokenAmount() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=getFarmTokenAmount
}

getFarmTokenInfos() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=getFarmTokenInfos
}

getRewardTokenInfos() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=getRewardTokenInfos
}

getA() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=getA
}

getB() {
    erdpy contract query ${ADDRESS} --proxy=$PROXY --function=getB
}
