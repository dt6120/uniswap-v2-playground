# Uniswap V2 Playground

This is a Foundry project developed to play around with Uniswap V2 protocol. It has contracts that implement flash swap and arbitrage functionality using the pair and router contracts. There are various unit and fuzz tests written to run features like swapping tokens, adding removing liquidity to more advanced setups for flash swaps and arbitrage.

### Getting started
- Clone the repo
```bash
git clone https://github.com/dt6120/uniswap-v2-playground.git
```
- Install dependencies and compile contracts
```bash
forge build
```
- Export Ethereum mainnet RPC url
```bash
export ETH_RPC="<ETH_RPC_URL_HERE>"
```

### Running the test suite
- Run forge test command with fork url
```bash
forge test --fork-url $ETH_RPC -vvv
```
