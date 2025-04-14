/// LendingCore - Main contract for the LendX protocol
/// 
/// This contract handles the core lending and borrowing functionality:
/// - LP deposits of stablecoins
/// - Borrower loan issuance with crypto collateral
/// - Interest accrual and repayments
/// - Price feed integration (Pyth)
/// - Liquidation logic
module lending_core::lending_core {
    use std::string::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use pyth_mock::pyth_mock::{Self, PriceFeeds};

    // === Error codes ===
    const EInsufficientCollateral: u64 = 0;
    const ELoanNotFound: u64 = 1;
    const ELoanNotUnderwater: u64 = 2;
    const EInvalidRepaymentAmount: u64 = 3;
    const EInsufficientLiquidity: u64 = 4;
    const EInvalidLoanDuration: u64 = 5;
    const EInvalidInterestRate: u64 = 6;
    const ELoanNotExpired: u64 = 7;
    const EInvalidCollateralValue: u64 = 8;

    // === Constants ===
    // Minimum collateralization ratio (e.g., 150%)
    const MIN_COLLATERALIZATION_RATIO: u64 = 150;
    // Liquidation threshold (e.g., 120%)
    const LIQUIDATION_THRESHOLD: u64 = 120;
    // Liquidation penalty percentage
    const LIQUIDATION_PENALTY: u64 = 10;
    // Base interest rate (annual, in basis points)
    const BASE_INTEREST_RATE_BPS: u64 = 500; // 5%
    // Seconds in a year for interest calculations
    const SECONDS_PER_YEAR: u64 = 31536000;
    
    // === Types ===
    
    /// Main storage object for the lending protocol
    struct LendingPool<phantom CoinType> has key {
        id: UID,
        // Total available liquidity
        liquidity: Balance<CoinType>,
        // Total borrowed amount
        total_borrowed: u64,
        // Interest rate model parameters
        utilization_optimal: u64,  // Optimal utilization point in basis points (e.g., 8000 = 80%)
        slope1: u64, // Interest rate slope below optimal utilization
        slope2: u64, // Interest rate slope above optimal utilization
        // Admin capabilities
        admin: address,
        // Last update timestamp
        last_update_timestamp: u64,
        // User accounts by address
        user_accounts: Table<address, UserAccount>,
    }
    
    /// Represents a user's account in the protocol
    struct UserAccount has store {
        // User's address
        owner: address,
        // Outstanding loans by ID
        loans: Table<ID, Loan>,
        // Total deposits
        deposit_amount: u64,
        // Last interest accrual timestamp
        last_accrual_timestamp: u64,
    }
    
    /// Represents a single loan
    struct Loan has store {
        // Loan ID
        id: ID,
        // Loan amount in the borrowed asset
        amount: u64,
        // Collateral amount in the respective asset
        collateral_amount: u64,
        // Collateral type
        collateral_type: String,
        // Interest rate at loan initiation (in basis points)
        interest_rate_bps: u64,
        // Loan origination timestamp
        origination_timestamp: u64,
        // Loan duration in seconds
        duration: u64,
        // Accumulated interest
        accrued_interest: u64,
        // Last interest accrual timestamp
        last_accrual_timestamp: u64,
    }
    
    // === Events ===
    
