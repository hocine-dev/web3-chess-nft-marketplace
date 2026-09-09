// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";

import { SupplyPolicy } from "../src/SupplyPolicy.sol";
import { Season1Catalog } from "../src/catalog/Season1Catalog.sol";

contract ConfigureSeason1 is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address supplyPolicyAddress = vm.envAddress("SUPPLY_POLICY");

        address admin = vm.addr(privateKey);

        SupplyPolicy supplyPolicy = SupplyPolicy(supplyPolicyAddress);

        require(
            supplyPolicy.hasRole(supplyPolicy.POLICY_MANAGER_ROLE(), admin),
            "Wallet is not policy manager"
        );

        Season1Catalog.SeriesConfig[] memory configs = Season1Catalog.series();

        vm.startBroadcast(privateKey);

        for (uint256 i = 0; i < configs.length; i++) {
            supplyPolicy.configureSeries(configs[i].data, configs[i].maxSupply);
        }

        vm.stopBroadcast();

        console2.log("Season 1 configured");

        console2.log("Series configured:", configs.length);

        console2.log("SupplyPolicy:", supplyPolicyAddress);
    }
}
