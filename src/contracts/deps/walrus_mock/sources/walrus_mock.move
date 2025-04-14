/// Walrus Mock Implementation
/// 
/// This module provides a simplified mock of the Walrus decentralized storage functionality
/// for development and testing purposes.
module walrus_mock::walrus_mock {
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    
    // === Error codes ===
    const EInvalidSigner: u64 = 0;
    const EInsufficientStorage: u64 = 1;
    const EBlobNotFound: u64 = 2;
    const EStorageResourceNotFound: u64 = 3;
    const EInvalidStorageDuration: u64 = 4;
    const EInvalidAvailabilityCertificate: u64 = 5;
    
    // === Types ===
    
    /// Represents the Walrus system object that manages storage resources
    struct WalrusSystem has key {
        id: UID,
        // Admin address
        admin: address,
        // Total available storage space (in bytes)
        total_available_space: u64,
        // Price per unit of storage (1 KiB) in SUI
        price_per_unit: u64,
        // Current storage epoch
        current_epoch: u64,
        // Storage resources by ID
        storage_resources: Table<ID, StorageResource>,
        // Blobs by ID
        blobs: Table<ID, Blob>,
        // Storage nodes
        storage_nodes: vector<address>,
    }
    
    /// Represents a storage resource that can be purchased and used to store blobs
    struct StorageResource has key, store {
        id: UID,
        // Owner of the resource
        owner: address,
        // Size of the resource in bytes
        size: u64,
        // Expiry epoch
        expiry_epoch: u64,
        // Storage blobs using this resource
        blob_ids: vector<ID>,
        // Whether the resource is active
        active: bool,
    }
    
    /// Represents a blob stored in the system
    struct Blob has store {
        // Blob ID
        id: ID,
        // Owner of the blob
        owner: address,
        // Size of the blob in bytes
        size: u64,
        // Content hash
        content_hash: vector<u8>,
        // Storage resource ID used
        storage_resource_id: ID,
        // Upload timestamp
        upload_timestamp: u64,
        // Expiry timestamp
        expiry_timestamp: u64,
        // Actual blob content (in a real implementation, this would be stored off-chain)
        content: vector<u8>,
    }
    
    /// Represents an availability certificate for a blob
    struct AvailabilityCertificate has copy, drop {
        // Blob ID
        blob_id: ID,
        // Signatures from storage nodes (in a real implementation, this would be more complex)
        signatures: vector<vector<u8>>,
    }
    
    // === Events ===
    
    /// Emitted when a storage resource is purchased
    struct StorageResourcePurchasedEvent has copy, drop {
        resource_id: ID,
        owner: address,
        size: u64,
        expiry_epoch: u64,
        timestamp: u64,
    }
    
    /// Emitted when a blob is stored
    struct BlobStoredEvent has copy, drop {
        blob_id: ID,
        owner: address,
        size: u64,
        storage_resource_id: ID,
        timestamp: u64,
    }
    
    /// Emitted when a blob is certified as available
    struct BlobAvailableEvent has copy, drop {
        blob_id: ID,
        owner: address,
        timestamp: u64,
    }
    
    // === Public functions ===
    
    /// Initialize a new Walrus system
    public fun initialize(
        admin: address,
        total_available_space: u64,
        price_per_unit: u64,
        ctx: &mut TxContext
    ) {
        let walrus_system = WalrusSystem {
            id: object::new(ctx),
            admin,
            total_available_space,
            price_per_unit,
            current_epoch: tx_context::epoch(ctx),
            storage_resources: table::new(ctx),
            blobs: table::new(ctx),
            storage_nodes: vector::empty<address>(),
        };
        
        transfer::share_object(walrus_system);
    }
    
    /// Add a storage node (admin only)
    public fun add_storage_node(
        system: &mut WalrusSystem,
        node: address,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == system.admin, EInvalidSigner);
        
