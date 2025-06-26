// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IWBTCConverter {
    function convertWBTCToStrBTC(uint256 wbtcAmount) external returns (uint256);

    function convertStrBTCToWBTC(uint256 strbtcAmount) external returns (uint256);

    function incomingRateNumerator() external view returns (uint256);

    function incomingRateDenominator() external view returns (uint256);

    function outgoingRateNumerator() external view returns (uint256);

    function outgoingRateDenominator() external view returns (uint256);
}
