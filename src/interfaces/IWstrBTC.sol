// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IWstrBTC {
    function wrap(uint256 strBTCAmount) external returns (uint256);

    function unwrap(uint256 wstrBTCAmount) external returns (uint256);

    function strBTC() external view returns (address);

    function strBTCPerToken(uint256 amount) external view returns (uint256);

    function tokensPerStrBTC(uint256 amount) external view returns (uint256);
}
