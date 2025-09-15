// Replace 0xYOUR_ADDRESS with your actual Sui address before publishing.
module 0xYOUR_ADDRESS::my_nft {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use sui::event;

    // ===============
    // Errors (NEW: Added a new error code)
    // ===============
    const ENameCannotBeEmpty: u64 = 1;

    // ===============
    // Structs
    // ===============

    public struct MyNFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String
    }

    // ===============
    // Events
    // ===============

    public struct NFTMinted has copy, drop {
        object_id: ID,
        creator: address,
        name: String,
    }

    // ===============
    // Entry Functions
    // ===============

    /// Mints a new NFT.
    public entry fun mint(
        name: String,
        description: String,
        image_url: String,
        ctx: &mut TxContext
    ) {
        // --- HARDENING CHECK (NEW) ---
        // Ensure the name string is not empty. If it is, the transaction will
        // safely abort with the ENameCannotBeEmpty error code.
        assert!(std::string::length(&name) > 0, ENameCannotBeEmpty);
        // -----------------------------

        let sender = tx_context::sender(ctx);
        let nft = MyNFT {
            id: object::new(ctx),
            name,
            description,
            image_url
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);
    }

    /// Burns (permanently destroys) an NFT. This function is inherently safe.
    public entry fun burn(nft: MyNFT) {
        let MyNFT { id, name: _, description: _, image_url: _ } = nft;
        object::delete(id);
    }

    /// Updates the description of an NFT. This function is inherently safe.
    public entry fun update_description(
        nft: &mut MyNFT,
        new_description: String,
    ) {
        nft.description = new_description;
    }

    // ===============
    // Getter Functions
    // ===============

    public fun name(nft: &MyNFT): &String {
        &nft.name
    }

    public fun description(nft: &MyNFT): &String {
        &nft.description
    }
}
