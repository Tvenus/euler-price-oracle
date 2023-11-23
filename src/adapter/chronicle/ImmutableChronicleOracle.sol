// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IChronicle} from "@chronicle-std/IChronicle.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutableChronicleOracle is IPriceOracle {
    uint256 public immutable maxStaleness;
    mapping(address base => mapping(address quote => ChronicleConfig)) public configs;

    error AlreadyConfigured(address base, address quote);
    error ArityMismatch(uint256 arityA, uint256 arityB, uint256 arityC);
    error NotConfigured(address base, address quote);
    error PriceTooStale(uint256 staleness, uint256 maxStaleness);

    struct ChronicleConfig {
        address feed;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    constructor(uint256 _maxStaleness, address[] memory bases, address[] memory quotes, address[] memory feeds) {
        maxStaleness = _maxStaleness;

        if (bases.length != quotes.length || quotes.length != feeds.length) {
            revert ArityMismatch(bases.length, quotes.length, feeds.length);
        }

        uint256 length = bases.length;
        for (uint256 i = 0; i < length;) {
            _initConfig(bases[i], quotes[i], feeds[i]);
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

    function _initConfig(address base, address quote, address feed) internal {
        if (configs[base][quote].feed != address(0)) revert AlreadyConfigured(base, quote);

        uint8 baseDecimals = ERC20(base).decimals();
        uint8 quoteDecimals = ERC20(quote).decimals();
        configs[base][quote] =
            ChronicleConfig({feed: feed, baseDecimals: baseDecimals, quoteDecimals: quoteDecimals, inverse: false});

        configs[quote][base] =
            ChronicleConfig({feed: feed, baseDecimals: quoteDecimals, quoteDecimals: baseDecimals, inverse: true});
    }

    function _getOrRevertConfig(address base, address quote) internal view returns (ChronicleConfig memory) {
        ChronicleConfig memory config = configs[base][quote];
        if (config.feed == address(0)) revert NotConfigured(base, quote);
        return config;
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        ChronicleConfig memory config = _getOrRevertConfig(base, quote);

        (uint256 unitPrice, uint256 age) = IChronicle(config.feed).readWithAge();
        if (age > maxStaleness) revert PriceTooStale(age, maxStaleness);

        if (config.inverse) return (inAmount * 10 ** config.quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** config.baseDecimals;
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableChronicleOracle(maxStaleness);
    }
}
