// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {UniswapV2FlashSwap} from "../../src/UniswapV2FlashSwap.sol";
import {UNISWAP_V2_PAIR_DAI_WETH} from "../../src/Constants.sol";

contract UniswapV2FlashSwapTest is Test {
    UniswapV2FlashSwap flashSwap;

    address swapCaller = makeAddr("swap-caller");

    function setUp() public {
        flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);
    }

    function test_uniswapV2FlashSwap(uint256 amount) public {
        address token0 = flashSwap.pair().token0();
        address token1 = flashSwap.pair().token1();
        (uint112 reserve0, uint112 reserve1,) = flashSwap.pair().getReserves();

        // vm.assume(token == token0 || token == token1);
        address token = amount % 2 == 0 ? token0 : token1;

        uint256 reserve = token == token0 ? reserve0 : reserve1;
        amount = bound(amount, 0, reserve / 2);

        deal(token, swapCaller, amount * 2);

        vm.startPrank(swapCaller);
        IERC20(token).approve(address(flashSwap), type(uint256).max);
        flashSwap.execute(token, amount);
        vm.stopPrank();
    }
}
