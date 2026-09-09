// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";

import { ChessPieces } from "../src/ChessPieces.sol";
import { SupplyPolicy } from "../src/SupplyPolicy.sol";
import { ISupplyPolicy } from "../src/interfaces/ISupplyPolicy.sol";
import { ChessTypes } from "../src/types/ChessTypes.sol";

contract ChessPiecesTest is Test {
    ChessPieces internal chessPieces;
    SupplyPolicy internal supplyPolicy;

    address internal admin = address(0xA11CE);
    address internal collector = address(0xB0B);
    address internal buyer = address(0xCAFE);
    address internal attacker = address(0xBAD);

    function setUp() public {
        supplyPolicy = new SupplyPolicy(admin);

        chessPieces = new ChessPieces(admin, ISupplyPolicy(address(supplyPolicy)));

        // ChessPieces itself must be allowed to consume supply.
        vm.startPrank(admin);

        supplyPolicy.grantRole(supplyPolicy.CONSUMER_ROLE(), address(chessPieces));

        vm.stopPrank();
    }

    // -------------------------------------------------
    // Fixtures
    // -------------------------------------------------

    function _genesisGoldKnight() internal pure returns (ChessTypes.PieceData memory) {
        return ChessTypes.PieceData({
            pieceType: ChessTypes.PieceType.Knight,
            side: ChessTypes.Side.White,
            material: ChessTypes.Material.Gold,
            rarity: ChessTypes.Rarity.Rare,
            season: 1
        });
    }

    function _diamondQueen() internal pure returns (ChessTypes.PieceData memory) {
        return ChessTypes.PieceData({
            pieceType: ChessTypes.PieceType.Queen,
            side: ChessTypes.Side.White,
            material: ChessTypes.Material.Diamond,
            rarity: ChessTypes.Rarity.Mythic,
            season: 1
        });
    }

    function _configureSeries(ChessTypes.PieceData memory data, uint64 maxSupply) internal {
        vm.prank(admin);

        supplyPolicy.configureSeries(data, maxSupply);
    }

    // -------------------------------------------------
    // Roles / constructor
    // -------------------------------------------------

    function testAdminHasMinterRole() public view {
        assertTrue(chessPieces.hasRole(chessPieces.MINTER_ROLE(), admin));
    }

    function testChessPiecesHasConsumerRole() public view {
        assertTrue(supplyPolicy.hasRole(supplyPolicy.CONSUMER_ROLE(), address(chessPieces)));
    }

    function testCannotDeployWithInvalidSupplyPolicy() public {
        vm.expectRevert(ChessPieces.InvalidSupplyPolicy.selector);

        new ChessPieces(admin, ISupplyPolicy(address(0)));
    }

    // -------------------------------------------------
    // Mint validation
    // -------------------------------------------------

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

        chessPieces.mint(collector, "ipfs://test.json", data);
    }

    function testNonMinterCannotMint() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        _configureSeries(data, 10);

        vm.prank(attacker);

        vm.expectRevert();

        chessPieces.mint(collector, "ipfs://test.json", data);
    }

    // -------------------------------------------------
    // Normal mint
    // -------------------------------------------------

    function testMintGenesisGoldKnight() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        _configureSeries(data, 100);

        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://test/genesis-gold-knight.json", data);

        assertEq(tokenId, 1);

        assertEq(chessPieces.ownerOf(tokenId), collector);

        assertEq(chessPieces.tokenURI(tokenId), "ipfs://test/genesis-gold-knight.json");
    }

    function testPieceDataStoredOnChain() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        _configureSeries(data, 10);

        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://test.json", data);

        ChessTypes.PieceData memory stored = chessPieces.pieceData(tokenId);

        assertEq(uint8(stored.pieceType), uint8(ChessTypes.PieceType.Knight));

        assertEq(uint8(stored.side), uint8(ChessTypes.Side.White));

        assertEq(uint8(stored.material), uint8(ChessTypes.Material.Gold));

        assertEq(uint8(stored.rarity), uint8(ChessTypes.Rarity.Rare));

        assertEq(stored.season, 1);
    }

    function testERC721TransferKeepsPieceData() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        _configureSeries(data, 10);

        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://test.json", data);

        vm.prank(collector);

        chessPieces.transferFrom(collector, buyer, tokenId);

        assertEq(chessPieces.ownerOf(tokenId), buyer);

        ChessTypes.PieceData memory stored = chessPieces.pieceData(tokenId);

        assertEq(uint8(stored.material), uint8(ChessTypes.Material.Gold));

        assertEq(stored.season, 1);
    }

    function testNextTokenIdIncrements() public {
        ChessTypes.PieceData memory data = _genesisGoldKnight();

        _configureSeries(data, 10);

        vm.startPrank(admin);

        chessPieces.mint(collector, "ipfs://1.json", data);

        chessPieces.mint(collector, "ipfs://2.json", data);

        vm.stopPrank();

        assertEq(chessPieces.nextTokenId(), 3);
    }

    function testPieceDataRevertsForNonexistentToken() public {
        vm.expectRevert();

        chessPieces.pieceData(999);
    }

    // -------------------------------------------------
    // SupplyPolicy integration
    // -------------------------------------------------

    function testMintConsumesSupply() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        _configureSeries(data, 5);

        assertEq(supplyPolicy.remainingSupply(data), 5);

        vm.prank(admin);

        chessPieces.mint(collector, "ipfs://diamond-queen-1.json", data);

        SupplyPolicy.SeriesPolicy memory policy = supplyPolicy.policyOf(data);

        assertEq(policy.minted, 1);

        assertEq(supplyPolicy.remainingSupply(data), 4);
    }

    function testCannotMintUnconfiguredSeries() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        bytes32 id = supplyPolicy.seriesId(data);

        vm.startPrank(admin);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SeriesNotConfigured.selector, id));

        chessPieces.mint(collector, "ipfs://diamond-queen.json", data);

        vm.stopPrank();
    }

    function testCannotMintBeyondSeriesMaxSupply() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        _configureSeries(data, 5);

        vm.startPrank(admin);

        chessPieces.mint(collector, "ipfs://diamond-queen-1.json", data);

        chessPieces.mint(collector, "ipfs://diamond-queen-2.json", data);

        chessPieces.mint(collector, "ipfs://diamond-queen-3.json", data);

        chessPieces.mint(collector, "ipfs://diamond-queen-4.json", data);

        chessPieces.mint(collector, "ipfs://diamond-queen-5.json", data);

        vm.stopPrank();

        assertEq(supplyPolicy.remainingSupply(data), 0);

        assertEq(chessPieces.nextTokenId(), 6);

        bytes32 id = supplyPolicy.seriesId(data);

        vm.startPrank(admin);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SupplyExceeded.selector, id, 5, 5));

        chessPieces.mint(collector, "ipfs://diamond-queen-6.json", data);

        vm.stopPrank();

        // No NFT #6 was created.
        assertEq(chessPieces.nextTokenId(), 6);

        assertEq(supplyPolicy.remainingSupply(data), 0);
    }

    /*
     * Important:
     * Do NOT call this test "testFailed..."
     * because Foundry interprets "testFail*" as
     * the old removed testFail convention.
     */
    function testMintFailureDoesNotConsumeSupply() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        _configureSeries(data, 1);

        vm.startPrank(admin);

        /*
         * address(this) is a contract that does not accept
         * ERC-721 safe transfers, so _safeMint() reverts.
         */
        vm.expectRevert();

        chessPieces.mint(address(this), "ipfs://failed-mint.json", data);

        vm.stopPrank();

        /*
         * SupplyPolicy.consume() happened before _safeMint(),
         * but because the transaction reverted, the whole
         * transaction was rolled back.
         */
        assertEq(supplyPolicy.remainingSupply(data), 1);

        assertEq(chessPieces.nextTokenId(), 1);
    }

    function testFirstMintGetsEditionOne() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        _configureSeries(data, 5);

        vm.prank(admin);

        uint256 tokenId = chessPieces.mint(collector, "ipfs://queen-1.json", data);

        ChessTypes.EditionData memory edition = chessPieces.editionData(tokenId);

        assertEq(edition.number, 1);

        assertEq(edition.maxSupply, 5);
    }

    function testEditionNumberIncrements() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        _configureSeries(data, 5);

        vm.startPrank(admin);

        uint256 tokenId1 = chessPieces.mint(collector, "ipfs://queen-1.json", data);

        uint256 tokenId2 = chessPieces.mint(collector, "ipfs://queen-2.json", data);

        uint256 tokenId3 = chessPieces.mint(collector, "ipfs://queen-3.json", data);

        vm.stopPrank();

        ChessTypes.EditionData memory edition1 = chessPieces.editionData(tokenId1);

        ChessTypes.EditionData memory edition2 = chessPieces.editionData(tokenId2);

        ChessTypes.EditionData memory edition3 = chessPieces.editionData(tokenId3);

        assertEq(edition1.number, 1);

        assertEq(edition2.number, 2);

        assertEq(edition3.number, 3);

        assertEq(edition1.maxSupply, 5);

        assertEq(edition2.maxSupply, 5);

        assertEq(edition3.maxSupply, 5);
    }

    function testDifferentSeriesHaveIndependentEditionNumbers() public {
        ChessTypes.PieceData memory queen = _diamondQueen();

        ChessTypes.PieceData memory knight = _genesisGoldKnight();

        _configureSeries(queen, 5);

        _configureSeries(knight, 100);

        vm.startPrank(admin);

        uint256 queen1 = chessPieces.mint(collector, "ipfs://queen-1.json", queen);

        uint256 queen2 = chessPieces.mint(collector, "ipfs://queen-2.json", queen);

        uint256 knight1 = chessPieces.mint(collector, "ipfs://knight-1.json", knight);

        vm.stopPrank();

        ChessTypes.EditionData memory queenEdition1 = chessPieces.editionData(queen1);

        ChessTypes.EditionData memory queenEdition2 = chessPieces.editionData(queen2);

        ChessTypes.EditionData memory knightEdition1 = chessPieces.editionData(knight1);

        assertEq(queenEdition1.number, 1);

        assertEq(queenEdition2.number, 2);

        assertEq(knightEdition1.number, 1);
    }
}
