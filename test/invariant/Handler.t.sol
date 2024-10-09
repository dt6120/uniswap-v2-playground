// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {UniswapV2FlashSwap} from "../../src/UniswapV2FlashSwap.sol";

contract Handler is Test {
    UniswapV2FlashSwap flashSwap;

    address swapCaller = makeAddr("swap-caller");

    constructor(UniswapV2FlashSwap _flashSwap) {
        flashSwap = _flashSwap;
    }

    function uniswapV2FlashSwap(address token, uint256 amount) public {
        address token0 = flashSwap.pair().token0();
        address token1 = flashSwap.pair().token1();
        (uint112 reserve0, uint112 reserve1,) = flashSwap.pair().getReserves();

        vm.assume(token == token0 || token == token1);

        uint256 reserve = token == token0 ? reserve0 : reserve1;
        amount = bound(amount, 0, reserve / 2);

        deal(token, swapCaller, amount * 2);

        vm.startPrank(swapCaller);
        IERC20(token).approve(address(flashSwap), type(uint256).max);
        flashSwap.execute(token, amount);
        vm.stopPrank();
    }
}
