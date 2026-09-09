// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ChessTypes } from "../types/ChessTypes.sol";

interface ISupplyPolicy {
    function consume(ChessTypes.PieceData calldata data) external;

    function remainingSupply(ChessTypes.PieceData calldata data) external view returns (uint256);

    function seriesId(ChessTypes.PieceData calldata data) external pure returns (bytes32);
}
