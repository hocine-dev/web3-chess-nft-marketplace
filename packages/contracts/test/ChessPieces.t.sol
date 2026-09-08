// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";

import { ChessPieces } from "../src/ChessPieces.sol";
import { ChessTypes } from "../src/types/ChessTypes.sol";

contract ChessPiecesTest is Test {
    ChessPieces internal chessPieces;

    address internal admin = address(0xA11CE);
    address internal collector = address(0xB0B);
    address internal attacker = address(0xBAD);

    function setUp() public {
        chessPieces = new ChessPieces(admin);
    }

    function _genesisGoldKnight() internal pure returns (ChessTypes.PieceData memory) {
        return ChessTypes.PieceData({
            pieceType: ChessTypes.PieceType.Knight,
            side: ChessTypes.Side.White,
            material: ChessTypes.Material.Gold,
            rarity: ChessTypes.Rarity.Rare,
            season: 1
        });
    }

    function testAdminHasMinterRole() public view {
        assertTrue(chessPieces.hasRole(chessPieces.MINTER_ROLE(), admin));
    }

    function testMintGenesisGoldKnight() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://genesis-gold-knight.json", data);

        assertEq(tokenId, 1);
        assertEq(chessPieces.ownerOf(1), collector);

        assertEq(chessPieces.tokenURI(1), "ipfs://genesis-gold-knight.json");
    }

    function testPieceDataStoredOnChain() public {
        ChessTypes.PieceData memory input = _genesisGoldKnight();

        vm.prank(admin);

        chessPieces.mint(collector, "ipfs://genesis-gold-knight.json", input);

        ChessTypes.PieceData memory stored = chessPieces.pieceData(1);

        assertEq(uint256(stored.pieceType), uint256(ChessTypes.PieceType.Knight));

        assertEq(uint256(stored.side), uint256(ChessTypes.Side.White));

        assertEq(uint256(stored.material), uint256(ChessTypes.Material.Gold));

        assertEq(uint256(stored.rarity), uint256(ChessTypes.Rarity.Rare));

        assertEq(stored.season, 1);
    }

    function testNextTokenIdIncrements() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        vm.startPrank(admin);

        chessPieces.mint(collector, "ipfs://piece-1.json", data);

        chessPieces.mint(collector, "ipfs://piece-2.json", data);

        vm.stopPrank();

        assertEq(chessPieces.nextTokenId(), 3);

        assertEq(chessPieces.ownerOf(1), collector);

        assertEq(chessPieces.ownerOf(2), collector);
    }

    function testNonMinterCannotMint() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        vm.prank(attacker);

        vm.expectRevert();

        chessPieces.mint(attacker, "ipfs://fake-piece.json", data);
    }

    function testCannotMintWithEmptyURI() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        vm.prank(admin);

        vm.expectRevert(ChessPieces.EmptyTokenURI.selector);

        chessPieces.mint(collector, "", data);
    }

    function testCannotMintWithSeasonZero() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        data.season = 0;

        vm.prank(admin);

        vm.expectRevert(ChessPieces.InvalidSeason.selector);

        chessPieces.mint(collector, "ipfs://invalid-season.json", data);
    }

    function testPieceDataRevertsForNonexistentToken() public {
        vm.expectRevert();

        chessPieces.pieceData(999);
    }

    function testERC721TransferKeepsPieceData() public {
        ChessTypes.PieceData memory input = _genesisGoldKnight();

        vm.prank(admin);

        chessPieces.mint(collector, "ipfs://genesis-gold-knight.json", input);

        vm.prank(collector);

        chessPieces.transferFrom(collector, attacker, 1);

        assertEq(chessPieces.ownerOf(1), attacker);

        ChessTypes.PieceData memory stored = chessPieces.pieceData(1);

        assertEq(uint256(stored.pieceType), uint256(ChessTypes.PieceType.Knight));

        assertEq(uint256(stored.material), uint256(ChessTypes.Material.Gold));

        assertEq(stored.season, 1);
    }
}
