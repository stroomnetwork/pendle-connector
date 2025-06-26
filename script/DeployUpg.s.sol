// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/PendleStrBTCSYUpg.sol";

contract DeployUpgradeableScript is Script {
    function setUp() public {}

    function run() public {
        address owner = vm.envAddress("OWNER");
        address strBTC = vm.envAddress("STR_BTC_ADDRESS");
        address wstrBTC = vm.envAddress("WSTR_BTC_ADDRESS");
        address wBTC = vm.envAddress("WBTC_ADDRESS");
        address wBTCConverter = vm.envAddress("WBTC_CONVERTER_ADDRESS");

        string memory name = vm.envOr("TOKEN_NAME", string("SY strBTC"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("SY-strBTC"));

        vm.startBroadcast();

        // Deploy implementation
        PendleStrBTCSYUpg implementation = new PendleStrBTCSYUpg(wstrBTC);

        // Prepare data for initialization
        bytes memory initData = abi.encodeWithSelector(
            PendleStrBTCSYUpg.initialize.selector,
            name,
            symbol,
            strBTC,
            wstrBTC,
            wBTC,
            wBTCConverter
        );

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            owner,
            initData
        );

        vm.stopBroadcast();

        address pendleStrBTCSYUpg = address(proxy);

        console.log("PendleStrBTCSYUpg deployed to:", pendleStrBTCSYUpg);
    }
}
