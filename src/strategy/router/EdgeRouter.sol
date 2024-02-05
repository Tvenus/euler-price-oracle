// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {EFactory} from "@euler-vault/EFactory/EFactory.sol";
import {GovEOracle} from "src/GovEOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @title EdgeRouter
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Default Oracle resolver for Euler Edge.
contract EdgeRouter is GovEOracle {
    address public fallbackOracle;
    mapping(address base => mapping(address quote => address oracle)) public oracles;
    mapping(address vault => address asset) public resolvedVaults;

    event ConfigSet(address indexed base, address indexed quote, address indexed oracle);
    event ConfigUnset(address indexed base, address indexed quote);
    event FallbackOracleSet(address indexed fallbackOracle);
    event ResolvedVaultSet(address indexed vault, address indexed asset);

    function govSetConfig(address base, address quote, address oracle) external onlyGovernor {
        oracles[base][quote] = oracle;
        emit ConfigSet(base, quote, oracle);
    }

    function govUnsetConfig(address base, address quote) external onlyGovernor {
        delete oracles[base][quote];
        emit ConfigUnset(base, quote);
    }

    function govSetResolvedVault(address vault) external onlyGovernor {
        address asset = ERC4626(vault).asset();
        resolvedVaults[vault] = asset;
        emit ResolvedVaultSet(vault, asset);
    }

    function govUnsetResolvedVault(address vault) external onlyGovernor {
        delete resolvedVaults[vault];
        emit ResolvedVaultSet(vault, address(0));
    }

    function govSetFallbackOracle(address _fallbackOracle) external onlyGovernor {
        fallbackOracle = _fallbackOracle;
        emit FallbackOracleSet(_fallbackOracle);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        address oracle;
        (inAmount, base, quote, oracle) = _resolveOracle(inAmount, base, quote);
        if (base == quote) return inAmount;
        return IEOracle(oracle).getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        address oracle;
        (inAmount, base, quote, oracle) = _resolveOracle(inAmount, base, quote);
        if (base == quote) return (inAmount, inAmount);
        return IEOracle(oracle).getQuotes(inAmount, base, quote);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.EdgeRouter(governor);
    }

    function _resolveOracle(uint256 inAmount, address base, address quote)
        internal
        view
        returns (uint256, address, address, address)
    {
        if (base == quote) return (inAmount, base, quote, address(0));
        address oracle = oracles[base][quote];
        if (oracle != address(0)) return (inAmount, base, quote, oracle);

        address baseAsset = resolvedVaults[base];
        if (baseAsset != address(0)) {
            inAmount = ERC4626(base).convertToAssets(inAmount);
            return _resolveOracle(inAmount, baseAsset, quote);
        }

        address quoteAsset = resolvedVaults[quote];
        if (quoteAsset != address(0)) {
            inAmount = ERC4626(quote).convertToShares(inAmount);
            return _resolveOracle(inAmount, base, quoteAsset);
        }

        oracle = fallbackOracle;
        if (oracle == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return (inAmount, base, quote, oracle);
    }
}