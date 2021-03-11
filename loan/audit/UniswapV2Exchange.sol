pragma solidity ^0.5.10;
import "../coin/itrx.sol";
import "../lib/std.sol";

interface IUniswapV2Exchange {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

library UniswapV2ExchangeLib {
    using SafeMath for uint256;
    using UniversalERC20 for ITRC20;

    function getReturn(
        IUniswapV2Exchange exchange,
        ITRC20 fromToken,
        ITRC20 destToken,
        uint amountIn
    ) internal view returns (uint256) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        return (denominator == 0) ? 0 : numerator.div(denominator);
    }
}
