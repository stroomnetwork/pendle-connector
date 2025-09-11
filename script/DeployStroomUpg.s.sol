// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PendleStroomSYUpg} from "../src/PendleStroomSYUpg.sol";

contract DeployStroomUpgScript is Script {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address wstrBTC = vm.envAddress("WSTR_BTC_ADDRESS");
        address adapter = vm.envAddress("STROOM_ADAPTER_ADDRESS");

        string memory name = vm.envOr("TOKEN_NAME", string("SY Stroom"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("SY-Stroom"));

        vm.startBroadcast();

        // Deploy implementation
        PendleStroomSYUpg implementation = new PendleStroomSYUpg(wstrBTC);

        // Prepare data for initialization
        bytes memory initData = abi.encodeWithSelector(PendleStroomSYUpg.initialize.selector, name, symbol, adapter);

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(implementation), owner, initData);

        vm.stopBroadcast();

        address pendleStroomSYUpg = address(proxy);

        console.log("PendleStroomSYUpg implementation deployed to:", address(implementation));
        console.log("PendleStroomAdapter address:", adapter);
        console.log("PendleStroomSYUpg proxy deployed to:", pendleStroomSYUpg);
        console.log("Owner:", owner);
        console.log("wstrBTC:", wstrBTC);
    }
}
