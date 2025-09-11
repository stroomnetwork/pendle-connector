// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {
    PendleERC4626WithAdapterSY,
    IStandardizedYieldAdapter
} from "Pendle-SY-Public/core/StandardizedYield/implementations/Adapter/extensions/PendleERC4626WithAdapterSY.sol";
import {ArrayLib} from "Pendle-SY-Public/core/libraries/ArrayLib.sol";

/**
 * @title PendleStroomSYUpg
 * @dev Upgradeable StandardizedYield contract for strBTC with wBTC and cbBTC adapter support
 * @notice This contract uses PendleERC4626WithAdapterSY with PendleStroomAdapter
 *         to support deposits/redemptions in strBTC, wBTC, and cbBTC
 */
contract PendleStroomSYUpg is PendleERC4626WithAdapterSY {
    address public stroomAdapter;

    uint256[99] private __gap;

    event StroomAdapterSet(address indexed adapter);

    constructor(address _wstrBTC) PendleERC4626WithAdapterSY(_wstrBTC) {}

    /**
     * @dev Initialize the contract with adapter address
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _stroomAdapter Stroom adapter address
     */
    function initialize(string memory _name, string memory _symbol, address _stroomAdapter)
        external
        override
        initializer
    {
        __SYBaseUpg_init(_name, _symbol);

        require(_stroomAdapter != address(0), "Invalid adapter address");

        stroomAdapter = _stroomAdapter;

        _safeApproveInf(asset, yieldToken);
        _setAdapter(stroomAdapter);

        emit StroomAdapterSet(stroomAdapter);
    }

    /**
     * @dev Update the adapter (only owner)
     * @param _newAdapter New adapter address
     */
    function updateAdapter(address _newAdapter) external onlyOwner {
        require(_newAdapter != address(0), "Invalid adapter address");
        stroomAdapter = _newAdapter;
        _setAdapter(_newAdapter);
        emit StroomAdapterSet(_newAdapter);
    }

    /**
     * @dev Returns all supported input tokens (strBTC, wstrBTC, wBTC, cbBTC)
     * @return result Array of supported input token addresses
     */
    function getTokensIn() public view override returns (address[] memory result) {
        address[] memory baseTokens = super.getTokensIn(); // strBTC, wstrBTC
        address[] memory adapterTokens = IStandardizedYieldAdapter(stroomAdapter).getAdapterTokensDeposit(); // wBTC, cbBTC

        result = _combineTokenArrays(baseTokens, adapterTokens);
    }

    /**
     * @dev Returns all supported output tokens (strBTC, wstrBTC, wBTC, cbBTC)
     * @return result Array of supported output token addresses
     */
    function getTokensOut() public view override returns (address[] memory result) {
        address[] memory baseTokens = super.getTokensOut(); // strBTC, wstrBTC
        address[] memory adapterTokens = IStandardizedYieldAdapter(stroomAdapter).getAdapterTokensRedeem(); // wBTC, cbBTC

        result = _combineTokenArrays(baseTokens, adapterTokens);
    }

    /**
     * @dev Validates if a token is supported for input
     * @param token Token address to validate
     * @return bool True if token is supported for deposits
     */
    function isValidTokenIn(address token) public view override returns (bool) {
        if (super.isValidTokenIn(token)) {
            return true;
        }

        return ArrayLib.contains(IStandardizedYieldAdapter(stroomAdapter).getAdapterTokensDeposit(), token);
    }

    /**
     * @dev Validates if a token is supported for output
     * @param token Token address to validate
     * @return bool True if token is supported for redemptions
     */
    function isValidTokenOut(address token) public view override returns (bool) {
        if (super.isValidTokenOut(token)) {
            return true;
        }

        return ArrayLib.contains(IStandardizedYieldAdapter(stroomAdapter).getAdapterTokensRedeem(), token);
    }

    /**
     * @dev Combines two token arrays into one
     * @param baseTokens First array (from parent contract)
     * @param adapterTokens Second array (from adapter)
     * @return result Combined array
     */
    function _combineTokenArrays(address[] memory baseTokens, address[] memory adapterTokens)
        private
        pure
        returns (address[] memory result)
    {
        result = new address[](baseTokens.length + adapterTokens.length);

        for (uint256 i = 0; i < baseTokens.length; i++) {
            result[i] = baseTokens[i];
        }

        for (uint256 i = 0; i < adapterTokens.length; i++) {
            result[baseTokens.length + i] = adapterTokens[i];
        }
    }

    /**
     * @dev Get contract version
     * @return string Version string
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
