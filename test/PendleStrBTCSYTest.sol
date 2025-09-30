// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.27;

import {SYWithAdapterTest} from "pendle-sy-tests/common/SYWithAdapterTest.t.sol";
import {PendleStroomAdapter} from "../src/PendleStroomAdapter.sol";
import {IStandardizedYield} from "pendle-sy/interfaces/IStandardizedYield.sol";

contract PendleStrBTCSYTest is SYWithAdapterTest {
    address internal constant strBTC = 0xB2723d5dF98689eCA6A4E7321121662DDB9b3017;
    address internal constant wstrBTC = 0xA3Ca88cfb7bBe9CfBd47df053ffA2130C7E6f770;
    address internal constant wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address internal constant wBTCConverter = 0x56192F14C1d84e41Db3d5d4C5d407EFDB5CB1352;
    address internal constant cbBTCConverter = 0xe7b4c44adB17147Ad877EB8607EEB1e95AdF2cD0;

    function setUpFork() internal override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
    }

    function deploySY() internal override {
        vm.startPrank(deployer);

        address adapter = address(new PendleStroomAdapter(wBTC, cbBTC, wBTCConverter, cbBTCConverter));

        sy =
            IStandardizedYield(deploySYWithAdapter(AdapterType.ERC4626, wstrBTC, "SY Stroom BTC", "SY-StrBTC", adapter));
        vm.stopPrank();
    }

    // Allow 0.3% tolerance for converter fees (incoming: 999/1000, outgoing: 999/1000)
    // Total loss: ~0.2%, so 0.3% provides comfortable margin
    function getPreviewTestAllowedEps() internal pure override returns (uint256) {
        return 0.003e18; // 0.3%
    }

    // Our adapter has fees due to converter rates (999/1000 in both directions)
    function hasFee() internal pure override returns (bool) {
        return true;
    }

    // Test all valid token pairs by excluding invalid ones:
    // Invalid pairs excluded:
    // - wBTC -> cbBTC, cbBTC -> wBTC (cross-converter operations)
    // - strBTC -> wBTC, wstrBTC -> wBTC (depends on wBTCConverter reserves)
    // - strBTC -> cbBTC, wstrBTC -> cbBTC (depends on cbBTCConverter reserves)
    function _genPreviewDepositThenRedeemTestParams()
        internal
        override
        returns (PreviewDepositThenRedeemTestParam[] memory)
    {
        uint256 DENOM = 17;
        uint256 NUMER = 3;
        uint256 NUM_TESTS_PER_PAIR = 5;

        address[] memory allTokensIn = getTokensInForPreviewTest();
        address[] memory allTokensOut = getTokensOutForPreviewTest();
        delete params;

        uint256 divBy = 1;
        for (uint256 i = 0; i < allTokensIn.length; ++i) {
            for (uint256 j = 0; j < allTokensOut.length; ++j) {
                address tokenIn = allTokensIn[i];
                address tokenOut = allTokensOut[j];

                bool isInvalidPair = (tokenIn == wBTC && tokenOut == cbBTC) // Cross-converter
                    || (tokenIn == cbBTC && tokenOut == wBTC) // Cross-converter
                    || (tokenIn == strBTC && tokenOut == wBTC) // Depends on wBTCConverter reserves
                    || (tokenIn == wstrBTC && tokenOut == wBTC) // Depends on wBTCConverter reserves
                    || (tokenIn == strBTC && tokenOut == cbBTC) // Depends on cbBTCConverter reserves
                    || (tokenIn == wstrBTC && tokenOut == cbBTC); // Depends on cbBTCConverter reserves

                if (isInvalidPair) continue;

                uint256 refAmount = refAmountFor(tokenIn);
                for (uint256 numTest = 0; numTest < NUM_TESTS_PER_PAIR; ++numTest) {
                    uint256 amountIn = refAmount / divBy;
                    divBy = (divBy * NUMER) % DENOM;

                    params.push() = PreviewDepositThenRedeemTestParam({
                        tokenIn: tokenIn,
                        netTokenIn: amountIn,
                        tokenOut: tokenOut,
                        shouldCheck: numTest == 0
                    });
                }
            }
        }

        return params;
    }
}
