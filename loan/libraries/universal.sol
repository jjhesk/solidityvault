pragma solidity ^0.5.10;

import "./std.sol";
import "../coin/itrc20.sol";

library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for ITRC20;

    ITRC20 private constant ZERO_ADDRESS = ITRC20("TR0T000000000000000000000000000000");
    ITRC20 private constant USDT_ADDRESS = ITRC20("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t");

    function universalTransfer(ITRC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }
        if (isUSDT(token)) {
            address(uint160(to)).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(ITRC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isUSDT(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(ITRC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isUSDT(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(ITRC20 token, address to, uint256 amount) internal {
        if (!isUSDT(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(ITRC20 token, address who) internal view returns (uint256) {
        if (isUSDT(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(ITRC20 token) internal view returns (uint256) {

        if (isUSDT(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(10000)(
            abi.encodeWithSignature("decimals()")
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall.gas(10000)(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isUSDT(ITRC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(USDT_ADDRESS));
    }

    function notExist(ITRC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}
