// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IWETH} from "v2-periphery/interfaces/IWETH.sol";

import {WETH, DAI, MKR, UNISWAP_V2_FACTORY} from "../../src/Constants.sol";

contract FactoryPlayground is Test {
    IWETH weth = IWETH(WETH);
    MockERC20 token;

    IUniswapV2Factory factoryV2 = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    modifier createNewToken() {
        token = new MockERC20();
        token.initialize("New Token", "NTN", 18);

        _;
    }

    function test_createPair() public createNewToken {
        (address token0, address token1) = WETH < address(token) ? (WETH, address(token)) : (address(token), WETH);

        address pair = factoryV2.createPair(token0, token1);

        assertEq(IUniswapV2Pair(pair).token0(), token0);
        assertEq(IUniswapV2Pair(pair).token1(), token1);

        console.log("Token 0", token0);
        console.log("Token 1", token1);
        console.log("Pair", pair);
    }
}
