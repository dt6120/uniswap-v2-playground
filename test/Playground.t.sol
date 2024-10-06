// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "v2-periphery/interfaces/IWETH.sol";

import {WETH, DAI, MKR, UNISWAP_V2_ROUTER_02} from "../src/Constants.sol";

contract Playground is Test {
    IWETH weth = IWETH(WETH);
    IERC20 dai = IERC20(DAI);
    IERC20 mkr = IERC20(MKR);

    IUniswapV2Router02 routerV2 = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    address swapper = makeAddr("swapper");
    uint256 INITIAL_ETH_BALANCE = 10 ether;

    modifier dealEth() {
        deal(swapper, INITIAL_ETH_BALANCE);
        _;
    }

    modifier dealWeth() {
        deal(swapper, INITIAL_ETH_BALANCE);

        vm.startPrank(swapper);
        weth.deposit{value: INITIAL_ETH_BALANCE}();
        IERC20(WETH).approve(address(UNISWAP_V2_ROUTER_02), type(uint256).max);
        vm.stopPrank();

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

        vm.prank(swapper);
        uint256[] memory amounts =
            routerV2.swapExactTokensForTokens(amountIn, amountOutMin, path, swapper, block.timestamp + 60);

        assertEq(amountIn, amounts[0]);
        assertEq(IERC20(WETH).balanceOf(swapper), 0);
        assertGe(mkr.balanceOf(swapper), amountOutMin);

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

        vm.prank(swapper);
        uint256[] memory amounts =
            routerV2.swapExactETHForTokens{value: amountIn}(amountOutMin, path, swapper, block.timestamp);

        assertEq(amountIn, amounts[0]);
        assertEq(swapper.balance, 0);
        assertGe(mkr.balanceOf(swapper), amountOutMin);

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

        vm.prank(swapper);
        uint256[] memory amounts =
            routerV2.swapTokensForExactTokens(amountOut, amountInMax, path, swapper, block.timestamp);

        assertEq(amountOut, amounts[2]);
        assertEq(mkr.balanceOf(swapper), amountOut);

        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }
}
