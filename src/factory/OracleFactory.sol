// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {GenericFactory} from "@euler-factory/GenericFactory.sol";

/// @title OracleFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Euler Factory for EOracles.
contract OracleFactory is GenericFactory {
    mapping(address oracle => OracleConfig) oracleLookup;

    struct OracleConfig {
        bool upgradeable;
    }

    constructor(address admin) GenericFactory(admin) {}

    function deploy(bool upgradeable, bytes memory trailingData) external nonReentrant returns (address) {
        address proxy = createProxy(upgradeable, trailingData);

        oracleLookup[proxy] = OracleConfig({upgradeable: upgradeable});

        return proxy;
    }
}
