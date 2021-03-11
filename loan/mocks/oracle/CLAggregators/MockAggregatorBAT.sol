pragma solidity ^0.5.10;

import "./MockAggregatorBase.sol";

contract MockAggregatorBAT is MockAggregatorBase {
    constructor (int256 _initialAnswer) public MockAggregatorBase(_initialAnswer) {}
}