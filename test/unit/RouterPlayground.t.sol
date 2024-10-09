// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "v2-periphery/interfaces/IWETH.sol";

import {WETH, DAI, MKR, UNISWAP_V2_PAIR_DAI_WETH, UNISWAP_V2_ROUTER_02} from "../../src/Constants.sol";

contract RouterPlayground is Test {
    IWETH weth = IWETH(WETH);
    IERC20 dai = IERC20(DAI);
    IERC20 mkr = IERC20(MKR);

    IUniswapV2Router02 routerV2 = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair wethDaiPair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);

    address user = makeAddr("user");

    uint256 INITIAL_ETH_BALANCE = 10 ether;
    uint256 INITIAL_TOKEN_BALANCE = 10000e18;

    modifier dealEth() {
        deal(user, INITIAL_ETH_BALANCE);
        _;
    }

    modifier dealWeth() {
        deal(user, INITIAL_ETH_BALANCE);

        vm.startPrank(user);
        weth.deposit{value: INITIAL_ETH_BALANCE}();
        IERC20(WETH).approve(UNISWAP_V2_ROUTER_02, type(uint256).max);
        vm.stopPrank();

        _;
    }

    modifier dealToken(address token) {
        deal(token, user, INITIAL_TOKEN_BALANCE, true);

        vm.prank(user);
        IERC20(token).approve(UNISWAP_V2_ROUTER_02, type(uint256).max);

        _;
    }

    modifier addLiquidity(address token) {
        deal(user, INITIAL_ETH_BALANCE);
        deal(token, user, INITIAL_TOKEN_BALANCE);

        vm.startPrank(user);
        IERC20(token).approve(UNISWAP_V2_ROUTER_02, type(uint256).max);
        (uint256 amountA, uint256 amountB,) = routerV2.addLiquidityETH{value: 1 ether}({
            token: token,
            amountTokenDesired: 3000e18,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: user,
            deadline: block.timestamp
        });
        vm.stopPrank();

        console.log("DAI added", amountA);
        console.log("WETH added", amountB);

        _;
    }

    function test_getAmountsOut() public view {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1 ether;
        uint256[] memory amounts = routerV2.getAmountsOut(amountIn, path);

        assertEq(amountIn, amounts[0]);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_getAmountsIn() public view {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 5e17;
        uint256[] memory amounts = routerV2.getAmountsIn(amountOut, path);

        assertEq(amountOut, amounts[2]);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_swapExactTokensForTokens() public dealWeth {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = INITIAL_ETH_BALANCE;
        uint256 amountOutMin = 1e17;

        vm.prank(user);
        uint256[] memory amounts =
            routerV2.swapExactTokensForTokens(amountIn, amountOutMin, path, user, block.timestamp + 60);

        assertEq(amountIn, amounts[0]);
        assertEq(IERC20(WETH).balanceOf(user), 0);
        assertGe(mkr.balanceOf(user), amountOutMin);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_swapExactEthForTokens() public dealEth {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = INITIAL_ETH_BALANCE;
        uint256 amountOutMin = 1e17;

        vm.prank(user);
        uint256[] memory amounts =
            routerV2.swapExactETHForTokens{value: amountIn}(amountOutMin, path, user, block.timestamp);

        assertEq(amountIn, amounts[0]);
        assertEq(user.balance, 0);
        assertGe(mkr.balanceOf(user), amountOutMin);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_swapTokensForExactTokens() public dealWeth {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 1e17;
        uint256 amountInMax = INITIAL_ETH_BALANCE;

        vm.prank(user);
        uint256[] memory amounts =
            routerV2.swapTokensForExactTokens(amountOut, amountInMax, path, user, block.timestamp);

        assertEq(amountOut, amounts[2]);
        assertEq(mkr.balanceOf(user), amountOut);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_addLiquidity() public dealWeth dealToken(DAI) {
        uint256 startingWethBalance = IERC20(WETH).balanceOf(user);
        uint256 startingDaiBalance = dai.balanceOf(user);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = routerV2.addLiquidity({
            tokenA: WETH,
            tokenB: DAI,
            amountADesired: 1 ether,
            amountBDesired: 3000e18,
            amountAMin: 0,
            amountBMin: 0,
            to: user,
            deadline: block.timestamp
        });

        uint256 endingWethBalance = IERC20(WETH).balanceOf(user);
        uint256 endingDaiBalance = dai.balanceOf(user);

        assertEq(wethDaiPair.balanceOf(user), liquidity);
        assertEq(startingWethBalance - endingWethBalance, amountA);
        assertEq(startingDaiBalance - endingDaiBalance, amountB);

        console.log("WETH added", amountA);
        console.log("DAI added", amountB);
        console.log("LP shares minted", liquidity);
    }

    function test_addLiquidityEth() public dealEth dealToken(DAI) {
        uint256 startingEthBalance = user.balance;
        uint256 startingDaiBalance = dai.balanceOf(user);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = routerV2.addLiquidityETH{value: 1 ether}({
            token: DAI,
            amountTokenDesired: 3000e18,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: user,
            deadline: block.timestamp
        });

        uint256 endingEthBalance = user.balance;
        uint256 endingDaiBalance = dai.balanceOf(user);

        assertEq(wethDaiPair.balanceOf(user), liquidity);
        assertEq(startingDaiBalance - endingDaiBalance, amountA);
        assertEq(startingEthBalance - endingEthBalance, amountB);

        console.log("WETH added", amountA);
        console.log("DAI added", amountB);
        console.log("LP shares minted", liquidity);
    }

    function test_removeLiquidity() public addLiquidity(DAI) {
        uint256 startingWethBalance = IERC20(WETH).balanceOf(user);
        uint256 startingDaiBalance = dai.balanceOf(user);
        uint256 liquidity = wethDaiPair.balanceOf(user);

        vm.startPrank(user);
        wethDaiPair.approve(UNISWAP_V2_ROUTER_02, type(uint256).max);

        (uint256 amountA, uint256 amountB) = routerV2.removeLiquidity({
            tokenA: DAI,
            tokenB: WETH,
            liquidity: liquidity,
            amountAMin: 0,
            amountBMin: 0,
            to: user,
            deadline: block.timestamp
        });
        vm.stopPrank();

        uint256 endingWethBalance = IERC20(WETH).balanceOf(user);
        uint256 endingDaiBalance = dai.balanceOf(user);

        assertEq(wethDaiPair.balanceOf(user), 0);
        assertEq(endingDaiBalance - startingDaiBalance, amountA);
        assertEq(endingWethBalance - startingWethBalance, amountB);

        console.log("DAI returned", amountA);
        console.log("WETH returned", amountB);
    }

    function test_removeLiquidityEth() public addLiquidity(DAI) {
        uint256 startingEthBalance = user.balance;
        uint256 startingDaiBalance = dai.balanceOf(user);
        uint256 liquidity = wethDaiPair.balanceOf(user);

        vm.startPrank(user);
        wethDaiPair.approve(UNISWAP_V2_ROUTER_02, type(uint256).max);

        (uint256 amountA, uint256 amountB) = routerV2.removeLiquidityETH({
            token: DAI,
            liquidity: liquidity,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: user,
            deadline: block.timestamp
        });
        vm.stopPrank();

        uint256 endingEthBalance = user.balance;
        uint256 endingDaiBalance = dai.balanceOf(user);

        assertEq(wethDaiPair.balanceOf(user), 0);
        assertEq(endingDaiBalance - startingDaiBalance, amountA);
        assertEq(endingEthBalance - startingEthBalance, amountB);

        console.log("DAI returned", amountA);
        console.log("ETH returned", amountB);
    }
}
