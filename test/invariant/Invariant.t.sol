// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {UniswapV2FlashSwap} from "../../src/UniswapV2FlashSwap.sol";
import {Handler} from "./Handler.t.sol";
import {UNISWAP_V2_PAIR_DAI_WETH} from "../../src/Constants.sol";

contract StatefulFuzzer is StdInvariant, Test {
    Handler handler;

    function setUp() public {
        UniswapV2FlashSwap flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);
        handler = new Handler(flashSwap);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Handler.uniswapV2FlashSwap.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function statefulFuzz_uniswapV2FlashSwap() public {
        /**
         * NOTE
         * UniswapV2 inherently checks for invariant fulfillment in its functions.
         * So if the flashswap executes without reverting, it can be said the invariant holds true
         */

        /**
         * NOTE
         * This invariant and handler based test case does not add more value than the existing stateless fuzz test
         * as there is no point of adding depth to the single function call of flash swap.
         * I wrote this just to practice writing stateful fuzz tests with handler based appraoch.
         */
    }
}
