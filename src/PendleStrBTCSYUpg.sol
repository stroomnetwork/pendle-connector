// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "Pendle-SY-Public/core/StandardizedYield/SYBaseUpg.sol";
import "./interfaces/IWstrBTC.sol";
import "./interfaces/IWBTCConverter.sol";

contract PendleStrBTCSYUpg is SYBaseUpg {
    address public strBTC;
    address public wstrBTC;
    address public wBTC;
    address public wBTCConverter;

    uint256[50] private __gap;

    constructor(address _yieldToken) SYBaseUpg(_yieldToken) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _strBTC,
        address _wstrBTC,
        address _wBTC,
        address _wBTCConverter
    ) external initializer {
        __SYBaseUpg_init(_name, _symbol);

        strBTC = _strBTC;
        wstrBTC = _wstrBTC;
        wBTC = _wBTC;
        wBTCConverter = _wBTCConverter;

        _safeApproveInf(strBTC, wstrBTC);
        _safeApproveInf(wBTC, wBTCConverter);
        _safeApproveInf(strBTC, wBTCConverter);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {SYBaseUpg-_deposit}
     *
     * The base yield token is wstrBTC. Depending on the deposit token:
     * - wstrBTC: returns the amount of 1:1
     * - strBTC: wraps in wstrBTC
     * - wBTC: converts through converter to strBTC, then wraps in wstrBTC
     *
     * The exchange rate of wstrBTC to shares is 1:1
     */
    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == wstrBTC) {
            amountSharesOut = amountDeposited;
        } else if (tokenIn == strBTC) {
            amountSharesOut = IWstrBTC(wstrBTC).wrap(amountDeposited);
        } else {
            // tokenIn must be wBTC
            uint256 strBTCAmount = IWBTCConverter(wBTCConverter).convertWBTCToStrBTC(amountDeposited);
            amountSharesOut = IWstrBTC(wstrBTC).wrap(strBTCAmount);
        }
    }

    /**
     * @dev See {SYBaseUpg-_redeem}
     *
     * Shares are redeemed depending on tokenOut:
     * - wstrBTC: returns shares 1:1
     * - strBTC: unwraps wstrBTC to strBTC
     */
    function _redeem(address receiver, address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == wstrBTC) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IWstrBTC(wstrBTC).unwrap(amountSharesToRedeem);
        }
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates and updates the exchange rate of shares to the base asset token
     * @dev This is the exchange rate of wstrBTC to strBTC
     */
    function exchangeRate() public view virtual override returns (uint256) {
        return IWstrBTC(wstrBTC).strBTCPerToken(1e8); // strBTC has 8 decimals
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == wstrBTC) {
            amountSharesOut = amountTokenToDeposit;
        } else if (tokenIn == strBTC) {
            amountSharesOut = IWstrBTC(wstrBTC).tokensPerStrBTC(amountTokenToDeposit);
        } else {
            uint256 strBTCAmount = (amountTokenToDeposit * IWBTCConverter(wBTCConverter).incomingRateNumerator())
                / IWBTCConverter(wBTCConverter).incomingRateDenominator();
            amountSharesOut = IWstrBTC(wstrBTC).tokensPerStrBTC(strBTCAmount);
        }
    }

    function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        view
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == wstrBTC) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IWstrBTC(wstrBTC).strBTCPerToken(amountSharesToRedeem);
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = wBTC;
        res[1] = strBTC;
        res[2] = wstrBTC;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = strBTC;
        res[1] = wstrBTC;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == strBTC || token == wstrBTC || token == wBTC;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == strBTC || token == wstrBTC || token == wBTC;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, strBTC, IERC20Metadata(strBTC).decimals());
    }

    /*///////////////////////////////////////////////////////////////
                        UPGRADEABLE ADMINISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the wBTC converter address (only for owner)
     * @param _newConverter New converter address
     */
    function updateWBTCConverter(address _newConverter) external onlyOwner {
        require(_newConverter != address(0), "Invalid converter address");

        _safeApprove(wBTC, wBTCConverter, 0);
        _safeApprove(strBTC, wBTCConverter, 0);

        wBTCConverter = _newConverter;

        _safeApproveInf(wBTC, wBTCConverter);
        _safeApproveInf(strBTC, wBTCConverter);
    }

    /**
     * @notice Version of the contract for tracking updates
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
