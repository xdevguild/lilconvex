WALLET_PEM="~/Elrond/pems/yum0e1.pem"
MY_ADDRESS="erd1r5x47cf3mazmpxed9u237sk97a6jm059mna2y7s53zp705khtdks57t3lu"

PROXY="https://testnet-gateway.elrond.com"
CHAIN="T"
ADDRESS=$(erdpy data load --key=address-testnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-testnet)

BYTECODE="./output/pool.wasm"

GOV_ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta"
SWAP_ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqaphkarlvclh2c3v0hq2em73gcuxkh5yxj9ts6s5dt2" # USDC / USDT
FARM_ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqrn64ujp5m8c6l2k58v7qgtn8f48u6d29j9ts27qugg" # for LPUSDCUSDT

gov_sc_address="0x$(erdpy wallet bech32 --decode ${GOV_ASHSWAP_SC})"
swap_sc_address="0x$(erdpy wallet bech32 --decode ${SWAP_ASHSWAP_SC})"
farm_sc_address="0x$(erdpy wallet bech32 --decode ${FARM_ASHSWAP_SC})"

deploy() {

    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=400000000 \
    --arguments $gov_sc_address $swap_sc_address $farm_sc_address \
    --send \
    --outfile="deploy-testnet.interaction.json" || return

    TRANSACTION=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-testnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-testnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    erdpy --verbose contract upgrade ${ADDRESS} --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=400000000 \
    --arguments $gov_sc_address $swap_sc_address $farm_sc_address \
    --outfile="deploy-testnet.interaction.json" \
    --send || return
}

# source interaction/testnet.snippets.sh && addLiquidityAndEnterFarm 1000000 10000000 
addLiquidityAndEnterFarm() {
    # add_liquidity to USDC/USDT pool and enterFarm with LPT-89ce1b

    # $1 first_token_amount_min
    # $2 second_token_amount_min
    # $3 lp_token amount to enterFarm

    first_token_id="0x$(echo -n 'USDC-780dd8' | xxd -p -u | tr -d '\n')"
    second_token_id="0x$(echo -n 'USDT-7d8186' | xxd -p -u | tr -d '\n')"
    # lp_token_id="0x$(echo -n 'LPT-89ce1b' | xxd -p -u | tr -d '\n')"
    method="0x$(echo -n 'addLiquidityAndEnterFarm' | xxd -p -u | tr -d '\n')"

    addr="0x$(erdpy wallet bech32 --decode ${ADDRESS})"
    sc="0x$(erdpy wallet bech32 --decode erd1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq6gq4hu)"

    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="MultiESDTNFTTransfer" \
    --arguments ${addr} 02 ${first_token_id} 00 $1 ${second_token_id} 00 $2 ${method} ${sc} \
    --send || return
}

claimRewardsInContract() {

    # $1 amount of LP token to send to the contract

    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=200000000 \
    --function="claimRewardsInContract" \
    --arguments $1 \
    --send || return
}

exchange1() {
    # exchange USDC to USDT
    # $1 amount to exchange
    token_to_pay_with="0x$(echo -n 'USDC-780dd8' | xxd -p -u | tr -d '\n')"
    method="0x$(echo -n 'exchange' | xxd -p -u | tr -d '\n')"
    token_to_receive="0x$(echo -n 'USDT-7d8186' | xxd -p -u | tr -d '\n')"

    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=600000000 \
        --proxy=${PROXY} --chain=${CHAIN} \
        --function="ESDTTransfer" \
        --arguments $token_to_pay_with $1 $method $token_to_receive 0 \
        --send || return
}

exchange2() {
    # exchange USDT to USDC
    # $1 amount to exchange
    token_to_pay_with="0x$(echo -n 'USDT-7d8186' | xxd -p -u | tr -d '\n')"
    method="0x$(echo -n 'exchange' | xxd -p -u | tr -d '\n')"
    token_to_receive="0x$(echo -n 'USDC-780dd8' | xxd -p -u | tr -d '\n')"

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
