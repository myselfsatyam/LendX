/// Wormhole Mock Implementation
/// 
/// This module provides a simplified mock of the Wormhole cross-chain messaging functionality
/// for development and testing purposes.
module wormhole_mock::wormhole_mock {
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    
    // === Error codes ===
    const EInvalidVAA: u64 = 0;
    const EInvalidSignature: u64 = 1;
    const EInvalidChainId: u64 = 2;
    const EInvalidSigner: u64 = 3;
    const EMessageNotFound: u64 = 4;
    const EVAAAlreadyProcessed: u64 = 5;
    
    // === Types ===
    
    /// Represents the Wormhole contract
    struct Wormhole has key {
        id: UID,
        // Admin address
        admin: address,
        // Guardian set
        guardians: vector<address>,
        // Chain ID for this chain
        chain_id: u16,
        // Current sequence number
        sequence: u64,
        // Messages that have been published
        messages: Table<u64, Message>,
        // Message VAAs that have been processed (to prevent replay)
        processed_vaas: Table<vector<u8>, bool>,
        // Bridge fee in SUI
        bridge_fee: u64,
    }
    
    /// Represents a message that has been published
    struct Message has store {
        // Sequence number
        sequence: u64,
        // Source chain ID
        source_chain_id: u16,
        // Emitter address
        emitter: address,
        // Target chain ID
        target_chain_id: u16,
        // Payload
        payload: vector<u8>,
        // Timestamp
        timestamp: u64,
        // VAA (if this message has been signed by guardians)
        vaa: Option<vector<u8>>,
    }
    
    /// Represents a VAA (Verified Action Approval) message
    struct VAA has copy, drop {
        // VAA version
        version: u8,
        // Guardian set index
        guardian_set_index: u32,
        // Signatures
        signatures: vector<Signature>,
        // Message timestamp
        timestamp: u64,
        // Nonce
        nonce: u32,
        // Source chain ID
        source_chain_id: u16,
        // Emitter address
        emitter: address,
        // Sequence number
        sequence: u64,
        // Consistency level
        consistency_level: u8,
        // Payload
        payload: vector<u8>,
        // Hash of the VAA
        hash: vector<u8>,
    }
    
    /// Represents a signature in a VAA
    struct Signature has copy, drop {
        // Guardian index
        guardian_index: u8,
        // Signature bytes
        signature: vector<u8>,
    }
    
    // === Events ===
    
    /// Emitted when a message is published
    struct MessagePublishedEvent has copy, drop {
        sequence: u64,
        source_chain_id: u16,
        emitter: address,
        target_chain_id: u16,
        timestamp: u64,
    }
    
    /// Emitted when a VAA is received and verified
    struct VAAReceivedEvent has copy, drop {
        source_chain_id: u16,
        sequence: u64,
        emitter: address,
        timestamp: u64,
    }
    
    // === Public functions ===
    
    /// Initialize a new Wormhole contract
    public fun initialize(
        admin: address,
        chain_id: u16,
        bridge_fee: u64,
        ctx: &mut TxContext
    ) {
        let wormhole = Wormhole {
            id: object::new(ctx),
            admin,
            guardians: vector::empty<address>(),
            chain_id,
            sequence: 0,
            messages: table::new(ctx),
            processed_vaas: table::new(ctx),
            bridge_fee,
        };
        
        transfer::share_object(wormhole);
    }
    
    /// Add a guardian (admin only)
    public fun add_guardian(
        wormhole: &mut Wormhole,
        guardian: address,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == wormhole.admin, EInvalidSigner);
        
