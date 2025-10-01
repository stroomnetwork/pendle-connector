// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IStandardizedYieldAdapter} from "Pendle-SY-Public/interfaces/IStandardizedYieldAdapter.sol";
import {IWBTCConverter} from "./interfaces/IWBTCConverter.sol";
import {ICBBTCConverter} from "./interfaces/ICBBTCConverter.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PendleStroomAdapter
 * @dev Adapter for converting wBTC and cbBTC to strBTC for Pendle StandardizedYield
 * @notice This adapter allows PendleERC4626WithAdapterSY to accept wBTC and cbBTC deposits
 *         by converting them to strBTC (the pivot token) via IWBTCConverter and ICBBTCConverter
 */
contract PendleStroomAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    address public constant PIVOT_TOKEN = 0xB2723d5dF98689eCA6A4E7321121662DDB9b3017; // strBTC address

    address public immutable wBTC;
    address public immutable cbBTC;

    address public immutable wBTCConverter;
    address public immutable cbBTCConverter;

    event ConvertedToDeposit(address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    event ConvertedToRedeem(address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _wBTC, address _cbBTC, address _wBTCConverter, address _cbBTCConverter) {
        require(_wBTC != address(0), "Invalid wBTC address");
        require(_cbBTC != address(0), "Invalid cbBTC address");
        require(_wBTCConverter != address(0), "Invalid wBTC converter address");
        require(_cbBTCConverter != address(0), "Invalid cbBTC converter address");

        wBTC = _wBTC;
        cbBTC = _cbBTC;
        wBTCConverter = _wBTCConverter;
        cbBTCConverter = _cbBTCConverter;

        IERC20(wBTC).forceApprove(_wBTCConverter, type(uint256).max);
        IERC20(cbBTC).forceApprove(_cbBTCConverter, type(uint256).max);
        IERC20(PIVOT_TOKEN).forceApprove(_wBTCConverter, type(uint256).max);
        IERC20(PIVOT_TOKEN).forceApprove(_cbBTCConverter, type(uint256).max);
    }

    /**
     * @dev Converts wBTC or cbBTC to strBTC for deposits
     * @param tokenIn Must be wBTC or cbBTC
     * @param amountTokenIn Amount of token to convert
     * @return amountOut Amount of strBTC received
     */
    function convertToDeposit(address tokenIn, uint256 amountTokenIn) external override returns (uint256 amountOut) {
        require(tokenIn == wBTC || tokenIn == cbBTC, "Only wBTC or cbBTC supported for deposits");

        if (tokenIn == wBTC) {
            amountOut = IWBTCConverter(wBTCConverter).convertWBTCToStrBTC(amountTokenIn);
        } else {
            amountOut = ICBBTCConverter(cbBTCConverter).convertCBBTCToStrBTC(amountTokenIn);
        }

        IERC20(PIVOT_TOKEN).safeTransfer(msg.sender, amountOut);

        emit ConvertedToDeposit(tokenIn, amountTokenIn, amountOut);
    }

    /**
     * @dev Converts strBTC to wBTC or cbBTC for redemptions
     * @param tokenOut Must be wBTC or cbBTC
     * @param amountPivotTokenIn Amount of strBTC to convert
     * @return amountOut Amount of token received
     */
    function convertToRedeem(address tokenOut, uint256 amountPivotTokenIn)
        external
        override
        returns (uint256 amountOut)
    {
        require(tokenOut == wBTC || tokenOut == cbBTC, "Only wBTC or cbBTC supported for redemptions");

        if (tokenOut == wBTC) {
            amountOut = IWBTCConverter(wBTCConverter).convertStrBTCToWBTC(amountPivotTokenIn);
        } else {
            amountOut = ICBBTCConverter(cbBTCConverter).convertStrBTCToCBBTC(amountPivotTokenIn);
        }

        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit ConvertedToRedeem(tokenOut, amountPivotTokenIn, amountOut);
    }

    /**
     * @dev Preview conversion of wBTC or cbBTC to strBTC for deposits
     * @param tokenIn Must be wBTC or cbBTC
     * @param amountTokenIn Amount of token to convert
     * @return amountOut Estimated amount of strBTC
     */
    function previewConvertToDeposit(address tokenIn, uint256 amountTokenIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        require(tokenIn == wBTC || tokenIn == cbBTC, "Only wBTC or cbBTC supported for deposits");

        uint256 numerator;
        uint256 denominator;

        if (tokenIn == wBTC) {
            numerator = IWBTCConverter(wBTCConverter).incomingRateNumerator();
            denominator = IWBTCConverter(wBTCConverter).incomingRateDenominator();
        } else {
            numerator = ICBBTCConverter(cbBTCConverter).rateNumerator();
            denominator = ICBBTCConverter(cbBTCConverter).rateDenominator();
        }

        amountOut = (amountTokenIn * numerator) / denominator;
    }

    /**
     * @dev Preview conversion of strBTC to wBTC or cbBTC for redemptions
     * @param tokenOut Must be wBTC or cbBTC
     * @param amountPivotTokenIn Amount of strBTC to convert
     * @return amountOut Estimated amount of token
     */
    function previewConvertToRedeem(address tokenOut, uint256 amountPivotTokenIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        require(tokenOut == wBTC || tokenOut == cbBTC, "Only wBTC or cbBTC supported for redemptions");

        uint256 numerator;
        uint256 denominator;

        if (tokenOut == wBTC) {
            numerator = IWBTCConverter(wBTCConverter).outgoingRateNumerator();
            denominator = IWBTCConverter(wBTCConverter).outgoingRateDenominator();
        } else {
            numerator = ICBBTCConverter(cbBTCConverter).rateNumerator();
            denominator = ICBBTCConverter(cbBTCConverter).rateDenominator();
        }

        amountOut = (amountPivotTokenIn * numerator) / denominator;
    }

    /**
     * @dev Returns supported tokens for deposits
     * @return tokens Array containing wBTC and cbBTC
     */
    function getAdapterTokensDeposit() external view override returns (address[] memory tokens) {
        tokens = new address[](2);
        tokens[0] = wBTC;
        tokens[1] = cbBTC;
    }

    /**
     * @dev Returns supported tokens for redemptions
     * @return tokens Array containing wBTC and cbBTC
     */
    function getAdapterTokensRedeem() external view override returns (address[] memory tokens) {
        tokens = new address[](2);
        tokens[0] = wBTC;
        tokens[1] = cbBTC;
    }
}
