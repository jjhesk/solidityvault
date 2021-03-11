pragma solidity ^0.5.10;

import "../drafts/Strings.sol";

contract StringsMock {
    function fromUint256(uint256 value) public pure returns (string memory) {
        return Strings.fromUint256(value);
    }
}
