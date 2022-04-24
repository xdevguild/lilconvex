WALLET_PEM="~/Elrond/pems/yum0e1.pem"
MY_ADDRESS="erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5"

PROXY="https://testnet-gateway.elrond.com"
CHAIN="T"
ADDRESS=$(erdpy data load --key=address-testnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-testnet)

BYTECODE="./pool/output/pool.wasm"

ASHSWAP_SC="erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta"

deploy() {

    sc_address="0x$(erdpy wallet bech32 --decode ${ASHSWAP_SC})"
    erd1qqqqqqqqqqqqqpgqvrc0x026cf44kktc7jhw6mgtpu9d5cw2j9tsfxnjta
    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=20000000 \
    --arguments $sc_address \
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
    --gas-limit=20000000 \
    --outfile="deploy-testnet.interaction.json" \
    --send || return
}

increaseAmount() {

    token_id="$(echo -n 'ASH-76f082' | xxd -p -u | tr -d '\n')"
    method="$(echo -n 'increase_amount' | xxd -p -u | tr -d '\n')"

    erdpy --verbose tx new --receiver=${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --data="ESDTTransfer@${token_id}@$1@${method}" \
    --send
}

