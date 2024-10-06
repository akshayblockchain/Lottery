// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Helper} from "./Helper.s.sol";
import {Lottery} from "../src/Lottery.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscription() public returns (uint256, address) {
        Helper helper = new Helper();
        address vrfCoordinatorV2_5 = helper.getconfig().VRF_address;
        address account = helper.getconfig().account;
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5)
            .createSubscription();
        vm.stopBroadcast();
        return (subId, vrfCoordinatorV2_5);
    }

    function run() external returns (uint256, address) {
        return createSubscription();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractAddVrf) public {
        Helper helper = new Helper();
        uint256 subId = helper.getconfig().subscriptionId;
        address vrfCoordinatorV2_5 = helper.getconfig().VRF_address;
        address account = helper.getconfig().account;
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(
            subId,
            contractAddVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        addConsumer(mostRecentlyDeployed);
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;
    uint96 public constant LOCAL_CHAIN_ID = 31337;
    function fundSubscription() public {
        Helper helper = new Helper();
        uint256 subId = helper.getconfig().subscriptionId;
        address vrfCoordinatorV2_5 = helper.getconfig().VRF_address;
        address account = helper.getconfig().account;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
        }
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscription();
    }
}
