/// DataStorage - Walrus-based storage for the LendX protocol
/// 
/// This contract handles storage of loan and collateral data:
/// - Uses Walrus for programmable on-chain storage
/// - Records loan agreements, collateral, repayments, liquidation logs
/// - Supports analytics, auditability, and historical access
/// - Stores user status, TwitterAI triggers, and other metadata
module data_storage::data_storage {
    use std::string::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set::{Self, VecSet};
    use walrus_mock::walrus_mock::{Self, WalrusSystem, AvailabilityCertificate};
    
    // === Error codes ===
    const EInvalidSigner: u64 = 0;
    const EBlobNotFound: u64 = 1;
    const EInvalidBlobData: u64 = 2;
    const EInsufficientStorage: u64 = 3;
    const EMetadataNotFound: u64 = 4;
    const EInvalidStorageResource: u64 = 5;
    
    // === Constants ===
    const LOAN_AGREEMENT_KEY: vector<u8> = b"loan_agreement";
    const COLLATERAL_DATA_KEY: vector<u8> = b"collateral_data";
    const REPAYMENT_HISTORY_KEY: vector<u8> = b"repayment_history";
    const LIQUIDATION_LOG_KEY: vector<u8> = b"liquidation_log";
    const USER_STATUS_KEY: vector<u8> = b"user_status";
    const TWITTER_AI_TRIGGER_KEY: vector<u8> = b"twitter_ai_trigger";
    
    // === Types ===
    
    /// Main storage object for data management
    struct DataManager has key {
        id: UID,
        // Admin address
        admin: address,
        // Protocol addresses with write permission
        authorized_writers: VecSet<address>,
        // Mapping of blob IDs to their metadata
        blob_metadata: Table<ID, BlobMetadata>,
        // Mapping of data types to their blob IDs
        data_index: VecMap<vector<u8>, VecSet<ID>>,
        // Walrus storage resource ID
        storage_resource_id: ID,
        // Total storage used (in bytes)
        total_storage_used: u64,
        // Storage capacity (in bytes)
        storage_capacity: u64,
    }
    
    /// Metadata for a stored blob
    struct BlobMetadata has store {
        // Blob ID
        id: ID,
        // Creator of the blob
        creator: address,
        // Creation timestamp
        creation_timestamp: u64,
        // Last update timestamp
        last_update_timestamp: u64,
        // Size of the blob (in bytes)
        size: u64,
        // Type of data (e.g., loan agreement, collateral data)
        data_type: vector<u8>,
        // Related entity ID (e.g., loan ID, user ID)
        related_entity_id: Option<ID>,
        // Content hash for verification
        content_hash: vector<u8>,
        // Whether the blob is active
        active: bool,
    }
    
    // === Events ===
    
    /// Emitted when a new blob is stored
    struct BlobStoredEvent has copy, drop {
        blob_id: ID,
        creator: address,
        data_type: vector<u8>,
        size: u64,
        timestamp: u64,
    }
    
    /// Emitted when a blob is updated
    struct BlobUpdatedEvent has copy, drop {
        blob_id: ID,
        updater: address,
        data_type: vector<u8>,
        new_size: u64,
        timestamp: u64,
    }
    
    /// Emitted when a blob is deleted
    struct BlobDeletedEvent has copy, drop {
        blob_id: ID,
        deleter: address,
        data_type: vector<u8>,
        timestamp: u64,
    }
    
    // === Public functions ===
    
    /// Initialize a new data manager
    public fun initialize(
        admin: address,
        walrus: &mut WalrusSystem,
        storage_capacity: u64,
        duration_epochs: u64,
        ctx: &mut TxContext
    ) {
        // Purchase storage resource from Walrus
        let storage_resource_id = walrus_mock::purchase_storage_resource(
            walrus,
            storage_capacity,
            duration_epochs,
            ctx
        );
        
        let authorized_writers = vec_set::empty();
        vec_set::insert(&mut authorized_writers, admin);
        
        let data_manager = DataManager {
            id: object::new(ctx),
            admin,
            authorized_writers,
            blob_metadata: table::new(ctx),
            data_index: vec_map::empty(),
            storage_resource_id,
            total_storage_used: 0,
            storage_capacity,
        };
        
        transfer::share_object(data_manager);
    }
    
    /// Add an authorized writer
    public fun add_authorized_writer(
        manager: &mut DataManager,
        writer: address,
        ctx: &mut TxContext
    ) {
        // Only admin can add writers
        assert!(tx_context::sender(ctx) == manager.admin, EInvalidSigner);
        
        // Add to set if not already present
        if (!vec_set::contains(&manager.authorized_writers, &writer)) {
            vec_set::insert(&mut manager.authorized_writers, writer);
        }
    }
    
