// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {
    ERC721URIStorage
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ChessTypes } from "./types/ChessTypes.sol";
import { ISupplyPolicy } from "./interfaces/ISupplyPolicy.sol";

/// @title ChessPieces
/// @notice ERC-721 contract representing unique Web3 chess collectibles.
contract ChessPieces is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _nextTokenId = 1;

    ISupplyPolicy public immutable supplyPolicy;

    mapping(uint256 tokenId => ChessTypes.PieceData data) private _pieceData;

    mapping(uint256 tokenId => ChessTypes.EditionData data) private _editionData;

    error InvalidAdmin();
    error InvalidSupplyPolicy();
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

    constructor(address initialAdmin, ISupplyPolicy initialSupplyPolicy)
        ERC721("Web3 Chess Collectibles", "W3CHESS")
    {
        if (initialAdmin == address(0)) {
            revert InvalidAdmin();
        }

        if (address(initialSupplyPolicy) == address(0)) {
            revert InvalidSupplyPolicy();
        }

        supplyPolicy = initialSupplyPolicy;

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);

        _grantRole(MINTER_ROLE, initialAdmin);
    }

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

        (uint64 editionNumber, uint64 maxSupply) = supplyPolicy.consume(data);

        tokenId = _nextTokenId++;

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, uri);

        _pieceData[tokenId] = data;

        _editionData[tokenId] =
            ChessTypes.EditionData({ number: editionNumber, maxSupply: maxSupply });

        emit ChessPieceMinted(
            tokenId, to, data.pieceType, data.side, data.material, data.rarity, data.season, uri
        );
    }

    function editionData(uint256 tokenId) external view returns (ChessTypes.EditionData memory) {
        _requireOwned(tokenId);

        return _editionData[tokenId];
    }

    function pieceData(uint256 tokenId) external view returns (ChessTypes.PieceData memory) {
        _requireOwned(tokenId);

        return _pieceData[tokenId];
    }

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
