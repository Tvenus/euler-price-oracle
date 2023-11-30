// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

contract OracleProxy {
    // ERC-1967 beacon address slot. bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
    bytes32 constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    address immutable beacon;
    uint256 immutable metadata1;
    uint256 immutable metadata2;

    event Genesis();

    constructor(address _asset, address _riskManager) {
        beacon = msg.sender;

        // pack 41 bytes metadata into 2 words
        metadata1 = (uint256(uint160(_asset)) << 96) | uint256(uint160(_riskManager)) >> 64;
        metadata2 = uint256(uint160(_riskManager)) << 192;

        // Store the beacon address in ERC-1967 slot for compatibility with block explorers
        assembly {
            sstore(BEACON_SLOT, caller())
        }

        emit Genesis();
    }

    fallback() external {
        address beacon_ = beacon;
        uint256 metadata1_ = metadata1;
        uint256 metadata2_ = metadata2;

        assembly {
            // fetch implementation address from the beacon
            mstore(0, 0x5c60da1b00000000000000000000000000000000000000000000000000000000) // implementation() selector
            let result := staticcall(gas(), beacon_, 0, 4, 0, 32)
            if eq(result, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            let implementation := mload(0)

            // delegate call to the implementation
            calldatacopy(0, 0, calldatasize())
            mstore(calldatasize(), metadata1_)
            mstore(add(32, calldatasize()), metadata2_)
            result := delegatecall(gas(), implementation, 0, add(40, calldatasize()), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