    /// Remove an authorized writer
    public fun remove_authorized_writer(
        manager: &mut DataManager,
        writer: address,
        ctx: &mut TxContext
    ) {
        // Only admin can remove writers
        assert!(tx_context::sender(ctx) == manager.admin, EInvalidSigner);
        
        // Remove from set if present
        if (vec_set::contains(&manager.authorized_writers, &writer)) {
            vec_set::remove(&mut manager.authorized_writers, &writer);
        }
    }
    
    /// Store a new blob
    public fun store_blob(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        data_type: vector<u8>,
        content: vector<u8>,
        content_hash: vector<u8>,
        related_entity_id: Option<ID>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Check if sender is authorized
        let sender = tx_context::sender(ctx);
        assert!(vec_set::contains(&manager.authorized_writers, &sender), EInvalidSigner);
        
        // Calculate size of content
        let size = vector::length(&content);
        
        // Check if there's enough storage capacity
        assert!(manager.total_storage_used + size <= manager.storage_capacity, EInsufficientStorage);
        
        // Store blob using Walrus
        let blob_id = walrus_mock::store_blob(
            walrus,
            manager.storage_resource_id,
            content,
            content_hash,
            clock,
            ctx
        );
        
        // Create metadata
        let metadata = BlobMetadata {
            id: blob_id,
            creator: sender,
            creation_timestamp: clock::timestamp_ms(clock),
            last_update_timestamp: clock::timestamp_ms(clock),
            size,
            data_type,
            related_entity_id,
            content_hash,
            active: true,
        };
        
        // Add to metadata table
        table::add(&mut manager.blob_metadata, blob_id, metadata);
        
        // Update data index
        if (!vec_map::contains(&manager.data_index, &data_type)) {
            vec_map::insert(&mut manager.data_index, data_type, vec_set::empty());
        };
        let data_type_set = vec_map::get_mut(&mut manager.data_index, &data_type);
        vec_set::insert(data_type_set, blob_id);
        
        // Update storage used
        manager.total_storage_used = manager.total_storage_used + size;
        
        // Create availability certificate
        let certificate = walrus_mock::create_mock_availability_certificate(walrus, blob_id, ctx);
        
        // Upload availability certificate
        walrus_mock::upload_availability_certificate(walrus, certificate, clock, ctx);
        
        // Emit event
        event::emit(BlobStoredEvent {
            blob_id,
            creator: sender,
            data_type,
            size,
            timestamp: clock::timestamp_ms(clock),
        });
        
        blob_id
    }
    
