/**
 *Submitted for verification at Etherscan.io on 2020-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.15;
import "../trccoin/itrc20.sol";
import "../libraries/std.sol";

interface Strategy {
    function want() external view returns (address);

    function deposit() external;

    function withdraw(address) external;

    function withdraw(uint) external;

    function withdrawAll() external returns (uint);

    function balanceOf() external view returns (uint);
}

interface Converter {
    function convert(address) external returns (uint);
}

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
    external payable returns (uint256 returnAmount);
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
    external view returns (
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

contract Controller {
    using SafeERC20 for ITRC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public onesplit;
    address public rewards;
    address public factory;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;

    uint public split = 5000;
    uint public constant max = 10000;

    constructor() public {
        governance = tx.origin;
        onesplit = address(T0NEPSLIT0000000000000000000000000);
        rewards = address(TXYYtJ9WA7rA9ZFE98V1s8AmbSXM6x84Rn);
    }

    function setFactory(address _factory) public {
        require(msg.sender == governance, "!governance");
        factory = _factory;
    }

    function setSplit(uint _split) public {
        require(msg.sender == governance, "!governance");
        split = _split;
    }

    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVault(address _token, address _vault) public {
        require(msg.sender == governance, "!governance");
        vaults[_token] = _vault;
    }

    function setConverter(address _input, address _output, address _converter) public {
        require(msg.sender == governance, "!governance");
        converters[_input][_output] = _converter;
    }

    function setStrategy(address _token, address _strategy) public {
        //某个币对应一个策略,比如现在的ycrv就是挖 yfii
        require(msg.sender == governance, "!governance");
        address _current = strategies[_token];
        if (_current != address(0)) {//之前的策略存在的话,那么就先提取所有资金
            Strategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    function earn(address _token, uint _amount) public {
        address _strategy = strategies[_token];
        //获取策略的合约地址
        address _want = Strategy(_strategy).want();
        //策略需要的token地址
        if (_want != _token) {//如果策略需要的和输入的不一样,需要先转换
            address converter = converters[_token][_want];
            //转换器合约地址.
            ITRC20(_token).safeTransfer(converter, _amount);
            //给转换器打钱
            _amount = Converter(converter).convert(_strategy);
            //执行转换...
            ITRC20(_want).safeTransfer(_strategy, _amount);
        } else {
            ITRC20(_token).safeTransfer(_strategy, _amount);
        }
        Strategy(_strategy).deposit();
        //存钱
    }

    function balanceOf(address _token) external view returns (uint) {
        return Strategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(msg.sender == governance, "!governance");
        Strategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint _amount) public {//转任意erc20
        require(msg.sender == governance, "!governance");
        ITRC20(_token).safeTransfer(governance, _amount);
    }

    function getExpectedReturn(address _strategy, address _token, uint parts) public view returns (uint expected) {
        uint _balance = ITRC20(_token).balanceOf(_strategy);
        //获取策略器 某个代币的余额
        address _want = Strategy(_strategy).want();
        //策略器需要的代币.
        (expected,) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function yearn(address _strategy, address _token, uint parts) public {
        // This contract should never have value in it, but just incase since this is a public call
        uint _before = ITRC20(_token).balanceOf(address(this));
        Strategy(_strategy).withdraw(_token);
        uint _after = ITRC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint _amount = _after.sub(_before);
            address _want = Strategy(_strategy).want();
            uint[] memory _distribution;
            uint _expected;
            _before = ITRC20(_want).balanceOf(address(this));
            ITRC20(_token).safeApprove(onesplit, 0);
            ITRC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
            _after = ITRC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint _reward = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_reward));
                ITRC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }

    function withdraw(address _token, uint _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        Strategy(strategies[_token]).withdraw(_amount);
    }
}