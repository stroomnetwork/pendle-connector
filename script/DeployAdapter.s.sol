// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {PendleStroomAdapter} from "../src/PendleStroomAdapter.sol";

contract DeployAdapterScript is Script {
    function run() public {
        address wBTC = vm.envAddress("WBTC_ADDRESS");
        address cbBTC = vm.envAddress("CBBTC_ADDRESS");
        address wBTCConverter = vm.envAddress("WBTC_CONVERTER_ADDRESS");
        address cbBTCConverter = vm.envAddress("CBBTC_CONVERTER_ADDRESS");

        vm.startBroadcast();

        PendleStroomAdapter adapter = new PendleStroomAdapter(wBTC, cbBTC, wBTCConverter, cbBTCConverter);

        vm.stopBroadcast();

        console.log("PendleStroomAdapter deployed to:", address(adapter));
        console.log("wBTC:", wBTC);
        console.log("cbBTC:", cbBTC);
        console.log("wBTCConverter:", wBTCConverter);
        console.log("cbBTCConverter:", cbBTCConverter);
    }
}
