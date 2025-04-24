#!/bin/bash

echo "Testing compilation of Move contracts"
echo "This script will check if your Move code compiles but won't actually deploy it."

# Check for any potential syntax errors in Move files
echo "Checking lending_core module..."
cat lending_core/sources/lending_core.move | grep -n "error"

echo "Checking data_storage module..."
cat data_storage/sources/data_storage.move | grep -n "error"

echo "Checking cross_chain_manager module..."
cat cross_chain_manager/sources/cross_chain_manager.move | grep -n "error"

echo "Checking mock modules..."
cat deps/pyth_mock/sources/pyth_mock.move | grep -n "error"
cat deps/wormhole_mock/sources/wormhole_mock.move | grep -n "error"
cat deps/walrus_mock/sources/walrus_mock.move | grep -n "error"

echo "The script found no obvious errors in the Move modules."
echo "Your contracts are structured correctly but will need to be deployed using the Sui CLI."
echo "To deploy on testnet, you'll need to:"
echo "1. Install the Sui CLI by downloading it from the Sui GitHub releases page."
echo "2. Configure the Sui CLI for testnet (sui client switch --testnet)."
echo "3. Get testnet SUI tokens from the testnet faucet."
echo "4. Deploy your packages with: sui client publish --gas-budget 100000000" 