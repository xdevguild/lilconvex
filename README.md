# lilconvex

This project aims to provide a compound contract for Ashswap.

:construction: WORK IN PROGRESS :construction:

# Main Functionalities

- You can add liquidity to the pool you are interested in and enter farm in the same transaction by calling `addLiquidityAndEnterFarm` function.
- You can compound your ASH rewards in the USDC/USDT pool by calling `compound` function.
- You can compound your ASH rewards in the USDC/WUSDC pool by calling `compoundUsdcWusdc` function.
- You can compound your ASH rewards in the renBTC/WBTC pool by calling `compoundBtc` function.
- You can compound the 3 pools in a single transaction by calling the fucntion `compoundAll` function.

Additional future functionalities:

- Withdraw from a specific farm and retrieve your liquidity by also quitting the liquidity pool in the same transaction.

## Schemas

Schema of the `addLiquidityAndEnterFarm` workflow.

![alt text](https://github.com/yum0e/lilconvex/tree/main/images/addLiquidityAndEnterFarm.png?raw=true)

Schema of the `compound` workflow.

> to be added.

## How to autocompound

Deploy the contract, call the function addLiquidityAndEnterFarm in order to deposit in all the pools you want.
You can then go to the `workflow.cjs` to execute the cron, you can choose the period between two auto-compound. You can choose to focus on one farm
Check [https://crontab.guru/](https://crontab.guru/) for cron syntax.
