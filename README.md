# lilconvex

This project aims to provide a compound contract for Ashswap.

:construction: WORK IN PROGRESS :construction:

# Main Functionalities

- You can add liquidity to the pool you are interested in and enter farm in the same transaction by calling `addLiquidityAndEnterFarm` function.

- You can compound your ASH rewards in the USDC/USDT pool by calling `compound` function.
- You can compound your ASH rewards in the USDC/WUSDC pool by calling `compoundUsdcWusdc` function.
- You can compound your ASH rewards in the renBTC/WBTC pool by calling `compoundBtc` function.
- You can compound the 3 pools in a single transaction by calling the `compoundAll` function.

- Withdraw from a specific farm and retrieve your liquidity by also quitting the liquidity pool in the same transaction by calling `exitPosition` function with the right arguments. This function retrieve your tokens by swapping the farm tokens into LP tokens & ASH and then swapping the LP tokens for liquidty. The liquidity and ASH tokens are then sent from the Compound smart contract to your wallet.

## Schemas

Schema of the `addLiquidityAndEnterFarm` workflow.

![alt text](https://github.com/yum0e/lilconvex/blob/main/images/addLiquidityAndEnterFarm.png?raw=true)

Schema of the `compound` workflow.

> This workflow is specific to the USDC/USDT pool. It is a bit more complicated for the other pools (more swaps 😎)

![alt text](https://github.com/yum0e/lilconvex/blob/main/images/compound2.png?raw=true)

## How to autocompound

Deploy the contract, call the function addLiquidityAndEnterFarm in order to deposit in all the pools you want.
You can then go to the `workflow.cjs` to execute the cron, you can choose the period between two auto-compound. You can choose to focus on one farm
Check [https://crontab.guru/](https://crontab.guru/) for cron syntax.
