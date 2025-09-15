#[test_only]
module 0xYOUR_ADDRESS::my_nft_tests {
    use sui::test_scenario::{Self, Scenario, next_tx,};
    use crate::my_nft::{Self, MyNFT};

    // === Test Constants ===
    const ALICE: address = @0xADDE;

    // === Test Cases ===

    #[test]
    /// Tests that an NFT can be successfully minted and has the correct properties.
    fun test_mint_success() {
        // Initialize a new test scenario.
        let mut scenario = test_scenario::init(ALICE);

        // Start a transaction as ALICE.
        next_tx(&mut scenario, ALICE);
        {
            my_nft::mint(
                string::utf8(b"My Awesome NFT"),
                string::utf8(b"A description"),
                string::utf8(b"ipfs://..."),
                test_scenario::ctx(&mut scenario)
            );
        };

        // Check the results of the transaction.
        next_tx(&mut scenario, ALICE);
        {
            // Assert that ALICE now owns exactly one object of type MyNFT.
            assert!(test_scenario::count_of<MyNFT>(&scenario) == 1, 0);

            // Get the NFT object that ALICE owns.
            let nft = test_scenario::take_owned<MyNFT>(&mut scenario);

            // Assert that its properties are correct.
            assert!(my_nft::name(&nft) == &string::utf8(b"My Awesome NFT"), 1);
            assert!(my_nft::description(&nft) == &string::utf8(b"A description"), 2);

            // Put the NFT back in the scenario so it can be cleaned up.
            test_scenario::return_owned(&mut scenario, nft);
        };

        // End the test scenario.
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = crate::my_nft::ENameCannotBeEmpty)]
    /// Tests that minting an NFT with an empty name fails as expected.
    fun test_mint_fail_empty_name() {
        let mut scenario = test_scenario::init(ALICE);

        next_tx(&mut scenario, ALICE);
        {
            // This call should fail because the name is empty.
            my_nft::mint(
                string::utf8(b""), // Empty name
                string::utf8(b"A description"),
                string::utf8(b"ipfs://..."),
                test_scenario::ctx(&mut scenario)
            );
        };
        test_scenario::end(scenario);
    }

    #[test]
    /// Tests that an NFT can be successfully burned by its owner.
    fun test_burn_success() {
        let mut scenario = test_scenario::init(ALICE);

        // First, mint an NFT for ALICE.
        next_tx(&mut scenario, ALICE);
        {
            my_nft::mint(
                string::utf8(b"NFT to Burn"),
                string::utf8(b"..."),
                string::utf8(b"..."),
                test_scenario::ctx(&mut scenario)
            );
        };

        // In the next transaction, burn the NFT.
        next_tx(&mut scenario, ALICE);
        {
            let nft = test_scenario::take_owned<MyNFT>(&mut scenario);
            my_nft::burn(nft);
        };

        // In the final transaction, check that ALICE no longer has any NFTs.
        next_tx(&mut scenario, ALICE);
        {
            assert!(test_scenario::count_of<MyNFT>(&scenario) == 0, 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    /// Tests that an NFT's description can be updated.
    fun test_update_description_success() {
        let mut scenario = test_scenario::init(ALICE);
        let new_desc = string::utf8(b"This is the new description!");

        // Mint the NFT.
        next_tx(&mut scenario, ALICE);
        {
            my_nft::mint(
                string::utf8(b"Updatable NFT"),
                string::utf8(b"Original description"),
                string::utf8(b"..."),
                test_scenario::ctx(&mut scenario)
            );
        };

        // Update the description in the next transaction.
        next_tx(&mut scenario, ALICE);
        {
            let mut nft = test_scenario::take_owned<MyNFT>(&mut scenario);
            my_nft::update_description(&mut nft, new_desc);
            test_scenario::return_owned(&mut scenario, nft);
        };

        // Check if the description was updated.
        next_tx(&mut scenario, ALICE);
        {
            let nft = test_scenario::take_owned<MyNFT>(&mut scenario);
            assert!(my_nft::description(&nft) == &string::utf8(b"This is the new description!"), 0);
            test_scenario::return_owned(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }
}
