// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";

import { ChessPieces } from "../src/ChessPieces.sol";
import { SupplyPolicy } from "../src/SupplyPolicy.sol";
import { ISupplyPolicy } from "../src/interfaces/ISupplyPolicy.sol";

contract DeployChessPieces is Script {
    function run() external returns (SupplyPolicy supplyPolicy, ChessPieces chessPieces) {
        address admin = vm.envAddress("ADMIN");

        vm.startBroadcast();

        // 1. Deploy the supply policy.
        supplyPolicy = new SupplyPolicy(admin);

        // 2. Deploy the ERC-721 contract and connect it
        //    permanently to the supply policy.
        chessPieces = new ChessPieces(admin, ISupplyPolicy(address(supplyPolicy)));

        // 3. Allow ChessPieces to consume series supply.
        supplyPolicy.grantRole(supplyPolicy.CONSUMER_ROLE(), address(chessPieces));

        vm.stopBroadcast();

        console2.log("Admin:", admin);

        console2.log("SupplyPolicy:", address(supplyPolicy));

        console2.log("ChessPieces:", address(chessPieces));
    }
}