        // Add guardian
        if (!vector::contains(&wormhole.guardians, &guardian)) {
            vector::push_back(&mut wormhole.guardians, guardian);
        };
    }
    
    /// Remove a guardian (admin only)
    public fun remove_guardian(
        wormhole: &mut Wormhole,
        guardian: address,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == wormhole.admin, EInvalidSigner);
        
        // Find and remove guardian
        let (found, index) = vector::index_of(&wormhole.guardians, &guardian);
        if (found) {
            vector::remove(&mut wormhole.guardians, index);
        };
    }
    
    /// Publish a message to another chain
    public fun publish_message(
        wormhole: &mut Wormhole,
        target_chain_id: u16,
        payload: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        // Increment sequence
        let sequence = wormhole.sequence + 1;
        wormhole.sequence = sequence;
        
        // Create message
        let message = Message {
            sequence,
            source_chain_id: wormhole.chain_id,
            emitter: tx_context::sender(ctx),
            target_chain_id,
            payload,
            timestamp: clock::timestamp_ms(clock),
            vaa: option::none(),
        };
        
        // Add message to table
        table::add(&mut wormhole.messages, sequence, message);
        
        // Emit event
        event::emit(MessagePublishedEvent {
            sequence,
            source_chain_id: wormhole.chain_id,
            emitter: tx_context::sender(ctx),
            target_chain_id,
            timestamp: clock::timestamp_ms(clock),
        });
        
        sequence
    }
    
    /// Create a mock VAA for testing
    public fun create_mock_vaa(
        wormhole: &mut Wormhole,
        source_chain_id: u16,
        emitter: address,
        sequence: u64,
        payload: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): vector<u8> {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == wormhole.admin, EInvalidSigner);
        
        // Create a mock signature
        let signature = Signature {
            guardian_index: 0,
            signature: b"mock_signature",
        };
        
        // Create VAA
        let vaa = VAA {
            version: 1,
            guardian_set_index: 0,
            signatures: vector::singleton(signature),
            timestamp: clock::timestamp_ms(clock),
            nonce: 0,
            source_chain_id,
            emitter,
            sequence,
            consistency_level: 0,
            payload,
            hash: b"mock_hash",
        };
        
        // Convert VAA to bytes (in a real implementation, this would be more complex)
        // For our mock, just concatenate the fields
        let vaa_bytes = vector::empty<u8>();
        vector::append(&mut vaa_bytes, vector::singleton(vaa.version));
        vector::append(&mut vaa_bytes, b"_");
        vector::append(&mut vaa_bytes, payload);
        
        vaa_bytes
    }
    
    /// Parse a VAA (mock implementation)
    public fun parse_and_verify_vaa(
        wormhole: &mut Wormhole,
        vaa_bytes: vector<u8>,
        ctx: &mut TxContext
    ): VAA {
        // Check if VAA has been processed before
        assert!(!table::contains(&wormhole.processed_vaas, vaa_bytes), EVAAAlreadyProcessed);
        
        // In a real implementation, this would verify signatures, but for our mock,
        // we'll just extract the payload assuming a simple format
        
        // Mark VAA as processed
        table::add(&mut wormhole.processed_vaas, vaa_bytes, true);
        
        // Split the VAA bytes to get version and payload
        // Format: version_payload
        let split_index = vector::index_of(&vaa_bytes, &b"_"[0]);
        assert!(option::is_some(&split_index), EInvalidVAA);
        let split_index = option::extract(&mut split_index);
        
        let version_bytes = vector::empty<u8>();
        let i = 0;
        while (i < split_index) {
            vector::push_back(&mut version_bytes, *vector::borrow(&vaa_bytes, i));
            i = i + 1;
        };
        
        let payload = vector::empty<u8>();
        let i = split_index + 1;
        while (i < vector::length(&vaa_bytes)) {
            vector::push_back(&mut payload, *vector::borrow(&vaa_bytes, i));
            i = i + 1;
        };
        
        // Create and return VAA
        VAA {
            version: 1, // Use fixed version for mock
            guardian_set_index: 0,
            signatures: vector::empty<Signature>(),
            timestamp: tx_context::epoch_timestamp_ms(ctx),
            nonce: 0,
            source_chain_id: 1, // Use fixed source chain ID for mock
            emitter: tx_context::sender(ctx),
            sequence: wormhole.sequence,
            consistency_level: 0,
            payload,
            hash: vaa_bytes,
        }
    }
    
    /// Extract payload from VAA
    public fun get_payload(vaa: &VAA): vector<u8> {
        vaa.payload
    }
    
    /// Get bridge fee
    public fun get_bridge_fee(wormhole: &Wormhole): u64 {
        wormhole.bridge_fee
    }
    
    /// Set bridge fee (admin only)
    public fun set_bridge_fee(
        wormhole: &mut Wormhole,
        new_fee: u64,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == wormhole.admin, EInvalidSigner);
        
        // Update fee
        wormhole.bridge_fee = new_fee;
    }
} 