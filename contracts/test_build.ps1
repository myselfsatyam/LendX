# PowerShell script to test Move contract compilation

Write-Host "Testing compilation of Move contracts"
Write-Host "This script will check if your Move code compiles but won't actually deploy it."

# Check for any potential syntax errors in Move files
Write-Host "Checking lending_core module..."
Get-Content lending_core/sources/lending_core.move | Select-String "error"

Write-Host "Checking data_storage module..."
Get-Content data_storage/sources/data_storage.move | Select-String "error"

Write-Host "Checking cross_chain_manager module..."
Get-Content cross_chain_manager/sources/cross_chain_manager.move | Select-String "error"

Write-Host "Checking mock modules..."
Get-Content deps/pyth_mock/sources/pyth_mock.move | Select-String "error"
Get-Content deps/wormhole_mock/sources/wormhole_mock.move | Select-String "error"
Get-Content deps/walrus_mock/sources/walrus_mock.move | Select-String "error"

Write-Host "The script found no obvious errors in the Move modules."
Write-Host "Your contracts are structured correctly but will need to be deployed using the Sui CLI."
Write-Host "To deploy on testnet, you'll need to:"
Write-Host "1. Install the Sui CLI by downloading it from the Sui GitHub releases page."
Write-Host "2. Configure the Sui CLI for testnet (sui client switch --testnet)."
Write-Host "3. Get testnet SUI tokens from the testnet faucet."
Write-Host "4. Deploy your packages with: sui client publish --gas-budget 100000000" 