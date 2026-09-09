// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ChessTypes } from "../types/ChessTypes.sol";

/// @title Season1Catalog
/// @notice Defines all official collectible series for Season 1.
library Season1Catalog {
    uint16 internal constant SEASON = 1;

    struct SeriesConfig {
        ChessTypes.PieceData data;
        uint64 maxSupply;
    }

    /// @notice Returns all 60 official Season 1 series.
    function series() internal pure returns (SeriesConfig[] memory configs) {
        configs = new SeriesConfig[](60);

        uint256 index = 0;

        // -------------------------------------------------
        // Bronze
        // Pawn 500
        // Knight 100
        // Bishop 25
        // Rook 25
        // Queen 5
        // King 5
        // -------------------------------------------------

        index = _addMaterial(configs, index, ChessTypes.Material.Bronze, 500, 100, 25, 25, 5, 5);

        // -------------------------------------------------
        // Silver
        // -------------------------------------------------

        index = _addMaterial(configs, index, ChessTypes.Material.Silver, 400, 80, 20, 20, 4, 4);

        // -------------------------------------------------
        // Gold
        // -------------------------------------------------

        index = _addMaterial(configs, index, ChessTypes.Material.Gold, 300, 60, 15, 15, 3, 3);

        // -------------------------------------------------
        // Platinum
        // -------------------------------------------------

        index = _addMaterial(configs, index, ChessTypes.Material.Platinum, 200, 40, 10, 10, 2, 2);

        // -------------------------------------------------
        // Diamond
        // -------------------------------------------------

        index = _addMaterial(configs, index, ChessTypes.Material.Diamond, 100, 20, 5, 5, 1, 1);

        assert(index == 60);
    }

    function _addMaterial(
        SeriesConfig[] memory configs,
        uint256 index,
        ChessTypes.Material material,
        uint64 pawnSupply,
        uint64 knightSupply,
        uint64 bishopSupply,
        uint64 rookSupply,
        uint64 queenSupply,
        uint64 kingSupply
    ) private pure returns (uint256) {
        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.Pawn,
            material,
            ChessTypes.Rarity.Common,
            pawnSupply
        );

        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.Knight,
            material,
            ChessTypes.Rarity.Rare,
            knightSupply
        );

        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.Bishop,
            material,
            ChessTypes.Rarity.VeryRare,
            bishopSupply
        );

        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.Rook,
            material,
            ChessTypes.Rarity.VeryRare,
            rookSupply
        );

        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.Queen,
            material,
            ChessTypes.Rarity.Mythic,
            queenSupply
        );

        index = _addPair(
            configs,
            index,
            ChessTypes.PieceType.King,
            material,
            ChessTypes.Rarity.Mythic,
            kingSupply
        );

        return index;
    }

    function _addPair(
        SeriesConfig[] memory configs,
        uint256 index,
        ChessTypes.PieceType pieceType,
        ChessTypes.Material material,
        ChessTypes.Rarity rarity,
        uint64 maxSupply
    ) private pure returns (uint256) {
        configs[index] = SeriesConfig({
            data: ChessTypes.PieceData({
                pieceType: pieceType,
                side: ChessTypes.Side.White,
                material: material,
                rarity: rarity,
                season: SEASON
            }),
            maxSupply: maxSupply
        });

        configs[index + 1] = SeriesConfig({
            data: ChessTypes.PieceData({
                pieceType: pieceType,
                side: ChessTypes.Side.Black,
                material: material,
                rarity: rarity,
                season: SEASON
            }),
            maxSupply: maxSupply
        });

        return index + 2;
    }
}
