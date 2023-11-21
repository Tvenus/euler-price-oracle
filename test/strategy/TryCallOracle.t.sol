// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {TryCallOracleHarness} from "test/utils/TryCallOracleHarness.sol";
import {IOracle} from "src/interfaces/IOracle.sol";

contract TryCallOracleTest is Test {
    TryCallOracleHarness private immutable harness;

    constructor() {
        harness = new TryCallOracleHarness();
    }

    function test_TryGetQuote_WhenNotIOracle_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        oracle = boundAddr(oracle);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IOracle(oracle), inAmount, base, quote);

        assertFalse(success);
        assertEq(outAmount, 0);
    }

    function test_TryGetQuote_WhenReturnsInvalidLengthData_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length != 32);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuote.selector), returnData);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IOracle(oracle), inAmount, base, quote);
        assertFalse(success);
        assertEq(outAmount, 0);
    }

    function test_TryGetQuote_WhenReturns32Bytes_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length == 32);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuote.selector), returnData);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(outAmount, abi.decode(returnData, (uint256)));
    }

    function test_TryGetQuote_WhenReturnsUint256_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnOutAmount
    ) public {
        oracle = boundAddr(oracle);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuote.selector), abi.encode(returnOutAmount));
        (bool success, uint256 outAmount) = harness.tryGetQuote(IOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(outAmount, returnOutAmount);
    }

    function test_TryGetQuotes_WhenNotIOracle_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        oracle = boundAddr(oracle);
        (bool success, uint256 bidOut, uint256 askOut) = harness.tryGetQuotes(IOracle(oracle), inAmount, base, quote);

        assertFalse(success);
        assertEq(bidOut, 0);
        assertEq(askOut, 0);
    }

    function test_TryGetQuotes_WhenReturnsInvalidLengthData_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length != 64);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuotes.selector), returnData);
        (bool success, uint256 bidOut, uint256 askOut) = harness.tryGetQuotes(IOracle(oracle), inAmount, base, quote);
        assertFalse(success);
        assertEq(bidOut, 0);
        assertEq(askOut, 0);
    }

    function test_TryGetQuotes_WhenReturns64Bytes_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length == 64);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuotes.selector), returnData);
        (bool success, uint256 bidOut, uint256 askOut) = harness.tryGetQuotes(IOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        (uint256 resBidOut, uint256 resAskOut) = abi.decode(returnData, (uint256, uint256));
        assertEq(bidOut, resBidOut);
        assertEq(askOut, resAskOut);
    }

    function test_TryGetQuotes_WhenReturnsTwoUint256s_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnBidOut,
        uint256 returnAskOut
    ) public {
        oracle = boundAddr(oracle);
        vm.mockCall(oracle, abi.encodeWithSelector(IOracle.getQuotes.selector), abi.encode(returnBidOut, returnAskOut));
        (bool success, uint256 bidOut, uint256 askOut) = harness.tryGetQuotes(IOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(bidOut, returnBidOut);
        assertEq(askOut, returnAskOut);
    }
}