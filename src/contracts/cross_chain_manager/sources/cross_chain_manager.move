/// CrossChainCollateralManager - Handles cross-chain collateral via Wormhole
/// 
/// This contract manages cross-chain collateral deposits:
/// - Accepts collateral from multiple chains (Ethereum, Solana, etc.)
/// - Uses Wormhole SDK to verify and lock bridged assets
/// - Manages collateral status across chains
/// - Sends collateral state updates to LendingCore
module cross_chain_manager::cross_chain_manager {
    use std::string::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    
    // Use mock implementations for development
    use wormhole_mock::wormhole_mock::{Self, Wormhole, VAA};
    use pyth_mock::pyth_mock::{Self, PriceFeeds};
    
    // === Error codes ===
    const EInvalidVAA: u64 = 0;
    const EInvalidSourceChain: u64 = 1;
    const EAssetNotSupported: u64 = 2;
    const EInvalidCollateralAmount: u64 = 3;
    const EInvalidSigner: u64 = 4;
    const ECollateralNotFound: u64 = 5;
    const ECollateralLocked: u64 = 6;
    const EInsufficientCollateralValue: u64 = 7;
    
    // === Types ===
    
    /// Main storage for the cross-chain collateral manager
    struct CollateralManager has key {
        id: UID,
        // Admin address
        admin: address,
        // Supported chains
        supported_chains: Table<u16, SupportedChain>,
        // Collateral deposits by ID
        collateral_deposits: Table<ID, CollateralDeposit>,
        // Total collateral by asset type
        collateral_by_asset: Table<String, u64>,
    }
    
    /// Represents a supported chain
    struct SupportedChain has store {
        // Chain ID as defined by Wormhole
        chain_id: u16,
        // Chain name
        name: String,
        // Whether the chain is active
        active: bool,
        // Mapping of supported assets on this chain
        supported_assets: Table<String, SupportedAsset>,
    }
    
    /// Represents a supported asset on a chain
    struct SupportedAsset has store {
        // Asset name (e.g., "ETH", "USDC")
        name: String,
        // Asset address on the source chain
        address: vector<u8>,
        // Decimal precision of the asset
        decimals: u8,
        // Collateralization factor (e.g., 80% = 8000 basis points)
        collateralization_factor_bps: u64,
        // Whether the asset is active
        active: bool,
    }
    
    /// Represents a collateral deposit from another chain
    struct CollateralDeposit has store {
        // Deposit ID
        id: ID,
        // User address on Sui
        owner: address,
        // Source chain ID
        source_chain_id: u16,
        // Asset name
        asset_name: String,
        // Asset amount (in smallest units)
        amount: u64,
        // Wormhole transaction ID or sequence
        wormhole_sequence: u64,
        // Timestamp of deposit
        deposit_timestamp: u64,
        // Whether the collateral is locked (used in a loan)
        locked: bool,
        // Loan ID if locked
        loan_id: Option<ID>,
    }
    
    // === Events ===
    
    /// Emitted when collateral is deposited from another chain
    struct CollateralDepositedEvent has copy, drop {
        deposit_id: ID,
        owner: address,
        source_chain_id: u16,
        asset_name: String,
        amount: u64,
        wormhole_sequence: u64,
        timestamp: u64,
    }
    
    /// Emitted when collateral is withdrawn back to the original chain
    struct CollateralWithdrawnEvent has copy, drop {
        deposit_id: ID,
        owner: address,
        destination_chain_id: u16,
        asset_name: String,
        amount: u64,
        timestamp: u64,
    }
    
    /// Emitted when collateral is locked for a loan
    struct CollateralLockedEvent has copy, drop {
        deposit_id: ID,
        loan_id: ID,
        owner: address,
        asset_name: String,
        amount: u64,
        timestamp: u64,
    }
    
    /// Emitted when collateral is released from a loan
    struct CollateralReleasedEvent has copy, drop {
        deposit_id: ID,
        loan_id: ID,
        owner: address,
        asset_name: String,
        amount: u64,
        timestamp: u64,
    }
    
    // === Public functions ===
    
    /// Initialize a new collateral manager
    public fun initialize(admin: address, ctx: &mut TxContext) {
        let collateral_manager = CollateralManager {
            id: object::new(ctx),
            admin,
            supported_chains: table::new(ctx),
            collateral_deposits: table::new(ctx),
            collateral_by_asset: table::new(ctx),
        };
        
        transfer::share_object(collateral_manager);
    }
    
    /// Add a supported chain
    public fun add_supported_chain(
        manager: &mut CollateralManager,
        chain_id: u16,
        name: String,
        ctx: &mut TxContext
    ) {
        // Only admin can add supported chains
        assert!(tx_context::sender(ctx) == manager.admin, EInvalidSigner);
        
        // Create supported chain entry
        let supported_chain = SupportedChain {
            chain_id,
            name,
            active: true,
            supported_assets: table::new(ctx),
        };
        
        // Add to table
        table::add(&mut manager.supported_chains, chain_id, supported_chain);
    }
    
