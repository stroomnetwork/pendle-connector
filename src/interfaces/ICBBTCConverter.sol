// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ICBBTCConverter {
    function convertCBBTCToStrBTC(uint256 cbbtcAmount) external returns (uint256);

    function convertStrBTCToCBBTC(uint256 strbtcAmount) external returns (uint256);

    function rateNumerator() external view returns (uint256);

    function rateDenominator() external view returns (uint256);
}
