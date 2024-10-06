// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract Helper is Script {
    error Helper_InvalidChainId();
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant ANVIL_CHAIN_ID = 31337;

    struct NetworkConfig {
        uint256 entryFee;
        uint256 interval;
        address VRF_address;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callBackGasLimit;
        address account;
    }

    mapping(uint256 => NetworkConfig) networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    }

    function getconfig() external returns (NetworkConfig memory) {
        uint256 chainId = block.chainid;
        if (networkConfigs[chainId].VRF_address != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID) {
            return getAnvilVRFMOCKAndConfig();
        } else {
            revert Helper_InvalidChainId();
        }
    }

    function getSepoliaNetworkConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        NetworkConfig memory networkConfig = NetworkConfig({
            entryFee: 0.01 ether,
            interval: 30, //30 seconds
            VRF_address: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 0,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callBackGasLimit: 500000,
            account: 0x0cFBda0a71A3864CB108cd84b74D748eAcA49A36
        });
        return networkConfig;
    }

    function getAnvilVRFMOCKAndConfig()
        internal
        returns (NetworkConfig memory)
    {
        if (networkConfigs[block.chainid].VRF_address != address(0)) {
            return networkConfigs[block.chainid];
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UINT_LINK
            );
        uint256 subId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        NetworkConfig memory networkConfig = NetworkConfig({
            entryFee: 0.01 ether,
            interval: 30, //30 seconds
            VRF_address: address(vrfCoordinatorV2_5Mock),
            subscriptionId: subId,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callBackGasLimit: 500000,
            account: 0x0cFBda0a71A3864CB108cd84b74D748eAcA49A36
        });
        return networkConfig;
    }
}
