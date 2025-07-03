// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/PendleStrBTCSY.sol";

contract DeployScript is Script {
    function run() public {
        address wstrBTC = vm.envAddress("WSTR_BTC_ADDRESS");
        address wBTC = vm.envAddress("WBTC_ADDRESS");
        address wBTCConverter = vm.envAddress("WBTC_CONVERTER_ADDRESS");

        string memory name = vm.envOr("TOKEN_NAME", string("SY strBTC"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("SY-strBTC"));

        vm.startBroadcast();

        PendleStrBTCSY pendleStrBTCSY = new PendleStrBTCSY(name, symbol, wstrBTC, wBTC, wBTCConverter);

        vm.stopBroadcast();

        console.log("PendleStrBTCSY deployed to:", address(pendleStrBTCSY));
    }
}
