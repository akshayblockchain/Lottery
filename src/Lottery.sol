// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    error Lottery_NotEnoughEntryFee();
    error Lottery_lotteryNotOpen();
    error Lottery_TransferFailed();

    enum LotteryState {
        OPEN,
        LOTTERY_TIME
    }

    uint256 private immutable i_entryFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    address payable private s_recentWinner;
    uint256 private s_lastLotteryTime;
    LotteryState private s_lotteryState;
    bytes32 private s_keyHash;
    uint32 private s_callBackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_subscriptionId;

    event LotteryEntry(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entryFee,
        uint256 interval,
        address VRF_address,
        uint256 subscriptionId,
        bytes32 keyHash,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2Plus(VRF_address) {
        i_entryFee = entryFee;
        i_interval = interval;
        s_lotteryState = LotteryState.OPEN;
        i_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callBackGasLimit = callBackGasLimit;
        s_lastLotteryTime = block.timestamp;
    }

    function enterLottery() public payable {
        if (msg.value < i_entryFee) {
            revert Lottery_NotEnoughEntryFee();
        }
        if (s_lotteryState == LotteryState.LOTTERY_TIME) {
            revert Lottery_lotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEntry(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool lotteryOpen = LotteryState.OPEN == s_lotteryState;
        bool timeDone = ((block.timestamp - s_lastLotteryTime) > i_interval);
        bool playersLength = s_players.length > 0;
        bool lotteryBalance = address(this).balance > 0;
        upkeepNeeded = (lotteryOpen &&
            timeDone &&
            playersLength &&
            lotteryBalance);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - s_lastLotteryTime) > i_interval) {
            requestRandomWords();
        }
    }

    function requestRandomWords() public {
        s_lotteryState = LotteryState.LOTTERY_TIME;
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: s_callBackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] calldata _randomWords
    ) internal override {
        uint winnerIndex = _randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastLotteryTime = block.timestamp;
        emit WinnerPicked(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery_TransferFailed();
        }
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getPlayer(uint index) public view returns (address) {
        return s_players[index];
    }
}
