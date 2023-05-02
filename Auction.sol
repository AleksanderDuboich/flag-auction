// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Auction {
    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public pendingReturns;

    bool public ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error NotEnoughEther();
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();

    constructor(uint biddingTime, address payable beneficiaryAddress) payable {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) revert AuctionAlreadyEnded();

        if (msg.value <= highestBid) revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function emergencyEnd() external payable {
        if (ended) revert AuctionEndAlreadyCalled();

        if (msg.value < 11000000 ether) revert NotEnoughEther();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (!payable(msg.sender).send(amount)) {
            return false;
        }
        return true;
    }

    function end() external {
        if (block.timestamp < auctionEndTime) revert AuctionNotYetEnded();
        if (ended) revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }

    receive() external payable {}

    fallback() external payable {}
}
