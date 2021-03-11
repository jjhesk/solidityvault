pragma solidity ^0.5.10;

import "./trc20.sol";

contract IWETH is ITRC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

