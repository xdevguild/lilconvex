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

- You also have the possibility to exit all your positions in a single transaction by calling `exitAllPosition` function. You will receive all the liquidity deposited & ASH rewards in your wallet.

## Thoughts

This work has been done in the context of the [Ashswap Battle of Yields](https://battleofyields.ashswap.io/?address=erd1yq2v0rpt5h2lfa8ljkgu6mchrjvy6en3ywe2wfnnjun2rs4qu8nqalcfe5&signature=5d0d8996611143ff82734dc9d829429f769fd4e2780bf82b078f0e888db5289d899e2783cf064527f96fb164cd3efefa10909d3a53e8d34ae5e21db57fd2e60a) in order to build on top of their smart contracts. It has been designed for a single user that deposits all his assets in a Compound contract, in order to create a single Compound contract that can be used by several users you will need to add a token to track the percentage of the liquidity each user has in the Compound contract.

This type of treasury management has NOT been done in this repo for now. I do NOT recommend to use my work in production.

Moreover, although the workflow is done, I will update the smart contract in order to pass way more less arguments in the snippets, the token identifiers and smart contracts addresses will be stored in storage mappers when deploying the contract in the future.

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