    /// Add a supported asset for a chain
    public fun add_supported_asset(
        manager: &mut CollateralManager,
        chain_id: u16,
        asset_name: String,
        asset_address: vector<u8>,
        decimals: u8,
        collateralization_factor_bps: u64,
        ctx: &mut TxContext
    ) {
        // Only admin can add supported assets
        assert!(tx_context::sender(ctx) == manager.admin, EInvalidSigner);
        
        // Check if chain exists and is active
        assert!(table::contains(&manager.supported_chains, chain_id), EInvalidSourceChain);
        let chain = table::borrow_mut(&mut manager.supported_chains, chain_id);
        assert!(chain.active, EInvalidSourceChain);
        
        // Create supported asset entry
        let supported_asset = SupportedAsset {
            name: asset_name,
            address: asset_address,
            decimals,
            collateralization_factor_bps,
            active: true,
        };
        
        // Add to table
        table::add(&mut chain.supported_assets, asset_name, supported_asset);
        
        // Initialize collateral tracking for this asset
        if (!table::contains(&manager.collateral_by_asset, asset_name)) {
            table::add(&mut manager.collateral_by_asset, asset_name, 0);
        };
    }
    
    /// Process a Wormhole VAA message to deposit collateral
    public fun process_collateral_deposit(
        manager: &mut CollateralManager,
        wormhole: &mut Wormhole,
        vaa_bytes: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Parse and verify the VAA
        let vaa = wormhole_mock::parse_and_verify_vaa(wormhole, vaa_bytes, ctx);
        
        // Extract data from VAA
        let payload = wormhole_mock::get_payload(&vaa);
        
        // Parse payload (in a real implementation, this would be more complex)
        // For our mock, assume the payload is formatted as: chain_id|asset_name|amount
        let source_chain_id = 1; // Ethereum for mock
        let asset_name = string::utf8(b"ETH"); // ETH for mock
        let amount: u64 = 1000000000000000000; // 1 ETH for mock
        let wormhole_sequence: u64 = vaa.sequence;
        let receiver = tx_context::sender(ctx);
        
        // Verify chain is supported
        assert!(table::contains(&manager.supported_chains, source_chain_id), EInvalidSourceChain);
        let chain = table::borrow(&manager.supported_chains, source_chain_id);
        assert!(chain.active, EInvalidSourceChain);
        
        // Verify asset is supported
        assert!(table::contains(&chain.supported_assets, asset_name), EAssetNotSupported);
        let asset = table::borrow(&chain.supported_assets, asset_name);
        assert!(asset.active, EAssetNotSupported);
        
        // Create a deposit ID
        let deposit_id = object::new(ctx);
        let deposit_id_copy = object::uid_to_inner(&deposit_id);
        
        // Create the collateral deposit
        let deposit = CollateralDeposit {
            id: deposit_id,
            owner: receiver,
            source_chain_id,
            asset_name,
            amount,
            wormhole_sequence,
            deposit_timestamp: clock::timestamp_ms(clock),
            locked: false,
            loan_id: option::none(),
        };
        
        // Add to table
        table::add(&mut manager.collateral_deposits, deposit_id_copy, deposit);
        
        // Update total collateral for this asset
        let current_total = *table::borrow(&manager.collateral_by_asset, asset_name);
        table::remove(&mut manager.collateral_by_asset, asset_name);
        table::add(&mut manager.collateral_by_asset, asset_name, current_total + amount);
        
        // Emit event
        event::emit(CollateralDepositedEvent {
            deposit_id: deposit_id_copy,
            owner: receiver,
            source_chain_id,
            asset_name,
            amount,
            wormhole_sequence,
            timestamp: clock::timestamp_ms(clock),
        });
        
        deposit_id_copy
    }
    