    /// Emitted when a user deposits liquidity
    struct DepositEvent has copy, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }
    
    /// Emitted when a user withdraws liquidity
    struct WithdrawEvent has copy, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }
    
    /// Emitted when a loan is created
    struct LoanCreatedEvent has copy, drop {
        borrower: address,
        loan_id: ID,
        amount: u64,
        collateral_amount: u64,
        collateral_type: String,
        interest_rate_bps: u64,
        duration: u64,
        timestamp: u64,
    }
    
    /// Emitted when a loan is repaid
    struct LoanRepaidEvent has copy, drop {
        borrower: address,
        loan_id: ID,
        repaid_amount: u64,
        remaining_principal: u64,
        interest_paid: u64,
        timestamp: u64,
    }
    
    /// Emitted when a loan is liquidated
    struct LiquidationEvent has copy, drop {
        borrower: address,
        loan_id: ID,
        liquidator: address,
        collateral_liquidated: u64,
        debt_covered: u64,
        timestamp: u64,
    }
    
    // === Public functions ===
    
    /// Initialize a new lending pool for a specific coin type
    public fun initialize<CoinType>(
        admin: address,
        utilization_optimal: u64,
        slope1: u64,
        slope2: u64,
        ctx: &mut TxContext
    ) {
        // Create new lending pool object
        let lending_pool = LendingPool<CoinType> {
            id: object::new(ctx),
            liquidity: balance::zero<CoinType>(),
            total_borrowed: 0,
            utilization_optimal,
            slope1,
            slope2,
            admin,
            last_update_timestamp: tx_context::epoch(ctx),
            user_accounts: table::new(ctx),
        };
        
        // Transfer ownership to sender
        transfer::share_object(lending_pool);
    }
    
    /// Supply liquidity to the lending pool
    public fun deposit<CoinType>(
        pool: &mut LendingPool<CoinType>,
        coin: Coin<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&coin);
        let deposit_balance = coin::into_balance(coin);
        
        // Update pool state
        balance::join(&mut pool.liquidity, deposit_balance);
        
        // Update interest accrual for the pool
        update_interest_accrual(pool, clock::timestamp_ms(clock));
        
        // Update user account
        if (!table::contains(&pool.user_accounts, sender)) {
            // Create new user account
            let user_account = UserAccount {
                owner: sender,
                loans: table::new(ctx),
                deposit_amount: amount,
                last_accrual_timestamp: clock::timestamp_ms(clock),
            };
            table::add(&mut pool.user_accounts, sender, user_account);
        } else {
            // Update existing user account
            let user_account = table::borrow_mut(&mut pool.user_accounts, sender);
            user_account.deposit_amount = user_account.deposit_amount + amount;
            user_account.last_accrual_timestamp = clock::timestamp_ms(clock);
        };
        
        // Emit deposit event
        event::emit(DepositEvent {
            user: sender,
            amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Withdraw liquidity from the lending pool
    public fun withdraw<CoinType>(
        pool: &mut LendingPool<CoinType>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<CoinType> {
        let sender = tx_context::sender(ctx);
        
        // Check if user has an account
        assert!(table::contains(&pool.user_accounts, sender), ELoanNotFound);
        let user_account = table::borrow_mut(&mut pool.user_accounts, sender);
        
        // Check if user has enough deposit
        assert!(user_account.deposit_amount >= amount, EInsufficientLiquidity);
        
        // Check if there's enough liquidity to withdraw
        let available_liquidity = balance::value(&pool.liquidity);
        assert!(available_liquidity >= amount, EInsufficientLiquidity);
        
        // Update interest accrual for the pool
        update_interest_accrual(pool, clock::timestamp_ms(clock));
        
        // Update user account
        user_account.deposit_amount = user_account.deposit_amount - amount;
        user_account.last_accrual_timestamp = clock::timestamp_ms(clock);
        
        // Extract balance and convert to coin
        let withdrawn_balance = balance::split(&mut pool.liquidity, amount);
        let withdrawn_coin = coin::from_balance(withdrawn_balance, ctx);
        
        // Emit withdraw event
        event::emit(WithdrawEvent {
            user: sender,
            amount,
            timestamp: clock::timestamp_ms(clock),
        });
        
        withdrawn_coin
    }
    
    /// Internal function to update interest accrual for the pool
    fun update_interest_accrual<CoinType>(
        pool: &mut LendingPool<CoinType>,
        current_timestamp: u64
    ) {
        // Calculate time elapsed since last update
        let time_elapsed = current_timestamp - pool.last_update_timestamp;
        if (time_elapsed == 0) return;
        
        // Update timestamp
        pool.last_update_timestamp = current_timestamp;
        
        // If no borrowed amount, nothing to do
        if (pool.total_borrowed == 0) return;
        
        // Calculate interest rate
        let interest_rate = calculate_interest_rate(pool);
        
        // Calculate interest accrued
        // Formula: total_borrowed * interest_rate * time_elapsed / SECONDS_PER_YEAR / 10000 (to convert bps to percentage)
        let interest_accrued = (pool.total_borrowed * interest_rate * time_elapsed) / (SECONDS_PER_YEAR * 10000);
        
        // Update total borrowed amount with accrued interest
        pool.total_borrowed = pool.total_borrowed + interest_accrued;
    }
    
    /// Update interest accrual for a specific loan
    fun update_loan_interest(
        loan: &mut Loan,
        current_timestamp: u64
    ) {
        // Calculate time elapsed since last update
        let time_elapsed = current_timestamp - loan.last_accrual_timestamp;
        if (time_elapsed == 0) return;
        
        // Update timestamp
        loan.last_accrual_timestamp = current_timestamp;
        
        // Calculate interest accrued
        // Formula: amount * interest_rate * time_elapsed / SECONDS_PER_YEAR / 10000 (to convert bps to percentage)
        let interest_accrued = (loan.amount * loan.interest_rate_bps * time_elapsed) / (SECONDS_PER_YEAR * 10000);
        
        // Update accrued interest
        loan.accrued_interest = loan.accrued_interest + interest_accrued;
    }
    
    /// Calculate current interest rate based on utilization
    fun calculate_interest_rate<CoinType>(pool: &LendingPool<CoinType>): u64 {
        let total_supply = balance::value(&pool.liquidity) + pool.total_borrowed;
        if (total_supply == 0) return BASE_INTEREST_RATE_BPS;
        
        let utilization_rate = (pool.total_borrowed * 10000) / total_supply;
        
        if (utilization_rate <= pool.utilization_optimal) {
            // Below optimal: base_rate + slope1 * utilization
            return BASE_INTEREST_RATE_BPS + (pool.slope1 * utilization_rate) / 10000;
        } else {
            // Above optimal: base_rate + slope1 * optimal + slope2 * (utilization - optimal)
            let base = BASE_INTEREST_RATE_BPS + (pool.slope1 * pool.utilization_optimal) / 10000;
            let excess_utilization = utilization_rate - pool.utilization_optimal;
            return base + (pool.slope2 * excess_utilization) / 10000;
        }
    }
    
    /// Create a new loan with collateral
    /// Note: Collateral handling will be done via the CrossChainCollateralManager
    public fun borrow<CoinType>(
        pool: &mut LendingPool<CoinType>,
        price_feeds: &PriceFeeds,
        amount: u64,
        collateral_amount: u64,
        collateral_type: String,
        duration: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<CoinType> {
        let sender = tx_context::sender(ctx);
        
        // Check if there's enough liquidity in the pool
        assert!(balance::value(&pool.liquidity) >= amount, EInsufficientLiquidity);
        
        // Check if duration is valid
        assert!(duration > 0, EInvalidLoanDuration);
        
        // Calculate interest rate for this loan
        let interest_rate_bps = calculate_interest_rate(pool);
        
        // Get collateral value using Pyth price feed
        let (collateral_value, _) = pyth_mock::get_price(price_feeds, collateral_type, clock);
        
        // Check if collateral value is sufficient
        // Collateral value should be at least MIN_COLLATERALIZATION_RATIO% of loan amount
        // Formula: collateral_value >= amount * MIN_COLLATERALIZATION_RATIO / 100
        assert!(collateral_value >= (amount * MIN_COLLATERALIZATION_RATIO) / 100, EInsufficientCollateral);
        
        // Create loan ID
        let loan_id = object::new(ctx);
        let loan_id_copy = object::uid_to_inner(&loan_id);
        object::delete(loan_id);
        
        // Create the loan
        let loan = Loan {
            id: loan_id_copy,
            amount,
            collateral_amount,
            collateral_type,
            interest_rate_bps,
            origination_timestamp: clock::timestamp_ms(clock),
            duration,
            accrued_interest: 0,
            last_accrual_timestamp: clock::timestamp_ms(clock),
        };
        
        // Add loan to user's account
        if (!table::contains(&pool.user_accounts, sender)) {
            // Create new user account
            let user_account = UserAccount {
                owner: sender,
                loans: table::new(ctx),
                deposit_amount: 0,
                last_accrual_timestamp: clock::timestamp_ms(clock),
            };
            table::add(&mut pool.user_accounts, sender, user_account);
        };
        
        // Get user account and add loan
        let user_account = table::borrow_mut(&mut pool.user_accounts, sender);
        table::add(&mut user_account.loans, loan_id_copy, loan);
        
        // Update pool state
        pool.total_borrowed = pool.total_borrowed + amount;
        
        // Create coin to return to borrower
        let borrowed_balance = balance::split(&mut pool.liquidity, amount);
        let borrowed_coin = coin::from_balance(borrowed_balance, ctx);
        
        // Emit loan created event
        event::emit(LoanCreatedEvent {
            borrower: sender,
            loan_id: loan_id_copy,
            amount,
            collateral_amount,
            collateral_type,
            interest_rate_bps,
            duration,
            timestamp: clock::timestamp_ms(clock),
        });
        
        borrowed_coin
    }
    
    /// Repay a loan (partial or full)
    public fun repay<CoinType>(
        pool: &mut LendingPool<CoinType>,
        loan_id: ID,
        repayment_coin: Coin<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let repayment_amount = coin::value(&repayment_coin);
        
        // Check if user has an account
        assert!(table::contains(&pool.user_accounts, sender), ELoanNotFound);
        let user_account = table::borrow_mut(&mut pool.user_accounts, sender);
        
        // Check if loan exists
        assert!(table::contains(&user_account.loans, loan_id), ELoanNotFound);
        let loan = table::borrow_mut(&mut user_account.loans, loan_id);
        
        // Update loan interest
        update_loan_interest(loan, clock::timestamp_ms(clock));
        
        // Calculate total debt (principal + interest)
        let total_debt = loan.amount + loan.accrued_interest;
        
        // Ensure repayment amount is not more than total debt
        assert!(repayment_amount <= total_debt, EInvalidRepaymentAmount);
        
        // Calculate how much goes to interest vs principal
        let interest_paid = if (repayment_amount <= loan.accrued_interest) {
            repayment_amount
        } else {
            loan.accrued_interest
        };
        
        let principal_paid = repayment_amount - interest_paid;
        
        // Update loan state
        loan.accrued_interest = loan.accrued_interest - interest_paid;
        loan.amount = loan.amount - principal_paid;
        
        // Add repayment to pool liquidity
        let repayment_balance = coin::into_balance(repayment_coin);
        balance::join(&mut pool.liquidity, repayment_balance);
        
        // Update pool state
        pool.total_borrowed = pool.total_borrowed - principal_paid;
        
        // If loan is fully repaid, remove it
        if (loan.amount == 0 && loan.accrued_interest == 0) {
            let Loan {
                id: _,
                amount: _,
                collateral_amount: _,
                collateral_type: _,
                interest_rate_bps: _,
                origination_timestamp: _,
                duration: _,
                accrued_interest: _,
                last_accrual_timestamp: _,
            } = table::remove(&mut user_account.loans, loan_id);
            
            // TODO: Release collateral via CrossChainCollateralManager
        };
        
        // Emit repayment event
        event::emit(LoanRepaidEvent {
            borrower: sender,
            loan_id,
            repaid_amount: repayment_amount,
            remaining_principal: loan.amount,
            interest_paid,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Check if a loan is underwater (collateral value below liquidation threshold)
    public fun is_underwater(
        price_feeds: &PriceFeeds,
        loan: &Loan,
        clock: &Clock
    ): bool {
        // Get collateral value using Pyth price feed
        let (collateral_value, _) = pyth_mock::get_price(price_feeds, loan.collateral_type, clock);
        
        // Calculate total debt (principal + interest)
        let total_debt = loan.amount + loan.accrued_interest;
        
        // Check if collateral value is below liquidation threshold
        // Formula: collateral_value < total_debt * LIQUIDATION_THRESHOLD / 100
        collateral_value < (total_debt * LIQUIDATION_THRESHOLD) / 100
    }
    
    /// Check if a loan is expired
    public fun is_expired(loan: &Loan, current_timestamp: u64): bool {
        current_timestamp > loan.origination_timestamp + loan.duration
    }
    
    /// Liquidate an underwater loan
    public fun liquidate<CoinType>(
        pool: &mut LendingPool<CoinType>,
        price_feeds: &PriceFeeds,
        borrower: address,
        loan_id: ID,
        liquidation_coin: Coin<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let liquidator = tx_context::sender(ctx);
        let liquidation_amount = coin::value(&liquidation_coin);
        
        // Check if borrower has an account
        assert!(table::contains(&pool.user_accounts, borrower), ELoanNotFound);
        let borrower_account = table::borrow_mut(&mut pool.user_accounts, borrower);
        
        // Check if loan exists
        assert!(table::contains(&borrower_account.loans, loan_id), ELoanNotFound);
        let loan = table::borrow_mut(&mut borrower_account.loans, loan_id);
        
        // Update loan interest
        update_loan_interest(loan, clock::timestamp_ms(clock));
        
        // Check if loan is underwater or expired
        let is_underwater_loan = is_underwater(price_feeds, loan, clock);
        let is_expired_loan = is_expired(loan, clock::timestamp_ms(clock));
        
        assert!(is_underwater_loan || is_expired_loan, ELoanNotUnderwater);
        
        // Calculate total debt (principal + interest)
        let total_debt = loan.amount + loan.accrued_interest;
        
        // Ensure liquidation amount is not more than total debt
        assert!(liquidation_amount <= total_debt, EInvalidRepaymentAmount);
        
        // Calculate how much collateral to liquidate
        // Add liquidation penalty
        let collateral_liquidated = (liquidation_amount * (100 + LIQUIDATION_PENALTY) / 100);
        
        // Ensure there's enough collateral
        assert!(collateral_liquidated <= loan.collateral_amount, EInvalidCollateralValue);
        
        // Update loan state
        if (liquidation_amount <= loan.accrued_interest) {
            loan.accrued_interest = loan.accrued_interest - liquidation_amount;
        } else {
            let remaining = liquidation_amount - loan.accrued_interest;
            loan.accrued_interest = 0;
            loan.amount = loan.amount - remaining;
        };
        
        loan.collateral_amount = loan.collateral_amount - collateral_liquidated;
        
        // Add liquidation payment to pool liquidity
        let liquidation_balance = coin::into_balance(liquidation_coin);
        balance::join(&mut pool.liquidity, liquidation_balance);
        
        // Update pool state
        pool.total_borrowed = pool.total_borrowed - liquidation_amount;
        
        // If loan is fully liquidated, remove it
        if (loan.amount == 0 && loan.accrued_interest == 0) {
            let Loan {
                id: _,
                amount: _,
                collateral_amount: _,
                collateral_type: _,
                interest_rate_bps: _,
                origination_timestamp: _,
                duration: _,
                accrued_interest: _,
                last_accrual_timestamp: _,
            } = table::remove(&mut borrower_account.loans, loan_id);
            
            // TODO: Release remaining collateral to borrower via CrossChainCollateralManager
        };
        
        // TODO: Transfer liquidated collateral to liquidator via CrossChainCollateralManager
        
        // Emit liquidation event
        event::emit(LiquidationEvent {
            borrower,
            loan_id,
            liquidator,
            collateral_liquidated,
            debt_covered: liquidation_amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }
    
    /// Get loan details
    public fun get_loan_details(
        pool: &LendingPool<CoinType>,
        borrower: address,
        loan_id: ID,
        clock: &Clock
    ): (u64, u64, u64, u64, u64, String) {
        // Check if borrower has an account
        assert!(table::contains(&pool.user_accounts, borrower), ELoanNotFound);
        let borrower_account = table::borrow(&pool.user_accounts, borrower);
        
        // Check if loan exists
        assert!(table::contains(&borrower_account.loans, loan_id), ELoanNotFound);
        let loan = table::borrow(&borrower_account.loans, loan_id);
        
        // Calculate time elapsed since last update
        let time_elapsed = clock::timestamp_ms(clock) - loan.last_accrual_timestamp;
        
        // Calculate interest accrued since last update
        let additional_interest = (loan.amount * loan.interest_rate_bps * time_elapsed) / (SECONDS_PER_YEAR * 10000);
        
        // Total accrued interest
        let total_interest = loan.accrued_interest + additional_interest;
        
        // Total debt
        let total_debt = loan.amount + total_interest;
        
        // Return loan details: amount, interest, total debt, collateral, expiry, collateral type
        (
            loan.amount,
            total_interest,
            total_debt,
            loan.collateral_amount,
            loan.origination_timestamp + loan.duration,
            loan.collateral_type
        )
    }
    
    // === Admin functions ===
    
    /// Update protocol parameters (admin only)
    public fun update_parameters<CoinType>(
        pool: &mut LendingPool<CoinType>,
        new_utilization_optimal: u64,
        new_slope1: u64,
        new_slope2: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool.admin, EInvalidSigner);
        
        pool.utilization_optimal = new_utilization_optimal;
        pool.slope1 = new_slope1;
        pool.slope2 = new_slope2;
    }
} 