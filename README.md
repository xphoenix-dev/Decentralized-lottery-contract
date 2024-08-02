# Decentralized Lottery Contract

This smart contract implements a decentralized lottery where participants can buy tickets and a winner is randomly selected using Chainlink VRF for fairness.

## Features

- Users can create lotteries with a specified ticket price.
- Participants can buy tickets for active lotteries.
- A random winner is selected using Chainlink VRF, and the prize pool is transferred to the winner.

## How to Use

1. Deploy the contract and set up Chainlink VRF.
2. Use `createLottery()` to create a new lottery.
3. Participants can buy tickets using `buyTicket()` by sending the correct ticket price.
4. Once ready, call `drawWinner()` to trigger the random winner selection.
5. The contract will automatically transfer the prize pool to the selected winner.

## Security Considerations

- Ensure the Chainlink VRF setup is correctly configured for fair randomness.
- The contract holds funds, so security audits and testing are recommended.
- Use caution when dealing with real funds and test thoroughly in a development environment.
