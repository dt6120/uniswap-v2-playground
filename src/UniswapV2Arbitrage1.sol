// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract UniswapV2Arbitrage1 {
    error UniswapV2Arbitrage1__InvalidCaller();
    error UniswapV2Arbitrage1__ProfitLessThanMin(uint256 profit);

    struct SwapParams {
        address router0;
        address router1;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minProfit;
    }

    function swap(SwapParams calldata params) external returns (uint256 profit) {
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountOut = _swap(params);

        IERC20(params.tokenIn).transfer(msg.sender, amountOut);

        profit = amountOut - params.amountIn;
    }

    function flashSwap(address _pair, SwapParams calldata params) external {
        bytes memory data = abi.encode(msg.sender, _pair, params);

        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        uint256 amount0Out = params.tokenIn == pair.token0() ? params.amountIn : 0;
        uint256 amount1Out = params.tokenIn == pair.token1() ? params.amountIn : 0;

        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256, uint256, bytes calldata data) external {
        if (sender != address(this)) {
            revert UniswapV2Arbitrage1__InvalidCaller();
        }

        (address swapCaller, address pair, SwapParams memory params) = abi.decode(data, (address, address, SwapParams));

        uint256 amountOut = _swap(params);

        uint256 swapFee = (params.amountIn * 3) / 997 + 1;
        uint256 amountToRepay = params.amountIn + swapFee;
        uint256 profit = amountOut - amountToRepay;

        if (profit < params.minProfit) {
            revert UniswapV2Arbitrage1__ProfitLessThanMin(profit);
        }

        IERC20(params.tokenIn).transfer(pair, amountToRepay);
        IERC20(params.tokenIn).transfer(swapCaller, profit);
    }

    function _swap(SwapParams memory params) private returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;

        IERC20(params.tokenIn).approve(params.router0, params.amountIn);
        uint256[] memory amounts = IUniswapV2Router02(params.router0).swapExactTokensForTokens(
            params.amountIn, 0, path, address(this), block.timestamp
        );

        amountOut = amounts[1];
        uint256 amountOutMin = params.amountIn + params.minProfit;

        path[0] = params.tokenOut;
        path[1] = params.tokenIn;

        IERC20(params.tokenOut).approve(params.router1, amountOut);
        amounts = IUniswapV2Router02(params.router1).swapExactTokensForTokens(
            amountOut, amountOutMin, path, address(this), block.timestamp
        );

        amountOut = amounts[1];
    }
}
