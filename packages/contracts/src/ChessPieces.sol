// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {
    ERC721URIStorage
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ChessTypes } from "./types/ChessTypes.sol";

/// @title ChessPieces
/// @notice ERC-721 contract representing unique Web3 chess collectibles.
contract ChessPieces is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _nextTokenId = 1;

    mapping(uint256 tokenId => ChessTypes.PieceData data) private _pieceData;

    error InvalidAdmin();
    error EmptyTokenURI();
    error InvalidSeason();

    event ChessPieceMinted(
        uint256 indexed tokenId,
        address indexed owner,
        ChessTypes.PieceType pieceType,
        ChessTypes.Side side,
        ChessTypes.Material material,
        ChessTypes.Rarity rarity,
        uint16 season,
        string tokenURI
    );

    constructor(address initialAdmin) ERC721("Web3 Chess Collectibles", "W3CHESS") {
        if (initialAdmin == address(0)) {
            revert InvalidAdmin();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
    }

    /// @notice Mints a new unique chess collectible.
    /// @param to Address receiving the NFT.
    /// @param uri Metadata URI associated with the collectible.
    /// @param data On-chain business characteristics of the chess piece.
    /// @return tokenId Identifier of the newly minted NFT.
    function mint(address to, string calldata uri, ChessTypes.PieceData calldata data)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        if (bytes(uri).length == 0) {
            revert EmptyTokenURI();
        }

        if (data.season == 0) {
            revert InvalidSeason();
        }

        tokenId = _nextTokenId++;

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, uri);

        _pieceData[tokenId] = data;

        emit ChessPieceMinted(
            tokenId, to, data.pieceType, data.side, data.material, data.rarity, data.season, uri
        );
    }

    /// @notice Returns the business characteristics of a collectible.
    /// @param tokenId NFT identifier.
    function pieceData(uint256 tokenId) external view returns (ChessTypes.PieceData memory) {
        _requireOwned(tokenId);

        return _pieceData[tokenId];
    }

    /// @notice Returns the ID that will be assigned to the next NFT.
    function nextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
