// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "v2-periphery/interfaces/IWETH.sol";

import {WETH, DAI, MKR, UNISWAP_V2_ROUTER_02} from "../src/Constants.sol";

contract Playground is Test {
    IWETH weth = IWETH(WETH);
    IERC20 dai = IERC20(DAI);
    IERC20 mkr = IERC20(MKR);

    IUniswapV2Router02 routerV2 = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    function test_getAmountsOut() public view {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1 ether;
        uint256[] memory amounts = routerV2.getAmountsOut(amountIn, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }

    function test_getAmountsIn() public view {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 5e17;
        uint256[] memory amounts = routerV2.getAmountsIn(amountOut, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }
}