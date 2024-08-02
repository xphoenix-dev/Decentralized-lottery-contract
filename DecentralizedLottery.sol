// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DecentralizedLottery is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Chainlink VRF Variables
    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;

    struct Lottery {
        uint256 lotteryId;
        address[] participants;
        uint256 ticketPrice;
        uint256 prizePool;
        bool isActive;
        address winner;
    }

    uint256 public lotteryCount;
    mapping(uint256 => Lottery) public lotteries;
    mapping(uint256 => uint256) public lotteryToRequestId;

    event LotteryCreated(uint256 lotteryId, uint256 ticketPrice);
    event TicketPurchased(uint256 lotteryId, address indexed participant);
    event WinnerDeclared(uint256 lotteryId, address indexed winner, uint256 prize);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        subscriptionId = _subscriptionId;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function createLottery(uint256 ticketPrice) external {
        require(ticketPrice > 0, "Ticket price must be greater than zero");

        lotteryCount += 1;
        lotteries[lotteryCount] = Lottery({
            lotteryId: lotteryCount,
            participants: new address ,
            ticketPrice: ticketPrice,
            prizePool: 0,
            isActive: true,
            winner: address(0)
        });

        emit LotteryCreated(lotteryCount, ticketPrice);
    }

    function buyTicket(uint256 lotteryId) external payable {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.isActive, "Lottery is not active");
        require(msg.value == lottery.ticketPrice, "Incorrect ticket price");

        lottery.participants.push(msg.sender);
        lottery.prizePool += msg.value;

        emit TicketPurchased(lotteryId, msg.sender);
    }

    function drawWinner(uint256 lotteryId) external {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.isActive, "Lottery is not active");
        require(lottery.participants.length > 0, "No participants in the lottery");

        lottery.isActive = false;

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        lotteryToRequestId[requestId] = lotteryId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 lotteryId = lotteryToRequestId[requestId];
        Lottery storage lottery = lotteries[lotteryId];
        uint256 winnerIndex = randomWords[0] % lottery.participants.length;
        lottery.winner = lottery.participants[winnerIndex];

        (bool sent, ) = lottery.winner.call{value: lottery.prizePool}("");
        require(sent, "Failed to send Ether");

        emit WinnerDeclared(lotteryId, lottery.winner, lottery.prizePool);
    }

    receive() external payable {}
}
