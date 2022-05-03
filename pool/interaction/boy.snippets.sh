WALLET_PEM="~/Elrond/pems/yum0e2.pem"
MY_ADDRESS="erd1yq2v0rpt5h2lfa8ljkgu6mchrjvy6en3ywe2wfnnjun2rs4qu8nqalcfe5"

PROXY="https://devnet-gateway.elrond.com"
CHAIN="D"
ADDRESS=$(erdpy data load --key=address-BoY)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-BoY)

BYTECODE="./output/pool.wasm"

# holder : https://devnet-explorer.elrond.com/accounts/erd12ndzew55nheac4xfzmuvqp8tzwd42d54c60s4t2saya2kflczh0qgxdzna/tokens
###########################################
GOV_ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta"

SWAP_BTC="erd1qqqqqqqqqqqqqpgq79zadfzu2gxdug2ztue6q6aa8xret9qszh0qzx5ncc" # OK
SWAP_USDC_USDT="erd1qqqqqqqqqqqqqpgq392nv8mkrhwvkaff2qlqcd5yj8jeexpmzh0q4us968" #OK
SWAP_USDC_WUSDC="erd1qqqqqqqqqqqqqpgqskct0n779lg9decdw6gvzcsx3xmxganezh0q5m8grk" # OK

FARM_BTC="erd1qqqqqqqqqqqqqpgqcx652pqh8fya2weavz253ttznaltyx4zzh0qw5t4dm" # NOT YETTTTTTTTTTTTTTTTTTT
FARM_USDC_USDT="erd1qqqqqqqqqqqqqpgqze4g0hcvp9usk9kqvpdcaehqu7ycav5szh0qz8wur9" # OK
FARM_USDC_WUSDC="erd1qqqqqqqqqqqqqpgqlaa4vmv6zcujzjrw2u0lqx8fy8hu45mlzh0qej9jya" # OK

PAIR_ASH_USDT="erd1qqqqqqqqqqqqqpgqp8mhm4dzt4vusdt2g36smup2f5vrtgrszh0qdpeqxx" # 
PAIR_WBTC_USDC="erd1qqqqqqqqqqqqqpgqe3wfkwqm49jmfeehc6apl59h6rv2h29lzh0qsg3ey5" # OK
###########################################

sc="0x$(erdpy wallet bech32 --decode erd1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq6gq4hu)"
gov_sc_address="0x$(erdpy wallet bech32 --decode ${GOV_ASHSWAP_SC})"
swap_btc="0x$(erdpy wallet bech32 --decode ${SWAP_BTC})"
swap_usdc_usdt="0x$(erdpy wallet bech32 --decode ${SWAP_USDC_USDT})" 
swap_usdc_wusdc="0x$(erdpy wallet bech32 --decode ${SWAP_USDC_WUSDC})" 

farm_btc="0x$(erdpy wallet bech32 --decode ${FARM_BTC})"
farm_usdc_usdt="0x$(erdpy wallet bech32 --decode ${FARM_USDC_USDT})" 
farm_usdc_wusdc="0x$(erdpy wallet bech32 --decode ${FARM_USDC_WUSDC})" 

pair_ash_usdt="0x$(erdpy wallet bech32 --decode ${SWAP_ASH_USDC})" 
pair_wbtc_usdc="0x$(erdpy wallet bech32 --decode ${PAIR_ASH_USDC})" 
###########################################
btc_id="0x$(echo -n 'RENBTC-8cd185' | xxd -p -u | tr -d '\n')" # OK
wbtc_id="0x$(echo -n 'WBTC-027977' | xxd -p -u | tr -d '\n')" # OK
usdc_id="0x$(echo -n 'USDC-fecc49' | xxd -p -u | tr -d '\n')" # OK
wusdc_id="0x$(echo -n 'WUSDC-f93edf' | xxd -p -u | tr -d '\n')" # OK
usdt_id="0x$(echo -n 'USDT-fedd98' | xxd -p -u | tr -d '\n')" # OK
ash_id="0x$(echo -n 'ASH-f7c9ea' | xxd -p -u | tr -d '\n')" # OK

lp_btc_id="0x$(echo -n 'LPT-0b4585' | xxd -p -u | tr -d '\n')" # OK
lp_usdc_usdt_id="0x$(echo -n 'LPT-44f690' | xxd -p -u | tr -d '\n')" # OK
lp_usdc_wusdc_id="0x$(echo -n 'LPT-8f1594' | xxd -p -u | tr -d '\n')" # OK

deploy() {

    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=400000000 \
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
    --outfile="deploy-BoY.interaction.json" \
    --send || return
}

# source interaction/BoY.snippets.sh && addLiquidityAndEnterFarmBtc 1000000 10000000 
addLiquidityAndEnterFarmBtc() {
    # add_liquidity to renBTC / WBTC pool and enterFarm with lp token provided

    # $1 first_token_amount_min
    # $2 second_token_amount_min

    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"
    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${btc_id} 00 $1 ${wbtc_id} 00 $2 ${method} ${swap_btc} ${farm_btc} ${lp_btc_id}  \
    --send || return
}

# source interaction/BoY.snippets.sh && addLiquidityAndEnterFarmBtc 1000000 10000000 
addLiquidityAndEnterFarmUsdc() {
    # add_liquidity to renBTC / WBTC pool and enterFarm with lp token provided

    # $1 first_token_amount_min
    # $2 second_token_amount_min

    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"
    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${usdc_id} 00 $1 ${usdt_id} 00 $2 ${method} ${swap_usdc_usdt} ${farm_usdc_usdt} ${lp_usdc_usdt_id}  \
    --send || return
}

compound() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="compound"  \
    --arguments ${farm_usdc_usdt} ${pair_ash_usdc} ${usdc_id} ${swap_usdc_usdt} ${usdt_id} ${lp_usdc_usdt_id} \
    --send || return
}

harvest() {
     erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="harvest" \
        --arguments $ash_id 1000000000000000000 \
        --send || return
}

testPair() {
    # $1 token_out
    # $2 amount_min_out
    method="0x$(echo -n 'swapTokensFixedInput' | xxd -p -u | tr -d '\n')"
     erdpy --verbose contract call ${PAIR_ASH_USDC} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="ESDTTransfer" \
        --arguments $ash_id $1 $method $usdc_id $2 \
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
