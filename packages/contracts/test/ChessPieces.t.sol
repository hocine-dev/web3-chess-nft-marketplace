// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { ChessPieces } from "../src/ChessPieces.sol";

contract ChessPiecesTest is Test {
    ChessPieces internal chessPieces;

    address internal admin = address(0xA11CE);
    address internal collector = address(0xB0B);
    address internal attacker = address(0xBAD);

    function setUp() public {
        chessPieces = new ChessPieces(admin);
    }

    function testAdminHasMinterRole() public view {
        assertTrue(chessPieces.hasRole(chessPieces.MINTER_ROLE(), admin));
    }

    function testMintFirstChessPiece() public {
        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://genesis-gold-knight.json");

        assertEq(tokenId, 1);
        assertEq(chessPieces.ownerOf(1), collector);
        assertEq(chessPieces.tokenURI(1), "ipfs://genesis-gold-knight.json");
    }

    function testNextTokenIdIncrements() public {
        vm.startPrank(admin);

        chessPieces.mint(collector, "ipfs://piece-1.json");

        chessPieces.mint(collector, "ipfs://piece-2.json");

        vm.stopPrank();

        assertEq(chessPieces.nextTokenId(), 3);
        assertEq(chessPieces.ownerOf(1), collector);
        assertEq(chessPieces.ownerOf(2), collector);
    }

    function testNonMinterCannotMint() public {
        vm.prank(attacker);

        vm.expectRevert();

        chessPieces.mint(attacker, "ipfs://fake-piece.json");
    }

    function testCannotMintWithEmptyURI() public {
        vm.prank(admin);

        vm.expectRevert(ChessPieces.EmptyTokenURI.selector);

        chessPieces.mint(collector, "");
    }

    function testERC721TransferWorks() public {
        vm.prank(admin);

        chessPieces.mint(collector, "ipfs://genesis-gold-knight.json");

        vm.prank(collector);

        chessPieces.transferFrom(collector, attacker, 1);

        assertEq(chessPieces.ownerOf(1), attacker);
    }
}