        // Add node if not already present
        if (!vector::contains(&system.storage_nodes, &node)) {
            vector::push_back(&mut system.storage_nodes, node);
        };
    }
    
    /// Remove a storage node (admin only)
    public fun remove_storage_node(
        system: &mut WalrusSystem,
        node: address,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == system.admin, EInvalidSigner);
        
        // Find and remove node
        let (found, index) = vector::index_of(&system.storage_nodes, &node);
        if (found) {
            vector::remove(&mut system.storage_nodes, index);
        };
    }
    
    /// Purchase a storage resource
    public fun purchase_storage_resource(
        system: &mut WalrusSystem,
        size: u64,
        duration_epochs: u64,
        ctx: &mut TxContext
    ): ID {
        // Check if duration is valid
        assert!(duration_epochs > 0, EInvalidStorageDuration);
        
        // Check if there's enough available space
        assert!(system.total_available_space >= size, EInsufficientStorage);
        
        // Calculate expiry epoch
        let current_epoch = tx_context::epoch(ctx);
        let expiry_epoch = current_epoch + duration_epochs;
        
        // Create storage resource
        let resource_id = object::new(ctx);
        let resource_id_copy = object::uid_to_inner(&resource_id);
        
        let storage_resource = StorageResource {
            id: resource_id,
            owner: tx_context::sender(ctx),
            size,
            expiry_epoch,
            blob_ids: vector::empty<ID>(),
            active: true,
        };
        
        // Update system state
        system.total_available_space = system.total_available_space - size;
        
        // Add to table
        table::add(&mut system.storage_resources, resource_id_copy, storage_resource);
        
        // Emit event
        event::emit(StorageResourcePurchasedEvent {
            resource_id: resource_id_copy,
            owner: tx_context::sender(ctx),
            size,
            expiry_epoch,
            timestamp: tx_context::epoch_timestamp_ms(ctx),
        });
        
        resource_id_copy
    }
    
    /// Store a blob using a storage resource
    public fun store_blob(
        system: &mut WalrusSystem,
        storage_resource_id: ID,
        content: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Check if storage resource exists
        assert!(table::contains(&system.storage_resources, storage_resource_id), EStorageResourceNotFound);
        
        // Get storage resource
        let storage_resource = table::borrow_mut(&mut system.storage_resources, storage_resource_id);
        
        // Check if sender is the owner of the resource
        assert!(storage_resource.owner == tx_context::sender(ctx), EInvalidSigner);
        
        // Check if resource is active
        assert!(storage_resource.active, EStorageResourceNotFound);
        
        // Check if current epoch is before expiry
        assert!(tx_context::epoch(ctx) < storage_resource.expiry_epoch, EStorageResourceNotFound);
        
        // Calculate size of content
        let size = vector::length(&content);
        
        // Check if resource has enough space
        assert!(size <= storage_resource.size, EInsufficientStorage);
        
        // Create blob ID
        let blob_id = object::new(ctx);
        let blob_id_copy = object::uid_to_inner(&blob_id);
        object::delete(blob_id);
        
        // Create blob
        let blob = Blob {
            id: blob_id_copy,
            owner: tx_context::sender(ctx),
            size,
            content_hash,
            storage_resource_id,
            upload_timestamp: clock::timestamp_ms(clock),
            expiry_timestamp: (storage_resource.expiry_epoch as u64) * 1000, // Convert epochs to ms (simplified)
            content,
        };
        
        // Add blob ID to storage resource
        vector::push_back(&mut storage_resource.blob_ids, blob_id_copy);
        
        // Update storage resource size
        storage_resource.size = storage_resource.size - size;
        
        // Add blob to table
        table::add(&mut system.blobs, blob_id_copy, blob);
        
        // Emit event
        event::emit(BlobStoredEvent {
            blob_id: blob_id_copy,
            owner: tx_context::sender(ctx),
            size,
            storage_resource_id,
            timestamp: clock::timestamp_ms(clock),
        });
        
        blob_id_copy
    }
    
    /// Retrieve a blob
    public fun retrieve_blob(
        system: &WalrusSystem,
        blob_id: ID
    ): vector<u8> {
        // Check if blob exists
        assert!(table::contains(&system.blobs, blob_id), EBlobNotFound);
        
        // Get blob
        let blob = table::borrow(&system.blobs, blob_id);
        
        // Return content
        blob.content
    }
    
    /// Create a mock availability certificate for a blob
    public fun create_mock_availability_certificate(
        system: &WalrusSystem,
        blob_id: ID,
        ctx: &mut TxContext
    ): AvailabilityCertificate {
        // Check if blob exists
        assert!(table::contains(&system.blobs, blob_id), EBlobNotFound);
        
        // Get blob
        let blob = table::borrow(&system.blobs, blob_id);
        
        // Check if sender is the owner of the blob
        assert!(blob.owner == tx_context::sender(ctx), EInvalidSigner);
        
        // Create mock signatures
        let signatures = vector::empty<vector<u8>>();
        let i = 0;
        let num_nodes = vector::length(&system.storage_nodes);
        
        // Create signatures from 2/3 of storage nodes (simulating quorum)
        let required_signatures = (num_nodes * 2) / 3;
        while (i < required_signatures && i < num_nodes) {
            let signature = vector::empty<u8>();
            vector::append(&mut signature, b"node_");
            vector::append(&mut signature, blob_id);
            vector::push_back(&mut signatures, signature);
            i = i + 1;
        };
        
        // Create certificate
        AvailabilityCertificate {
            blob_id,
            signatures,
        }
    }
    
    /// Upload an availability certificate to mark a blob as available
    public fun upload_availability_certificate(
        system: &WalrusSystem,
        certificate: AvailabilityCertificate,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if blob exists
        assert!(table::contains(&system.blobs, certificate.blob_id), EBlobNotFound);
        
        // Get blob
        let blob = table::borrow(&system.blobs, certificate.blob_id);
        
        // Check if sender is the owner of the blob
        assert!(blob.owner == tx_context::sender(ctx), EInvalidSigner);
        
        // Check if certificate has enough signatures (simplified)
        assert!(vector::length(&certificate.signatures) >= 1, EInvalidAvailabilityCertificate);
        
        // In a real implementation, we would verify the signatures
        
        // Emit availability event
        event::emit(BlobAvailableEvent {
            blob_id: certificate.blob_id,
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Get price per unit
    public fun get_price_per_unit(system: &WalrusSystem): u64 {
        system.price_per_unit
    }
    
    /// Set price per unit (admin only)
    public fun set_price_per_unit(
        system: &mut WalrusSystem,
        new_price: u64,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(tx_context::sender(ctx) == system.admin, EInvalidSigner);
        
        // Update price
        system.price_per_unit = new_price;
    }
} 