// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library ChessTypes {
    enum PieceType {
        Pawn,
        Knight,
        Bishop,
        Rook,
        Queen,
        King
    }

    enum Side {
        White,
        Black
    }

    enum Material {
        Bronze,
        Silver,
        Gold,
        Platinum,
        Diamond
    }

    enum Rarity {
        Common,
        Rare,
        VeryRare,
        Mythic
    }

    struct PieceData {
        PieceType pieceType;
        Side side;
        Material material;
        Rarity rarity;
        uint16 season;
    }
}
