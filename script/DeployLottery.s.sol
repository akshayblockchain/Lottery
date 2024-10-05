// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {Helper} from "./Helper.s.sol";

// struct NetworkConfig {
//         uint256 entryFee;
//         uint256 interval;
//         address VRF_address;
//         uint256 subscriptionId;
//         bytes32 keyHash;
//         uint32 callBackGasLimit;
//     }
contract DeployLottery is Script {
    function run() external returns (Lottery, Helper) {
        Helper helper = new Helper();
        Helper.NetworkConfig memory config = helper.getconfig();
        vm.startBroadcast();
        Lottery lottery = new Lottery(
            config.entryFee,
            config.interval,
            config.VRF_address,
            config.subscriptionId,
            config.keyHash,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
        return (lottery, helper);
    }
}
