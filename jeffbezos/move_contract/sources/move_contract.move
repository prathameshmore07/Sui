/*
/// Module: shady_coin
///
/// The official Shady Coin contract.
/// Features a fixed maximum supply and a decentralized vending machine
/// for minting. Trust is code. The rest is... business.
*/

// Replace 0xYOUR_ADDRESS with the actual address of the publisher.
module 0xYOUR_ADDRESS::shady_coin {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::event;

    // ==================
    // Errors
    // ==================
    const ESupplyDepleted: u64 = 1;
    const EIncorrectPayment: u64 = 2;

    // ==================
    // Structs & Constants
    // ==================

    /// The coin struct. Its name, SHADY, is the unique type.
    public struct SHADY has drop {}

    /// The total number of coins that will ever exist (1 Billion).
    const MAX_SUPPLY: u64 = 1_000_000_000;

    /// The price in SUI to mint 1 SHADY coin.
    /// 1,000,000 MIST = 0.001 SUI.
    const MINT_PRICE_PER_COIN: u66 = 1_000_000;

    /// The decentralized vending machine. It's a shared object that anyone
    /// can use. It holds the TreasuryCap and enforces the rules.
    public struct VendingMachine has key {
        id: UID,
        treasury_cap: TreasuryCap<SHADY>,
        /// Tracks how many coins have been minted so far.
        total_minted: u64,
        /// Holds the SUI paid to the machine.
        collected_sui: Balance<SUI>,
    }

    // ==================
    // Events
    // ==================
    public struct CoinMinted has copy, drop {
        minter: address,
        amount_minted: u64,
        sui_paid: u64,
    }

    // ==================
    // Init
    // ==================

    /// Runs once on publish. Creates the currency and locks the TreasuryCap
    /// inside the VendingMachine, then shares the machine publicly.
    fun init(witness: SHADY, ctx: &mut TxContext) {
        // Create the currency.
        let (treasury_cap, metadata) = coin::create_currency(
            witness, 2, b"SHADY", b"Shady Coin", b"Trust is code. The rest is... business.", option::none(), ctx
        );
        transfer::public_transfer(metadata, tx_context::sender(ctx));

        // Create the Vending Machine.
        let machine = VendingMachine {
            id: object::new(ctx),
            // IMPORTANT: The TreasuryCap is now owned by the machine, not a person.
            treasury_cap,
            total_minted: 0,
            collected_sui: balance::zero(),
        };

        // Share the machine so anyone can use it.
        transfer::share_object(machine);
    }

    // ==================
    // Entry Functions
    // ==================

    /// Public mint function. Anyone can call this to buy SHADY coins with SUI.
    public entry fun public_mint(
        machine: &mut VendingMachine,
        amount_to_mint: u64,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // Rule 1: Check if the max supply would be exceeded.
        assert!(machine.total_minted + amount_to_mint <= MAX_SUPPLY, ESupplyDepleted);

        // Rule 2: Check if the payment is correct.
        let required_payment = amount_to_mint * MINT_PRICE_PER_COIN;
        assert!(coin::value(&payment) == required_payment, EIncorrectPayment);

        // Take the payment and store it in the machine's balance.
        let payment_balance = coin::into_balance(payment);
        balance::join(&mut machine.collected_sui, payment_balance);

        // Update the total minted supply.
        machine.total_minted = machine.total_minted + amount_to_mint;

        // Mint the new coins and send them to the buyer.
        let new_coins = coin::mint(&mut machine.treasury_cap, amount_to_mint, ctx);
        transfer::public_transfer(new_coins, tx_context::sender(ctx));

        event::emit(CoinMinted {
            minter: tx_context::sender(ctx),
            amount_minted: amount_to_mint,
            sui_paid: required_payment,
        });
    }

    /// Allows the original publisher to withdraw the collected SUI.
    public entry fun withdraw_sui(machine: &mut VendingMachine, ctx: &mut TxContext) {
        let amount = balance::value(&machine.collected_sui);
        let withdrawn_sui = coin::from_balance(balance::split(&mut machine.collected_sui, amount), ctx);
        transfer::public_transfer(withdrawn_sui, tx_context::sender(ctx));
    }
}
