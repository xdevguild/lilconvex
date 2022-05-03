# lilconvex

This project aims to provide a compound contract for Ashswap.

:construction: WORK IN PROGRESS :construction:

# Functionalities

- You can compound your ASH rewards in the USDC/USDT pool or USDC/WUSDC in a single transaction.
- Will add compound for renBTC/WBTC pool.
- You can addLiquidity on any pair and enter the farm in the same transaction for ease of use.

## How to autocompound

Deploy the contract, call the function addLiquidityAndEnterFarm in order to deposit USDC and USDT to the USDC/USDT pool.
You can then go to the `workflow.cjs` to execute the cron, you can choose the period between two auto-compound.
Check [https://crontab.guru/](https://crontab.guru/) for cron syntax.

