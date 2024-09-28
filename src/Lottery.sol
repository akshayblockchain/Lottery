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

contract Lottery{

    error Lottery_NotEnoughEntryFee();
    error Lottery_lotteryNotOpen();

    enum LotteryState{
        OPEN,
        LOTTERY_TIME    
    }

    uint private immutable i_entryFee;
    address payable[] private s_players;
    uint private immutable i_interval;
    LotteryState private s_lotteryState;

    event LotteryEntry(address indexed player);

    constructor(uint entryFee, uint interval){
        i_entryFee = entryFee;
        i_interval = interval;
        s_lotteryState = LotteryState.OPEN;
    }

    function enterLottery() public payable{
        if(msg.value < i_entryFee){
            revert Lottery_NotEnoughEntryFee();
        }
        if(s_lotteryState == LotteryState.LOTTERY_TIME){
            revert Lottery_lotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEntry(msg.sender);
    }

    
}