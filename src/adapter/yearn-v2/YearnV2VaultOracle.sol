// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {IYearnV2Vault} from "src/adapter/yearn-v2/IYearnV2Vault.sol";

contract YearnV2VaultOracle {
    address public immutable yvToken;
    address public immutable underlying;
    uint8 public immutable yvTokenDecimals;
    uint8 public immutable underlyingDecimals;

    error NotSupported(address base, address quote);

    constructor(address _yvToken) {
        yvToken = _yvToken;
        underlying = IYearnV2Vault(_yvToken).token();
        yvTokenDecimals = ERC20(_yvToken).decimals();
        underlyingDecimals = ERC20(underlying).decimals();
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (base == yvToken && quote == underlying) {
            uint256 price = IYearnV2Vault(yvToken).pricePerShare();
            return inAmount * 10 ** yvTokenDecimals / price;
        }

        if (base == underlying && quote == yvToken) {
            uint256 price = IYearnV2Vault(yvToken).pricePerShare();
            return inAmount * price / 10 ** yvTokenDecimals;
        }

        revert NotSupported(base, quote);
    }
}
