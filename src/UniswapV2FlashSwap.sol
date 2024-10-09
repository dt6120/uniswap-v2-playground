// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV2FlashSwap {
    error UniswapV2FlashSwap__InvalidToken();
    error UniswapV2FlashSwap__InvalidCaller();

    IUniswapV2Pair public immutable pair;

    event FlashSwapExecuted(uint256 amountBorrowed, uint256 swapFee);

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
    }

    function execute(address token, uint256 amount) external {
        address token0 = pair.token0();
        address token1 = pair.token1();

        if (token != token0 && token != token1) {
            revert UniswapV2FlashSwap__InvalidToken();
        }

        uint256 amount0Out = token == token0 ? amount : 0;
        uint256 amount1Out = token == token1 ? amount : 0;

        bytes memory data = abi.encode(msg.sender, token);

        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        if (sender != address(this)) {
            revert UniswapV2FlashSwap__InvalidCaller();
        }

        (address swapCaller, address token) = abi.decode(data, (address, address));

        uint256 amountBorrowed = amount0 != 0 ? amount0 : amount1;
        uint256 swapFee = (3 * amountBorrowed) / 997 + 1;
        uint256 amountToRepay = amountBorrowed + swapFee;

        emit FlashSwapExecuted(amountBorrowed, swapFee);

        SafeERC20.safeTransferFrom(IERC20(token), swapCaller, address(pair), amountToRepay);
    }
}
