/// Pyth Mock Implementation
/// 
/// This module provides a simplified mock of the Pyth price feed functionality
/// for development and testing purposes.
module pyth_mock::pyth_mock {
    use std::string::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};

    // === Error codes ===
    const EPriceNotFound: u64 = 0;
    const EInvalidSigner: u64 = 1;
    const EInvalidPriceData: u64 = 2;
    const EStalePrice: u64 = 3;

    // === Constants ===
    // Maximum staleness in milliseconds
    const MAX_PRICE_STALENESS_MS: u64 = 60000; // 1 minute

    // === Types ===

    /// Main price feed object 
    struct PriceFeeds has key {
        id: UID,
        // Admin address
        admin: address,
        // Price data by feed ID
        prices: Table<String, PriceData>,
        // Verification fee in SUI
        verification_fee: u64,
    }

    /// Represents price data for an asset
    struct PriceData has store, copy, drop {
        // Symbol (e.g., "BTC/USD")
        symbol: String,
        // Price in USD (with 8 decimal precision)
        price: u64,
        // Confidence interval (with 8 decimal precision)
        confidence: u64,
        // Timestamp of last update (in ms)
        last_updated_timestamp: u64,
        // Expo (e.g., -8 means price is scaled by 10^-8)
        expo: u8,
    }

    // === Events ===

    /// Emitted when a price is updated
    struct PriceUpdatedEvent has copy, drop {
        symbol: String,
        price: u64,
        confidence: u64,
        timestamp: u64,
    }

    // === Public functions ===

    /// Initialize a new price feed
    public fun initialize(
        admin: address, 
        verification_fee: u64,
        ctx: &mut TxContext
    ) {
        let price_feeds = PriceFeeds {
            id: object::new(ctx),
            admin,
            prices: table::new(ctx),
            verification_fee,
        };

        transfer::share_object(price_feeds);
    }

    /// Set price for an asset (admin only)
    public fun set_price(
        feeds: &mut PriceFeeds,
        symbol: String,
        price: u64,
        confidence: u64,
        expo: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == feeds.admin, EInvalidSigner);

        // Create price data
        let price_data = PriceData {
            symbol: symbol,
            price,
            confidence,
            last_updated_timestamp: clock::timestamp_ms(clock),
            expo,
        };

        // Update price in the table
        if (table::contains(&feeds.prices, symbol)) {
            let old_price = table::remove(&mut feeds.prices, symbol);
            table::add(&mut feeds.prices, symbol, price_data);
        } else {
            table::add(&mut feeds.prices, symbol, price_data);
        };

        // Emit event
        event::emit(PriceUpdatedEvent {
            symbol,
            price,
            confidence,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    /// Get current price for an asset
    public fun get_price(
        feeds: &PriceFeeds,
        symbol: String,
        clock: &Clock
    ): (u64, u64) {
        // Check if price exists
        assert!(table::contains(&feeds.prices, symbol), EPriceNotFound);

        // Get price data
        let price_data = table::borrow(&feeds.prices, symbol);

        // Check if price is stale
        let current_time = clock::timestamp_ms(clock);
        let time_since_update = current_time - price_data.last_updated_timestamp;
        assert!(time_since_update <= MAX_PRICE_STALENESS_MS, EStalePrice);

        // Return price and confidence
        (price_data.price, price_data.confidence)
    }

    /// Get price with timestamp for an asset
    public fun get_price_with_timestamp(
        feeds: &PriceFeeds,
        symbol: String
    ): (u64, u64, u64) {
        // Check if price exists
        assert!(table::contains(&feeds.prices, symbol), EPriceNotFound);

        // Get price data
        let price_data = table::borrow(&feeds.prices, symbol);

        // Return price, confidence, and timestamp
        (price_data.price, price_data.confidence, price_data.last_updated_timestamp)
    }

    /// Update price feed verification fee (admin only)
    public fun set_verification_fee(
        feeds: &mut PriceFeeds,
        new_fee: u64,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == feeds.admin, EInvalidSigner);

        // Update fee
        feeds.verification_fee = new_fee;
    }

    /// Get verification fee
    public fun get_verification_fee(feeds: &PriceFeeds): u64 {
        feeds.verification_fee
    }
} 