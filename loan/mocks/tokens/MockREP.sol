pragma solidity ^0.5.10;


import "./MintableERC20.sol";


contract MockREP is MintableERC20 {

    uint256 public decimals = 18;
    string public symbol = "REP";
    string public name = "Augur";
}