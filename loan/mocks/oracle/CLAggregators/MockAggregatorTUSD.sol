pragma solidity ^0.5.10;

import "./MockAggregatorBase.sol";

contract MockAggregatorTUSD is MockAggregatorBase {
    constructor (int256 _initialAnswer) public MockAggregatorBase(_initialAnswer) {}
}