// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC4626SYV2.sol";
import "./interfaces/IWBTCConverter.sol";

contract PendleStrBTCSY is PendleERC4626SYV2 {
    address public immutable wBTC;
    address public immutable wBTCConverter;

    constructor(string memory _name, string memory _symbol, address _wstrBTC, address _wBTC, address _wBTCConverter)
        PendleERC4626SYV2(_name, _symbol, _wstrBTC)
    {
        wBTC = _wBTC;
        wBTCConverter = _wBTCConverter;

        _safeApproveInf(wBTC, wBTCConverter);
    }

    /**
     * @dev Extends the basic deposit logic to support wBTC
     * Base class already handles strBTC -> wstrBTC via ERC4626.deposit()
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
        res[1] = asset; // strBTC (from ERC4626SYV2)
        res[2] = yieldToken; // wstrBTC (from ERC4626SYV2)
    }

    /**
     * @dev Extends validation to support wBTC
     */
    function isValidTokenIn(address token) public view override returns (bool) {
        return token == wBTC || super.isValidTokenIn(token);
    }
}
