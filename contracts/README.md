# LendX - Cross-Chain Lending Protocol

LendX is a cross-chain lending protocol built on Sui blockchain that enables users to borrow stablecoins by depositing crypto assets as collateral from various blockchains.

## Contract Structure

The protocol consists of three main contracts:

### 1. LendingCore

The heart of the LendX protocol - controls capital flows and risk checks:

- Handles both borrower and lender logic
- LPs deposit stablecoins (USDC, etc.)
- Borrowers take loans by locking crypto as collateral
- Tracks loan issuance, interest accrual, and repayments
- Interfaces with Pyth price feeds for loan-to-value (LTV) checks
- Triggers liquidations via internal logic

### 2. CrossChainCollateralManager

Handles cross-chain deposits and messaging via Wormhole:

- Accepts collateral from multiple chains (Ethereum, Solana, etc.)
- Uses Wormhole SDK to verify and lock bridged assets
- Manages collateral status across chains
- Sends collateral state updates to LendingCore

### 3. DataStorage

Walrus-based storage for all critical loan and collateral data:

- Uses Walrus for programmable on-chain storage
- Records: loan agreements, borrower collateral, repayments, liquidation logs
- Supports analytics, auditability, and historical access
- Also stores user status, TwitterAI triggers, and more

## Dependencies

- [Sui](https://sui.io/) - Base blockchain
- [Pyth Network](https://pyth.network/) - Price feeds
- [Wormhole](https://wormhole.com/) - Cross-chain messaging
- [Walrus](https://docs.wal.app/) - Decentralized storage on Sui

## Getting Started

1. Install Sui
2. Clone this repository
3. Build the contracts:
   ```
   sui move build
   ```

## Integration Details

### Pyth Integration

- Used for price feeds to determine loan-to-value ratios and liquidation thresholds
- The LendingCore contract queries Pyth Oracle for real-time price data

### Wormhole Integration

- Used for cross-chain messaging to verify asset transfers
- The CrossChainCollateralManager contract interacts with the Wormhole contract to process VAAs

### Walrus Integration

- Used for storing loan and collateral data
- The DataStorage contract interacts with Walrus to store and retrieve data

## License

TBD
