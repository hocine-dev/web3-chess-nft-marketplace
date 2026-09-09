// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ChessTypes } from "../types/ChessTypes.sol";

/// @title Season1Catalog
/// @notice Defines the official collectible series for Season 1.
library Season1Catalog {
    struct SeriesConfig {
        ChessTypes.PieceData data;
        uint64 maxSupply;
    }

    function series() internal pure returns (SeriesConfig[] memory configs) {
        configs = new SeriesConfig[](1);

        configs[0] = SeriesConfig({
            data: ChessTypes.PieceData({
                pieceType: ChessTypes.PieceType.Queen,
                side: ChessTypes.Side.White,
                material: ChessTypes.Material.Diamond,
                rarity: ChessTypes.Rarity.Mythic,
                season: 1
            }),
            maxSupply: 5
        });
    }
}
