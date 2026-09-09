// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";

import { SupplyPolicy } from "../src/SupplyPolicy.sol";
import { ChessTypes } from "../src/types/ChessTypes.sol";

contract SupplyPolicyTest is Test {
    SupplyPolicy internal supplyPolicy;

    address internal admin = address(0xA11CE);
    address internal consumer = address(0xC0FFEE);
    address internal attacker = address(0xBAD);

    function setUp() public {
        supplyPolicy = new SupplyPolicy(admin);

        vm.startPrank(admin);

        supplyPolicy.grantRole(supplyPolicy.CONSUMER_ROLE(), consumer);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // Fixtures
    // -------------------------------------------------

    function _goldKnight() internal pure returns (ChessTypes.PieceData memory) {
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

    // -------------------------------------------------
    // Roles
    // -------------------------------------------------

    function testAdminHasPolicyManagerRole() public view {
        assertTrue(supplyPolicy.hasRole(supplyPolicy.POLICY_MANAGER_ROLE(), admin));
    }

    function testConsumerHasConsumerRole() public view {
        assertTrue(supplyPolicy.hasRole(supplyPolicy.CONSUMER_ROLE(), consumer));
    }

    // -------------------------------------------------
    // Series configuration
    // -------------------------------------------------

    function testConfigureSeries() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 5);

        SupplyPolicy.SeriesPolicy memory policy = supplyPolicy.policyOf(data);

        assertTrue(policy.configured);
        assertEq(policy.maxSupply, 5);
        assertEq(policy.minted, 0);

        assertEq(supplyPolicy.remainingSupply(data), 5);
    }

    function testCannotConfigureSeriesTwice() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 5);

        bytes32 id = supplyPolicy.seriesId(data);

        vm.prank(admin);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SeriesAlreadyConfigured.selector, id));

        supplyPolicy.configureSeries(data, 20);
    }

    function testCannotDecreaseSupplyAfterConfiguration() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 5);

        bytes32 id = supplyPolicy.seriesId(data);

        vm.prank(admin);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SeriesAlreadyConfigured.selector, id));

        supplyPolicy.configureSeries(data, 2);
    }

    function testCannotConfigureSeasonZero() public {
        ChessTypes.PieceData memory data = _goldKnight();

        data.season = 0;

        vm.prank(admin);

        vm.expectRevert(SupplyPolicy.InvalidSeason.selector);

        supplyPolicy.configureSeries(data, 100);
    }

    function testCannotConfigureZeroSupply() public {
        ChessTypes.PieceData memory data = _goldKnight();

        vm.prank(admin);

        vm.expectRevert(SupplyPolicy.InvalidMaxSupply.selector);

        supplyPolicy.configureSeries(data, 0);
    }

    function testUnauthorizedWalletCannotConfigureSeries() public {
        ChessTypes.PieceData memory data = _goldKnight();

        vm.prank(attacker);

        vm.expectRevert();

        supplyPolicy.configureSeries(data, 100);
    }

    // -------------------------------------------------
    // Supply consumption
    // -------------------------------------------------

    function testConsumeSupply() public {
        ChessTypes.PieceData memory data = _goldKnight();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 2);

        vm.prank(consumer);

        supplyPolicy.consume(data);

        SupplyPolicy.SeriesPolicy memory policy = supplyPolicy.policyOf(data);

        assertEq(policy.maxSupply, 2);
        assertEq(policy.minted, 1);

        assertEq(supplyPolicy.remainingSupply(data), 1);
    }

    function testConsumeUntilSupplyIsExhausted() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 5);

        vm.startPrank(consumer);

        supplyPolicy.consume(data);
        supplyPolicy.consume(data);
        supplyPolicy.consume(data);
        supplyPolicy.consume(data);
        supplyPolicy.consume(data);

        vm.stopPrank();

        SupplyPolicy.SeriesPolicy memory policy = supplyPolicy.policyOf(data);

        assertEq(policy.maxSupply, 5);
        assertEq(policy.minted, 5);

        assertEq(supplyPolicy.remainingSupply(data), 0);
    }

    function testCannotExceedMaxSupply() public {
        ChessTypes.PieceData memory data = _diamondQueen();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 2);

        vm.startPrank(consumer);

        supplyPolicy.consume(data);
        supplyPolicy.consume(data);

        bytes32 id = supplyPolicy.seriesId(data);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SupplyExceeded.selector, id, 2, 2));

        supplyPolicy.consume(data);

        vm.stopPrank();
    }

    function testCannotConsumeUnconfiguredSeries() public {
        ChessTypes.PieceData memory data = _goldKnight();

        bytes32 id = supplyPolicy.seriesId(data);

        vm.prank(consumer);

        vm.expectRevert(abi.encodeWithSelector(SupplyPolicy.SeriesNotConfigured.selector, id));

        supplyPolicy.consume(data);
    }

    function testUnauthorizedWalletCannotConsume() public {
        ChessTypes.PieceData memory data = _goldKnight();

        vm.prank(admin);

        supplyPolicy.configureSeries(data, 10);

        vm.prank(attacker);

        vm.expectRevert();

        supplyPolicy.consume(data);
    }

    // -------------------------------------------------
    // Series isolation
    // -------------------------------------------------

    function testDifferentSeriesHaveIndependentSupply() public {
        ChessTypes.PieceData memory goldKnight = _goldKnight();

        ChessTypes.PieceData memory diamondQueen = _diamondQueen();

        vm.startPrank(admin);

        supplyPolicy.configureSeries(goldKnight, 100);

        supplyPolicy.configureSeries(diamondQueen, 5);

        vm.stopPrank();

        vm.startPrank(consumer);

        supplyPolicy.consume(goldKnight);

        supplyPolicy.consume(diamondQueen);

        supplyPolicy.consume(diamondQueen);

        vm.stopPrank();

        assertEq(supplyPolicy.remainingSupply(goldKnight), 99);

        assertEq(supplyPolicy.remainingSupply(diamondQueen), 3);
    }

    // -------------------------------------------------
    // Series ID
    // -------------------------------------------------

    function testSameDataProducesSameSeriesId() public view {
        ChessTypes.PieceData memory data1 = _goldKnight();

        ChessTypes.PieceData memory data2 = _goldKnight();

        assertEq(supplyPolicy.seriesId(data1), supplyPolicy.seriesId(data2));
    }

    function testDifferentDataProducesDifferentSeriesId() public view {
        ChessTypes.PieceData memory goldKnight = _goldKnight();

        ChessTypes.PieceData memory diamondQueen = _diamondQueen();

        assertNotEq(supplyPolicy.seriesId(goldKnight), supplyPolicy.seriesId(diamondQueen));
    }

    function testUnconfiguredSeriesHasZeroRemainingSupply() public view {
        ChessTypes.PieceData memory data = _goldKnight();

        assertEq(supplyPolicy.remainingSupply(data), 0);
    }
}
