// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC4626UpgSYV2.sol";
import "./interfaces/IWBTCConverter.sol";

contract PendleStrBTCSYUpg is PendleERC4626UpgSYV2 {
    address public wBTC;
    address public wBTCConverter;

    uint256[50] private __gap;

    constructor(address _wstrBTC) PendleERC4626UpgSYV2(_wstrBTC) {}

    function initialize(string memory _name, string memory _symbol, address _wBTC, address _wBTCConverter)
        external
        initializer
    {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken); // strBTC -> wstrBTC

        wBTC = _wBTC;
        wBTCConverter = _wBTCConverter;

        _safeApproveInf(wBTC, wBTCConverter);
    }

    /**
     * @dev Extends the basic deposit logic to support wBTC
     */
    function _deposit(address tokenIn, uint256 amountDeposited) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == wBTC) {
            uint256 strBTCAmount = IWBTCConverter(wBTCConverter).convertWBTCToStrBTC(amountDeposited);
            return super._deposit(asset, strBTCAmount);
        }

        // For strBTC and wstrBTC, we use standard ERC4626 logic
        return super._deposit(tokenIn, amountDeposited);
    }

    /**
     * @dev Extends preview to support wBTC
     */
    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == wBTC) {
            uint256 strBTCAmount = (amountTokenToDeposit * IWBTCConverter(wBTCConverter).incomingRateNumerator())
                / IWBTCConverter(wBTCConverter).incomingRateDenominator();
            return super._previewDeposit(asset, strBTCAmount);
        }

        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    /**
     * @dev Adds wBTC to the list of supported tokens
     */
    function getTokensIn() public view override returns (address[] memory res) {
        res = new address[](3);
        res[0] = wBTC; // Additional token
        res[1] = asset; // strBTC (from ERC4626UpgSYV2)
        res[2] = yieldToken; // wstrBTC (from ERC4626UpgSYV2)
    }

    /**
     * @dev Extends validation to support wBTC
     */
    function isValidTokenIn(address token) public view override returns (bool) {
        return token == wBTC || super.isValidTokenIn(token);
    }

    /**
     * @notice Updates the wBTC converter (only owner)
     */
    function updateWBTCConverter(address _newConverter) external onlyOwner {
        require(_newConverter != address(0), "Invalid converter address");

        _safeApprove(wBTC, wBTCConverter, 0);

        wBTCConverter = _newConverter;

        _safeApproveInf(wBTC, wBTCConverter);
    }

    /**
     * @notice Version of the contract
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
