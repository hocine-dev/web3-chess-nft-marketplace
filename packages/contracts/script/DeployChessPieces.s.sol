// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ChessPieces } from "../src/ChessPieces.sol";

contract DeployChessPieces is Script {
    function run() external returns (ChessPieces chessPieces) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        chessPieces = new ChessPieces(admin);

        vm.stopBroadcast();

        console2.log("ChessPieces deployed at:");
        console2.logAddress(address(chessPieces));

        console2.log("Admin:");
        console2.logAddress(admin);
    }
}