    /// Update an existing blob
    public fun update_blob(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        blob_id: ID,
        new_content: vector<u8>,
        new_content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if sender is authorized
        let sender = tx_context::sender(ctx);
        assert!(vec_set::contains(&manager.authorized_writers, &sender), EInvalidSigner);
        
        // Check if blob exists
        assert!(table::contains(&manager.blob_metadata, blob_id), EBlobNotFound);
        
        // Get metadata
        let metadata = table::borrow_mut(&mut manager.blob_metadata, blob_id);
        
        // Check if blob is active
        assert!(metadata.active, EBlobNotFound);
        
        // Calculate size of new content
        let new_size = vector::length(&new_content);
        
        // Calculate size difference
        let size_diff = if (new_size > metadata.size) {
            new_size - metadata.size
        } else {
            0
        };
        
        // Check if there's enough storage capacity for increased size
        assert!(manager.total_storage_used + size_diff <= manager.storage_capacity, EInsufficientStorage);
        
        // In a real implementation, we would remove the old blob and store a new one
        // For our mock, we'll just update the metadata
        
        // Update storage used
        if (new_size > metadata.size) {
            manager.total_storage_used = manager.total_storage_used + size_diff;
        } else {
            manager.total_storage_used = manager.total_storage_used - (metadata.size - new_size);
        };
        
        // Update metadata
        metadata.size = new_size;
        metadata.content_hash = new_content_hash;
        metadata.last_update_timestamp = clock::timestamp_ms(clock);
        
        // Emit event
        event::emit(BlobUpdatedEvent {
            blob_id,
            updater: sender,
            data_type: metadata.data_type,
            new_size,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Delete a blob
    public fun delete_blob(
        manager: &mut DataManager,
        blob_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if sender is authorized
        let sender = tx_context::sender(ctx);
        assert!(vec_set::contains(&manager.authorized_writers, &sender), EInvalidSigner);
        
        // Check if blob exists
        assert!(table::contains(&manager.blob_metadata, blob_id), EBlobNotFound);
        
        // Get metadata
        let metadata = table::borrow_mut(&mut manager.blob_metadata, blob_id);
        
        // Check if blob is active
        assert!(metadata.active, EBlobNotFound);
        
        // Update storage used
        manager.total_storage_used = manager.total_storage_used - metadata.size;
        
        // Mark as inactive
        metadata.active = false;
        
        // Get data type
        let data_type = metadata.data_type;
        
        // Remove from data index
        if (vec_map::contains(&manager.data_index, &data_type)) {
            let data_type_set = vec_map::get_mut(&mut manager.data_index, &data_type);
            if (vec_set::contains(data_type_set, &blob_id)) {
                vec_set::remove(data_type_set, &blob_id);
            }
        };
        
        // Emit event
        event::emit(BlobDeletedEvent {
            blob_id,
            deleter: sender,
            data_type,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Get blob content
    public fun get_blob_content(
        walrus: &WalrusSystem,
        blob_id: ID
    ): vector<u8> {
        walrus_mock::retrieve_blob(walrus, blob_id)
    }
    
    /// Get blob metadata
    public fun get_blob_metadata(
        manager: &DataManager,
        blob_id: ID
    ): &BlobMetadata {
        // Check if blob exists
        assert!(table::contains(&manager.blob_metadata, blob_id), EBlobNotFound);
        
        // Return metadata
        table::borrow(&manager.blob_metadata, blob_id)
    }
    
    /// Get all blobs of a specific data type
    public fun get_blobs_by_type(
        manager: &DataManager,
        data_type: vector<u8>
    ): vector<ID> {
        // Check if data type exists in index
        if (!vec_map::contains(&manager.data_index, &data_type)) {
            return vector::empty<ID>()
        };
        
        // Get data type set
        let data_type_set = vec_map::get(&manager.data_index, &data_type);
        
        // Convert set to vector
        let result = vector::empty<ID>();
        let iter = vec_set::into_keys(*data_type_set);
        while (vector::length(&iter) > 0) {
            vector::push_back(&mut result, vector::pop_back(&mut iter));
        };
        
        result
    }
    
    /// Store loan agreement data
    public fun store_loan_agreement(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        loan_id: ID,
        agreement_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            LOAN_AGREEMENT_KEY,
            agreement_data,
            content_hash,
            option::some(loan_id),
            clock,
            ctx
        )
    }
    
    /// Store collateral data
    public fun store_collateral_data(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        collateral_id: ID,
        collateral_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            COLLATERAL_DATA_KEY,
            collateral_data,
            content_hash,
            option::some(collateral_id),
            clock,
            ctx
        )
    }
    
    /// Store repayment history
    public fun store_repayment_history(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        loan_id: ID,
        repayment_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            REPAYMENT_HISTORY_KEY,
            repayment_data,
            content_hash,
            option::some(loan_id),
            clock,
            ctx
        )
    }
    
    /// Store liquidation log
    public fun store_liquidation_log(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        loan_id: ID,
        liquidation_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            LIQUIDATION_LOG_KEY,
            liquidation_data,
            content_hash,
            option::some(loan_id),
            clock,
            ctx
        )
    }
    
    /// Store user status
    public fun store_user_status(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        user_id: ID,
        status_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            USER_STATUS_KEY,
            status_data,
            content_hash,
            option::some(user_id),
            clock,
            ctx
        )
    }
    
    /// Store Twitter AI trigger
    public fun store_twitter_ai_trigger(
        manager: &mut DataManager,
        walrus: &mut WalrusSystem,
        user_id: ID,
        trigger_data: vector<u8>,
        content_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        store_blob(
            manager,
            walrus,
            TWITTER_AI_TRIGGER_KEY,
            trigger_data,
            content_hash,
            option::some(user_id),
            clock,
            ctx
        )
    }
    
    /// Get all loan agreements
    public fun get_all_loan_agreements(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, LOAN_AGREEMENT_KEY)
    }
    
    /// Get all collateral data
    public fun get_all_collateral_data(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, COLLATERAL_DATA_KEY)
    }
    
    /// Get all repayment history
    public fun get_all_repayment_history(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, REPAYMENT_HISTORY_KEY)
    }
    
    /// Get all liquidation logs
    public fun get_all_liquidation_logs(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, LIQUIDATION_LOG_KEY)
    }
    
    /// Get all user statuses
    public fun get_all_user_statuses(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, USER_STATUS_KEY)
    }
    
    /// Get all Twitter AI triggers
    public fun get_all_twitter_ai_triggers(
        manager: &DataManager
    ): vector<ID> {
        get_blobs_by_type(manager, TWITTER_AI_TRIGGER_KEY)
    }
} 