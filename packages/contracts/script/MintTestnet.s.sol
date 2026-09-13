// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";

import { ChessPieces } from "../src/ChessPieces.sol";
import { ChessTypes } from "../src/types/ChessTypes.sol";

contract MintTestnet is Script {
    string internal constant METADATA_BASE =
        "ipfs://bafybeiegsqm3tlk4crff63c56yfagdidgv5lvsulfqrjsfqfebiowfjx3e/";

    function run() external {
        address admin = vm.envAddress("ADMIN");
        address chessPiecesAddress = vm.envAddress("CHESS_PIECES");

        ChessPieces chessPieces = ChessPieces(chessPiecesAddress);

        require(chessPieces.hasRole(chessPieces.MINTER_ROLE(), admin), "Wallet is not minter");

        // Safety check: Token #1 must already be our White Diamond Queen #1/1.
        require(chessPieces.ownerOf(1) == admin, "Token #1 owner mismatch");

        require(
            keccak256(bytes(chessPieces.tokenURI(1)))
                == keccak256(bytes(string.concat(METADATA_BASE, "diamond/white/queen/1.json"))),
            "Token #1 is not White Diamond Queen"
        );

        vm.startBroadcast();

        // Token #2
        _mint(
            chessPieces,
            admin,
            "bronze/white/pawn/1.json",
            ChessTypes.PieceType.Pawn,
            ChessTypes.Side.White,
            ChessTypes.Material.Bronze,
            ChessTypes.Rarity.Common
        );

        // Token #3
        _mint(
            chessPieces,
            admin,
            "bronze/black/pawn/1.json",
            ChessTypes.PieceType.Pawn,
            ChessTypes.Side.Black,
            ChessTypes.Material.Bronze,
            ChessTypes.Rarity.Common
        );

        // Token #4
        _mint(
            chessPieces,
            admin,
            "silver/white/knight/1.json",
            ChessTypes.PieceType.Knight,
            ChessTypes.Side.White,
            ChessTypes.Material.Silver,
            ChessTypes.Rarity.Rare
        );

        // Token #5
        _mint(
            chessPieces,
            admin,
            "silver/black/knight/1.json",
            ChessTypes.PieceType.Knight,
            ChessTypes.Side.Black,
            ChessTypes.Material.Silver,
            ChessTypes.Rarity.Rare
        );

        // Token #6
        _mint(
            chessPieces,
            admin,
            "gold/white/bishop/1.json",
            ChessTypes.PieceType.Bishop,
            ChessTypes.Side.White,
            ChessTypes.Material.Gold,
            ChessTypes.Rarity.VeryRare
        );

        // Token #7
        _mint(
            chessPieces,
            admin,
            "gold/black/bishop/1.json",
            ChessTypes.PieceType.Bishop,
            ChessTypes.Side.Black,
            ChessTypes.Material.Gold,
            ChessTypes.Rarity.VeryRare
        );

        // Token #8
        _mint(
            chessPieces,
            admin,
            "platinum/white/rook/1.json",
            ChessTypes.PieceType.Rook,
            ChessTypes.Side.White,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.VeryRare
        );

        // Token #9
        _mint(
            chessPieces,
            admin,
            "platinum/black/rook/1.json",
            ChessTypes.PieceType.Rook,
            ChessTypes.Side.Black,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.VeryRare
        );

        // Token #10
        _mint(
            chessPieces,
            admin,
            "diamond/black/queen/1.json",
            ChessTypes.PieceType.Queen,
            ChessTypes.Side.Black,
            ChessTypes.Material.Diamond,
            ChessTypes.Rarity.Mythic
        );

        // Token #11
        _mint(
            chessPieces,
            admin,
            "diamond/white/king/1.json",
            ChessTypes.PieceType.King,
            ChessTypes.Side.White,
            ChessTypes.Material.Diamond,
            ChessTypes.Rarity.Mythic
        );

        // Token #12
        _mint(
            chessPieces,
            admin,
            "diamond/black/king/1.json",
            ChessTypes.PieceType.King,
            ChessTypes.Side.Black,
            ChessTypes.Material.Diamond,
            ChessTypes.Rarity.Mythic
        );

        // Tokens #13 and #14 — order is important: #1/2 then #2/2.
        _mint(
            chessPieces,
            admin,
            "platinum/white/queen/1.json",
            ChessTypes.PieceType.Queen,
            ChessTypes.Side.White,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.Mythic
        );

        _mint(
            chessPieces,
            admin,
            "platinum/white/queen/2.json",
            ChessTypes.PieceType.Queen,
            ChessTypes.Side.White,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.Mythic
        );

        // Tokens #15 and #16 — order is important: #1/2 then #2/2.
        _mint(
            chessPieces,
            admin,
            "platinum/black/king/1.json",
            ChessTypes.PieceType.King,
            ChessTypes.Side.Black,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.Mythic
        );

        _mint(
            chessPieces,
            admin,
            "platinum/black/king/2.json",
            ChessTypes.PieceType.King,
            ChessTypes.Side.Black,
            ChessTypes.Material.Platinum,
            ChessTypes.Rarity.Mythic
        );

        // Token #17
        _mint(
            chessPieces,
            admin,
            "diamond/white/pawn/1.json",
            ChessTypes.PieceType.Pawn,
            ChessTypes.Side.White,
            ChessTypes.Material.Diamond,
            ChessTypes.Rarity.Common
        );

        // Token #18
        _mint(
            chessPieces,
            admin,
            "diamond/black/knight/1.json",
            ChessTypes.PieceType.Knight,
            ChessTypes.Side.Black,
            ChessTypes.Material.Diamond,
            ChessTypes.Rarity.Rare
        );

        // Token #19
        _mint(
            chessPieces,
            admin,
            "silver/white/bishop/1.json",
            ChessTypes.PieceType.Bishop,
            ChessTypes.Side.White,
            ChessTypes.Material.Silver,
            ChessTypes.Rarity.VeryRare
        );

        // Token #20
        _mint(
            chessPieces,
            admin,
            "gold/black/rook/1.json",
            ChessTypes.PieceType.Rook,
            ChessTypes.Side.Black,
            ChessTypes.Material.Gold,
            ChessTypes.Rarity.VeryRare
        );

        vm.stopBroadcast();

        console2.log("Testnet collection mint sequence complete");
    }

    function _mint(
        ChessPieces chessPieces,
        address recipient,
        string memory metadataPath,
        ChessTypes.PieceType pieceType,
        ChessTypes.Side side,
        ChessTypes.Material material,
        ChessTypes.Rarity rarity
    ) internal {
        uint256 tokenId = chessPieces.mint(
            recipient,
            string.concat(METADATA_BASE, metadataPath),
            ChessTypes.PieceData({
                pieceType: pieceType, side: side, material: material, rarity: rarity, season: 1
            })
        );

        console2.log("Minted token ID:", tokenId);
    }
}
