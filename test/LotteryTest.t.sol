// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {Test} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";
import {Helper} from "../script/Helper.s.sol";
import {DeployLottery} from "../script/DeployLottery.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    Helper public helper;
    uint256 public s_entryFee;

    event LotteryEntry(address indexed player);

    address public PLAYER = makeAddr("player");

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helper) = deployer.run();
        vm.deal(PLAYER, 10 ether);
        Helper.NetworkConfig memory config = helper.getconfig();
        s_entryFee = config.entryFee;
    }

    function testInitialStateIsOpen() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testLotteryRevertsWHenYouDontPayEnought() public {
        vm.prank(PLAYER);
        vm.expectRevert(Lottery.Lottery_NotEnoughEntryFee.selector);
        lottery.enterLottery();
    }

    function testlotteryRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value: s_entryFee}();
        address playersRecorded = lottery.getPlayer(0);
        assert(playersRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit LotteryEntry(PLAYER);
        lottery.enterLottery{value: s_entryFee}();
    }

    function testDontAllowPlayersToEnterWhileLotteryTime() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value: s_entryFee}();
        vm.warp(block.timestamp + 30 + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        vm.prank(PLAYER);
        vm.expectRevert(Lottery.Lottery_lotteryNotOpen.selector);
        lottery.enterLottery{value: s_entryFee}();
    }
}