    /// Lock collateral for a loan
    public fun lock_collateral(
        manager: &mut CollateralManager,
        deposit_id: ID,
        loan_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit
        let deposit = table::borrow_mut(&mut manager.collateral_deposits, deposit_id);
        
        // Check if sender is the owner
        assert!(deposit.owner == tx_context::sender(ctx), EInvalidSigner);
        
        // Check if collateral is not already locked
        assert!(!deposit.locked, ECollateralLocked);
        
        // Lock collateral
        deposit.locked = true;
        deposit.loan_id = option::some(loan_id);
        
        // Emit event
        event::emit(CollateralLockedEvent {
            deposit_id,
            loan_id,
            owner: deposit.owner,
            asset_name: deposit.asset_name,
            amount: deposit.amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Release collateral from a loan
    public fun release_collateral(
        manager: &mut CollateralManager,
        deposit_id: ID,
        loan_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit
        let deposit = table::borrow_mut(&mut manager.collateral_deposits, deposit_id);
        
        // Check if collateral is locked
        assert!(deposit.locked, ECollateralNotFound);
        
        // Check if loan ID matches
        assert!(option::contains(&deposit.loan_id, &loan_id), ECollateralNotFound);
        
        // Release collateral
        deposit.locked = false;
        deposit.loan_id = option::none();
        
        // Emit event
        event::emit(CollateralReleasedEvent {
            deposit_id,
            loan_id,
            owner: deposit.owner,
            asset_name: deposit.asset_name,
            amount: deposit.amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Initiate withdrawal of collateral back to the original chain
    public fun withdraw_collateral(
        manager: &mut CollateralManager,
        wormhole: &mut Wormhole,
        deposit_id: ID,
        destination_address: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit
        let deposit = table::borrow(&manager.collateral_deposits, deposit_id);
        
        // Check if sender is the owner
        assert!(deposit.owner == tx_context::sender(ctx), EInvalidSigner);
        
        // Check if collateral is not locked
        assert!(!deposit.locked, ECollateralLocked);
        
        // Create message payload for withdrawal
        let payload = vector::empty<u8>();
        // In a real implementation, this would be properly encoded
        // For mock, we'll just use a simple format
        
        // Publish message to Wormhole
        let sequence = wormhole_mock::publish_message(
            wormhole,
            deposit.source_chain_id,
            payload,
            clock,
            ctx
        );
        
        // Emit withdrawal event
        event::emit(CollateralWithdrawnEvent {
            deposit_id,
            owner: deposit.owner,
            destination_chain_id: deposit.source_chain_id,
            asset_name: deposit.asset_name,
            amount: deposit.amount,
            timestamp: clock::timestamp_ms(clock),
        });
        
        // Update total collateral for this asset
        let asset_name = deposit.asset_name;
        let amount = deposit.amount;
        let current_total = *table::borrow(&manager.collateral_by_asset, asset_name);
        table::remove(&mut manager.collateral_by_asset, asset_name);
        table::add(&mut manager.collateral_by_asset, asset_name, current_total - amount);
        
        // Remove the deposit
        let CollateralDeposit {
            id,
            owner: _,
            source_chain_id: _,
            asset_name: _,
            amount: _,
            wormhole_sequence: _,
            deposit_timestamp: _,
            locked: _,
            loan_id: _,
        } = table::remove(&mut manager.collateral_deposits, deposit_id);
        
        // Destroy the UID
        object::delete(id);
    }
    
    /// Get the value of collateral in USD using Pyth price feeds
    public fun get_collateral_value(
        manager: &CollateralManager,
        price_feeds: &PriceFeeds,
        deposit_id: ID,
        clock: &Clock
    ): u64 {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit
        let deposit = table::borrow(&manager.collateral_deposits, deposit_id);
        
        // Get chain and asset info
        let chain = table::borrow(&manager.supported_chains, deposit.source_chain_id);
        let asset = table::borrow(&chain.supported_assets, deposit.asset_name);
        
        // Get price from Pyth
        let (price, _) = pyth_mock::get_price(price_feeds, deposit.asset_name, clock);
        
        // Calculate value based on amount and price
        // Adjust for different decimal precision between asset and price
        let value = (deposit.amount * price) / (10 ** (asset.decimals as u64));
        
        // Apply collateralization factor
        (value * asset.collateralization_factor_bps) / 10000
    }
    
    /// Check if collateral has sufficient value for a loan amount
    public fun has_sufficient_value(
        manager: &CollateralManager,
        price_feeds: &PriceFeeds,
        deposit_id: ID,
        loan_amount: u64,
        required_ratio: u64, // in percentage (e.g., 150 for 150%)
        clock: &Clock
    ): bool {
        // Get collateral value
        let collateral_value = get_collateral_value(manager, price_feeds, deposit_id, clock);
        
        // Check if value is sufficient
        // Formula: collateral_value >= loan_amount * required_ratio / 100
        collateral_value >= (loan_amount * required_ratio) / 100
    }
    
    /// Get collateral deposit details
    public fun get_collateral_details(
        manager: &CollateralManager,
        deposit_id: ID
    ): (address, u16, String, u64, bool, Option<ID>) {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit
        let deposit = table::borrow(&manager.collateral_deposits, deposit_id);
        
        // Return details: owner, source chain, asset name, amount, locked status, loan ID
        (
            deposit.owner,
            deposit.source_chain_id,
            deposit.asset_name,
            deposit.amount,
            deposit.locked,
            deposit.loan_id
        )
    }
    
    /// Check if collateral is locked
    public fun is_locked(
        manager: &CollateralManager,
        deposit_id: ID
    ): bool {
        // Check if deposit exists
        assert!(table::contains(&manager.collateral_deposits, deposit_id), ECollateralNotFound);
        
        // Get deposit and return locked status
        let deposit = table::borrow(&manager.collateral_deposits, deposit_id);
        deposit.locked
    }
    
    /// Get total collateral for an asset
    public fun get_total_collateral(
        manager: &CollateralManager,
        asset_name: String
    ): u64 {
        // Check if asset is tracked
        if (!table::contains(&manager.collateral_by_asset, asset_name)) {
            return 0
        };
        
        // Return total collateral for the asset
        *table::borrow(&manager.collateral_by_asset, asset_name)
    }
} 