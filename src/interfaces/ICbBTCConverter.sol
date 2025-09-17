// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ICbBTCConverter {
    function convertCbBTCToStrBTC(uint256 cbbtcAmount) external returns (uint256);

    function convertStrBTCToCbBTC(uint256 strbtcAmount) external returns (uint256);

    function incomingRateNumerator() external view returns (uint256);

    function incomingRateDenominator() external view returns (uint256);

    function outgoingRateNumerator() external view returns (uint256);

    function outgoingRateDenominator() external view returns (uint256);
}
