// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ConfigurableConstantOracle is BaseOracle {
    struct ConfigParams {
        address base;
        address quote;
        uint256 rate;
    }

    uint256 public constant PRECISION = 10 ** 27;
    mapping(address base => mapping(address quote => uint256 rate)) public configs;

    constructor(ConfigParams[] memory _initialConfigs) {
        uint256 length = _initialConfigs.length;
        for (uint256 i = 0; i < length;) {
            _setConfig(_initialConfigs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ConfigurableConstantOracle();
    }

    function _setConfig(ConfigParams memory params) internal {
        configs[params.base][params.quote] = params.rate;
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        uint256 rate = configs[base][quote];
        if (rate == 0) revert Errors.EOracle_NotSupported(base, quote);
        return inAmount * rate / PRECISION;
    }
}
