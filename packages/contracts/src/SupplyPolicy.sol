// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ChessTypes } from "./types/ChessTypes.sol";
import { ISupplyPolicy } from "./interfaces/ISupplyPolicy.sol";

/// @title SupplyPolicy
/// @notice Controls issuance limits for Web3 Chess collectible series.
contract SupplyPolicy is AccessControl, ISupplyPolicy {
    bytes32 public constant POLICY_MANAGER_ROLE = keccak256("POLICY_MANAGER_ROLE");

    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    struct SeriesPolicy {
        uint64 maxSupply;
        uint64 minted;
        ChessTypes.Rarity rarity;
        bool configured;
    }

    mapping(bytes32 seriesId => SeriesPolicy policy) private _policies;

    error InvalidAdmin();
    error InvalidSeason();
    error InvalidMaxSupply();

    error SeriesNotConfigured(bytes32 seriesId);

    error SupplyExceeded(bytes32 seriesId, uint256 minted, uint256 maxSupply);

    error SeriesAlreadyConfigured(bytes32 seriesId);
    error InvalidSeriesRarity(
        bytes32 seriesId, ChessTypes.Rarity expected, ChessTypes.Rarity provided
    );

    event SeriesPolicyConfigured(bytes32 indexed seriesId, uint64 maxSupply);

    event SupplyConsumed(bytes32 indexed seriesId, uint64 minted, uint64 maxSupply);

    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) {
            revert InvalidAdmin();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);

        _grantRole(POLICY_MANAGER_ROLE, initialAdmin);
    }

    /// @notice Computes the unique identifier of a collectible series.
    function seriesId(ChessTypes.PieceData calldata data) public pure override returns (bytes32) {
        return keccak256(
            abi.encode(data.season, uint8(data.pieceType), uint8(data.side), uint8(data.material))
        );
    }

    /// @notice Permanently defines the maximum supply of a series.
    /// @dev A series can only be configured once.
    function configureSeries(ChessTypes.PieceData calldata data, uint64 maxSupply)
        external
        onlyRole(POLICY_MANAGER_ROLE)
    {
        if (data.season == 0) {
            revert InvalidSeason();
        }

        if (maxSupply == 0) {
            revert InvalidMaxSupply();
        }

        bytes32 id = seriesId(data);

        SeriesPolicy storage policy = _policies[id];

        if (policy.configured) {
            revert SeriesAlreadyConfigured(id);
        }

        policy.maxSupply = maxSupply;
        policy.rarity = data.rarity;
        policy.configured = true;

        emit SeriesPolicyConfigured(id, maxSupply);
    }

    /// @notice Consumes one unit of supply.
    /// @dev Intended to be called by ChessPieces during minting.
    function consume(ChessTypes.PieceData calldata data)
        external
        override
        onlyRole(CONSUMER_ROLE)
        returns (uint64 editionNumber, uint64 maxSupply)
    {
        bytes32 id = seriesId(data);

        SeriesPolicy storage policy = _policies[id];

        if (!policy.configured) {
            revert SeriesNotConfigured(id);
        }

        if (data.rarity != policy.rarity) {
            revert InvalidSeriesRarity(id, policy.rarity, data.rarity);
        }

        if (policy.minted >= policy.maxSupply) {
            revert SupplyExceeded(id, policy.minted, policy.maxSupply);
        }

        policy.minted++;

        editionNumber = policy.minted;
        maxSupply = policy.maxSupply;

        emit SupplyConsumed(id, policy.minted, policy.maxSupply);
    }

    /// @notice Returns the complete supply information of a series.
    function policyOf(ChessTypes.PieceData calldata data)
        external
        view
        returns (SeriesPolicy memory)
    {
        return _policies[seriesId(data)];
    }

    /// @notice Returns how many collectibles can still be minted.
    function remainingSupply(ChessTypes.PieceData calldata data)
        external
        view
        override
        returns (uint256)
    {
        SeriesPolicy storage policy = _policies[seriesId(data)];

        if (!policy.configured) {
            return 0;
        }

        return uint256(policy.maxSupply) - uint256(policy.minted);
    }
}
