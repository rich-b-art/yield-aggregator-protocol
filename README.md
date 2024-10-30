# Yield Aggregator Protocol

The **Yield Aggregator Protocol** is a decentralized yield optimization contract designed to maximize returns by automatically allocating user funds across different yield farming opportunities. It optimizes investment performance by selecting the best strategies based on Annual Percentage Yields (APY) and other risk metrics. The protocol is implemented in Clarity, a language specifically designed for smart contracts on the Stacks blockchain.

---

## Features

- **Automated Yield Optimization**: Funds are strategically allocated across multiple yield farming strategies based on predefined rules and APY comparisons.
- **Emergency Shutdown**: A security feature allowing the contract owner to shut down protocol operations in case of emergencies.
- **Flexible Strategy Management**: New strategies can be added, updated, enabled, or disabled, and allocation criteria can be customized.
- **User Deposits and Withdrawals**: Users can deposit assets into the protocol and withdraw funds based on their share allocation.

---

## Getting Started

### Prerequisites

To deploy and interact with this contract, ensure you have the following tools installed:

- [Stacks CLI](https://docs.hiro.so/get-started/cli) or another tool compatible with Clarity development
- Stacks wallet address for contract ownership and deployment

### Installation

Clone the repository and navigate to the contract directory:

```bash
git clone https://github.com/rich-b-art/yield-aggregator-protocol.git
cd yield-aggregator-protocol
```

Deploy the contract on the Stacks blockchain testnet or mainnet using the Stacks CLI:

```bash
clarity-cli launch yield-aggregator.clar
```

### Contract Initialization

Upon deployment, the contract initializes with default variables, including `contract-owner`, `emergency-shutdown`, `total-value-locked`, `performance-fee`, `management-fee`, `max-strategies`, and `token-contract`.

The `contract-owner` is set as the contract deployer, and only this principal can perform administrative tasks.

---

## Key Components

### Constants and Error Codes

Constants are used to manage protocol parameters such as `contract-name`, `ERR-NOT-AUTHORIZED`, and `ERR-INSUFFICIENT-BALANCE`, providing readable error handling.

### Data Variables

- `contract-owner`: Set at deployment; only the owner can perform administrative functions.
- `emergency-shutdown`: Boolean to pause all contract activity in emergencies.
- `total-value-locked`: Tracks the total value locked in the protocol.
- `performance-fee` and `management-fee`: Fees collected on user deposits and withdrawals, adjustable by the contract owner.

### Data Maps

- `Strategies`: Stores details about each yield farming strategy, including name, protocol, APY, and risk score.
- `UserDeposits`: Manages user-specific data, including total deposits and token shares.
- `StrategyAllocations`: Holds allocation details, such as minimum/maximum deposit requirements for each strategy.

---

## Functions

### Public Functions

1. **Deposit** - Allows users to deposit funds into the protocol.
2. **Withdraw** - Users can withdraw their allocated share tokens and underlying assets.
3. **Add Strategy** - Adds a new yield strategy with specific parameters.
4. **Update Strategy APY** - Allows the contract owner to update the APY of a strategy.
5. **Toggle Emergency Shutdown** - Enables or disables emergency shutdown mode.
6. **Set Token Contract** - Sets the token contract for managing deposits and withdrawals.

### Read-Only Functions

1. **Get Strategy List** - Returns the list of available strategy IDs.
2. **Get Strategy Info** - Provides details about a specific strategy.
3. **Get User Info** - Returns deposit information for a specific user.
4. **Get Total TVL** - Retrieves the total value locked in the protocol.
5. **Calculate Best Strategy** - Identifies the best strategy based on APY and other metrics.

### Private Functions

These functions manage internal calculations and validations, such as verifying the contract owner, calculating share tokens, and reallocating funds across strategies.

---

## Security

- **Authorization**: Only the contract owner can add strategies, update parameters, and toggle emergency shutdown.
- **Emergency Shutdown**: In the event of critical issues, the contract can be paused to protect user assets.
- **Error Handling**: Error codes provide detailed feedback on failed operations to improve transparency and debugging.

---

## Testing

Test the protocol by writing and running test cases in a Clarity-compatible testing environment, such as Clarinet or `clarity-cli`. Ensure all scenarios are covered, including deposit, withdrawal, strategy updates, and emergency shutdown activation.

---

## License

This project is licensed under the MIT License.
