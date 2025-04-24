# LendX Contract Deployment Guide

This guide will help you deploy the LendX contracts to the Sui testnet.

## Prerequisites

1. **Install the Sui CLI**

   - Download the appropriate Sui CLI binary for your platform from [Sui Releases](https://github.com/MystenLabs/sui/releases)
   - Add the binary to your PATH
   - Verify installation with `sui --version`

2. **Set up a Sui Wallet**

   - Create a wallet: `sui client new-address ed25519`
   - Save your mnemonic and address

3. **Switch to Testnet**

   - Set your client to use the testnet environment: `sui client switch --testnet`

4. **Get Testnet SUI Tokens**
   - Visit the [Sui Testnet Faucet](https://discord.com/channels/916379725201563759/971488439931392130) on Discord
   - Use the `/faucet` command with your address to get testnet SUI

## Deployment Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd lendx/contracts
```

### 2. Deploy Mock Packages First

Deploy the mock packages in the following order:

```bash
# Deploy Pyth Mock
cd deps/pyth_mock
sui client publish --gas-budget 100000000
# Save the published package ID

# Deploy Wormhole Mock
cd ../wormhole_mock
sui client publish --gas-budget 100000000
# Save the published package ID

# Deploy Walrus Mock
cd ../walrus_mock
sui client publish --gas-budget 100000000
# Save the published package ID
```

### 3. Update the Main Move.toml File

After deploying the mock packages, update the main `Move.toml` file with the actual package IDs:

```toml
[package]
name = "LendX"
version = "0.1.0"
published-at = "0x0"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/testnet" }
pyth_mock = { local = "./deps/pyth_mock", published-at = "0x..." }  # Add your published ID
wormhole_mock = { local = "./deps/wormhole_mock", published-at = "0x..." }  # Add your published ID
walrus_mock = { local = "./deps/walrus_mock", published-at = "0x..." }  # Add your published ID

[addresses]
lending_core = "0x0"
cross_chain_manager = "0x0"
data_storage = "0x0"
pyth_mock = "<PUBLISHED_PYTH_MOCK_PACKAGE_ID>"
wormhole_mock = "<PUBLISHED_WORMHOLE_MOCK_PACKAGE_ID>"
walrus_mock = "<PUBLISHED_WALRUS_MOCK_PACKAGE_ID>"
```

### 4. Deploy Main Packages

```bash
# Go back to the contracts root
cd ../../

# Deploy Data Storage Module
sui client publish --gas-budget 100000000
# Save the published package ID

# Update Move.toml with the data_storage address
# Then deploy Cross Chain Manager
sui client publish --gas-budget 100000000
# Save the published package ID

# Update Move.toml with both data_storage and cross_chain_manager addresses
# Then deploy Lending Core
sui client publish --gas-budget 100000000
```

### 5. Initialize the Protocol

After all packages are deployed, call the initialization functions:

```bash
# Initialize PriceFeeds
sui client call --package <PYTH_MOCK_PACKAGE_ID> --module pyth_mock --function initialize \
  --args <ADMIN_ADDRESS> <VERIFICATION_FEE> --gas-budget 10000000

# Initialize Data Manager
sui client call --package <DATA_STORAGE_PACKAGE_ID> --module data_storage --function initialize \
  --args <ADMIN_ADDRESS> <WALRUS_SYSTEM_OBJECT_ID> <STORAGE_CAPACITY> <DURATION_EPOCHS> --gas-budget 10000000

# Initialize Collateral Manager
sui client call --package <CROSS_CHAIN_MANAGER_PACKAGE_ID> --module cross_chain_manager --function initialize \
  --args <ADMIN_ADDRESS> --gas-budget 10000000

# Initialize Lending Pool
sui client call --package <LENDING_CORE_PACKAGE_ID> --module lending_core --function initialize \
  --args <ADMIN_ADDRESS> <UTILIZATION_OPTIMAL> <SLOPE1> <SLOPE2> --gas-budget 10000000
```

## Verification

After deployment, verify your packages are correctly published:

```bash
# Check your published packages
sui client objects --address <YOUR_ADDRESS>
```

## Additional Resources

- [Sui Developer Documentation](https://docs.sui.io/build)
- [Sui Move Programming Language](https://docs.sui.io/build/move)
- [Sui CLI Reference](https://docs.sui.io/build/cli)
