// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "v2-periphery/interfaces/IWETH.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {UniswapV2Arbitrage2} from "../../src/UniswapV2Arbitrage2.sol";
import {
    WETH,
    DAI,
    MKR,
    UNISWAP_V2_PAIR_DAI_MKR,
    UNISWAP_V2_PAIR_DAI_WETH,
    SUSHISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_FACTORY,
    SUSHISWAP_V2_FACTORY,
    UNISWAP_V2_ROUTER_02,
    SUSHISWAP_V2_ROUTER_02
} from "../../src/Constants.sol";

contract UniswapV2Arbitrage2Test is Test {
    IWETH weth = IWETH(WETH);
    IERC20 dai = IERC20(DAI);

    address whale = makeAddr("whale");
    address user = makeAddr("user");

    uint256 INITIAL_ETH_BALANCE = 1000 ether;
    uint256 INITIAL_TOKEN_BALANCE = 3e6 * 1e18;

    UniswapV2Arbitrage2 arb;

    function setUp() public {
        arb = new UniswapV2Arbitrage2();

        deal(whale, INITIAL_ETH_BALANCE * 10);
        deal(WETH, whale, INITIAL_ETH_BALANCE * 10);
        deal(DAI, whale, INITIAL_TOKEN_BALANCE * 10);
    }

    modifier dealEth() {
        deal(user, INITIAL_ETH_BALANCE);
        _;
    }

    modifier dealWeth() {
        deal(user, INITIAL_ETH_BALANCE);

        vm.startPrank(user);
        weth.deposit{value: INITIAL_ETH_BALANCE}();
        IERC20(WETH).approve(UNISWAP_V2_ROUTER_02, type(uint256).max);
        IERC20(WETH).approve(SUSHISWAP_V2_ROUTER_02, type(uint256).max);
        vm.stopPrank();

        _;
    }

    modifier dealToken(address token) {
        deal(token, user, INITIAL_TOKEN_BALANCE, true);

        vm.prank(user);
        IERC20(token).approve(UNISWAP_V2_ROUTER_02, type(uint256).max);
        IERC20(token).approve(SUSHISWAP_V2_ROUTER_02, type(uint256).max);

        _;
    }

    modifier reduceUniswapWethPrice() {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        IUniswapV2Pair pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 amountIn = (pair.token0() == path[0] ? reserve0 : reserve1) / 5;
        uint256 amountOutMin = 0;

        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

        console.log("Swapping", amountIn, "WETH for DAI");
        console.log("Price before swapping", router.quote(1, reserve1, reserve0));

        vm.startPrank(whale);
        IERC20(WETH).approve(address(router), type(uint256).max);
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, whale, block.timestamp);
        vm.stopPrank();

        (uint112 reserve0New, uint112 reserve1New,) = pair.getReserves();

        console.log("Price after swapping", router.quote(1, reserve1New, reserve0New));

        _;
    }

    function test_flashArbitrage2UniswapToSushiswap() public reduceUniswapWethPrice {
        uint256 amountIn = 1000e18;

        vm.prank(user);
        arb.flashSwap({
            pair0: UNISWAP_V2_PAIR_DAI_WETH,
            pair1: SUSHISWAP_V2_PAIR_DAI_WETH,
            isZeroForOne: true,
            amountIn: amountIn,
            minProfit: amountIn / 100
        });

        console.log("profit", dai.balanceOf(user));
    }
}
