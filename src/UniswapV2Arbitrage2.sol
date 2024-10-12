// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract UniswapV2Arbitrage2 {
    error UniswapV2Arbitrage2__InvalidCaller();
    error UniswapV2Arbitrage2__ProfitLessThanMin(uint256 profit);

    struct FlashSwapParams {
        address swapCaller;
        address pair0;
        address pair1;
        bool isZeroForOne;
        uint256 amountIn;
        uint256 amountOut;
        uint256 minProfit;
    }

    function flashSwap(address pair0, address pair1, bool isZeroForOne, uint256 amountIn, uint256 minProfit) external {
        IUniswapV2Pair pair = IUniswapV2Pair(pair0);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 amountOut =
            isZeroForOne ? getAmountOut(amountIn, reserve0, reserve1) : getAmountOut(amountIn, reserve1, reserve0);
        uint256 amount0Out = isZeroForOne ? 0 : amountOut;
        uint256 amount1Out = isZeroForOne ? amountOut : 0;
        bytes memory data = abi.encode(
            FlashSwapParams({
                swapCaller: msg.sender,
                pair0: pair0,
                pair1: pair1,
                isZeroForOne: isZeroForOne,
                amountIn: amountIn,
                amountOut: amountOut,
                minProfit: minProfit
            })
        );

        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256, uint256, bytes calldata data) external {
        if (sender != address(this)) {
            revert UniswapV2Arbitrage2__InvalidCaller();
        }

        FlashSwapParams memory params = abi.decode(data, (FlashSwapParams));

        address token0 = IUniswapV2Pair(params.pair0).token0();
        address token1 = IUniswapV2Pair(params.pair0).token1();
        (address tokenIn, address tokenOut) = params.isZeroForOne ? (token0, token1) : (token1, token0);

        IERC20(tokenOut).transfer(params.pair1, params.amountOut);
        IUniswapV2Pair pair = IUniswapV2Pair(params.pair1);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 amountOut = params.isZeroForOne
            ? getAmountOut(params.amountOut, reserve1, reserve0)
            : getAmountOut(params.amountOut, reserve0, reserve1);

        uint256 amount0Out = params.isZeroForOne ? amountOut : 0;
        uint256 amount1Out = params.isZeroForOne ? 0 : amountOut;

        pair.swap(amount0Out, amount1Out, address(this), "");

        IERC20(tokenIn).transfer(params.pair0, params.amountIn);

        uint256 profit = amountOut - params.amountIn;

        if (profit < params.minProfit) {
            revert UniswapV2Arbitrage2__ProfitLessThanMin(profit);
        }
        IERC20(tokenIn).transfer(params.swapCaller, profit);
    }

    function getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut)
        private
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
