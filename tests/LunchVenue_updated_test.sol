// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.00 < 0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix
import "remix_accounts.sol";
import "../contracts/LunchVenue_updated.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol";


    //==============================================================================//
    //                            Upated Lunch Venue Tests                          //
    //==============================================================================//

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'LunchVenue' contract
contract LunchVenue_ModifiedTests is LunchVenue {
    using BytesLib for bytes;

    //=======================================//
    //   Modified version of original tests  //
    //=======================================//

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are 'beforeEach', 'beforeAll', 'afterEach', & 'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);      // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Account at zero index (account-0) is default account, so manager will be set to acc0
    function managerTest() public {
        Assert.equal(manager, acc0, "Manager should be acc0");
    }

    /// Add lunch venue as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is considered as the sender
    function setLunchVenue() public {
        // Call addFriendOrVenue and pass address(0) to indicate that venues are being created
        Assert.equal(addFriendOrVenue("Courtyard Cafe", address(0)), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Uni Cafe", address(0)), 2, "Should be equal to 2");
    }
    
    /// Try to add lunch venue as a user other than manager. This should fail
    /// #sender: account-2
    function setLunchVenueFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Atomic Cafe", address(0)));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Can only be executed by the manager", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    /// Set friends as account-0
    /// #sender doesn't need to be specified explicitly for account-0
    function setFriend() public {
        // Call addFriendOrVenue and pass valid address to indicate that friends are being added
        Assert.equal(addFriendOrVenue("Alice", acc0), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Bob", acc1), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Charlie", acc2), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Eve", acc3), 4, "Should be equal to 4");
    }

    /// Try adding friend as a user other than manager. This should fail
    /// #sender: account-2
    function setFriendFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Daniels", acc4));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Can only be executed by the manager", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    /// Manager will set state to voting state (state = 1)
    function setNextState() public {
        nextState();
    }

    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), "Voting result should be true");
    }

    /// Try voting as a user not in the friends list. This should fail
    /// #sender: account-4
    function voteFailure() public {
        Assert.equal(doVote(1), false, "Voting result should be false");
    }

    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(mostVotedVenue, "Uni Cafe", "Selected venue should be Uni Cafe");
    }

    /// Verify voting is now closed
    function voteOpenTest() public {
        // state = 2 represents contract disabled, so voting is thereby closed
        Assert.equal(votingState, 2, "Voting should be closed");
    }

    /// Verify voting after vote closed. This should fail
    /// #sender: account-2
    function voteAfterClosedFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }
}


contract LunchVenue_UpdatedTests_General is LunchVenue {
    using BytesLib for bytes;

    //=======================================//
    //     General Functionality Testing     //
    //=======================================//

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are 'beforeEach', 'beforeAll', 'afterEach', & 'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);      // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    // 2.1 Check that friends can be added before voting state (when state = 0)
    function checkFriendsAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Alice", acc0), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Bob", acc1), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Charlie", acc2), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Eve", acc3), 4, "Should be equal to 4");
    }

    // 2.2 Check that venues can be added before voting state (when state = 0)
    function checkVenuesAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Venue 1", address(0)), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Venue 2", address(0)), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Venue 3", address(0)), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Venue 4", address(0)), 4, "Should be equal to 4");
        Assert.equal(addFriendOrVenue("Venue 5", address(0)), 5, "Should be equal to 5");
    }

    // 1.1 Check that voting is eligible before voters have voted for a venue
    function checkVotingEligibilityBeforeVote() public {
        // basically ensuring that everyone's voted = 0, to ensure that they may vote later
        Assert.equal(friends[acc0].voted, 0, "Should be equal to 0 (Has not voted yet)");
        Assert.equal(friends[acc1].voted, 0, "Should be equal to 0 (Has not voted yet)");
        Assert.equal(friends[acc2].voted, 0, "Should be equal to 0 (Has not voted yet)");
        Assert.equal(friends[acc3].voted, 0, "Should be equal to 0 (Has not voted yet)");
    }

    // 2.3 Check that votes cannot be made before voting starts (before vote-open) (state = 0)
    /// #sender: account-2
    function checkVotingNotPossibleBeforeVote() public {
        doVote(1);
        Assert.equal(doVote(1), false, "Cannot vote before voting begins");
    }

    //2.4 Check that the manager can set the next state
    function checkManagerCanSetNextState() public {
        Assert.equal(votingState, 0, "State should be 0, meaning pre-voting state");
        nextState(); // set state to 1, meaning voting state
        Assert.equal(votingState, 1, "State should be 1, meaning voting state");
    }

    //2.5 Check that friends cannot set the next state
    /// #sender: account-3
    function checkFriendsCannotSetNextState() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("nextState()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Can only be executed by the manager", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    //2.6 Check that friends cannot be added after voting starts (state = 1)
    function checkFriendsCantBeAddedAfterVotingStarts() public {
        Assert.equal(numFriends, 4, "Number of friends currently 4");
        addFriendOrVenue("Michael", acc4);
        Assert.equal(numFriends, 4, "Number of friends remains unchanged");
    }

    //2.7 Check that venues cannot be added after voting starts (state = 1)
    function checkVenuesCantBeAddedAfterVotingStarts() public {
        Assert.equal(numVenues, 5, "Number of venues currently 5");
        addFriendOrVenue("Venue 6", address(0));
        Assert.equal(numVenues, 5, "Number of venues remains unchanged");
    }

    // 2.8 Check that a single voter can know who all the other voters are
    // #sender: account-1
    function checkVoterKnowsOtherVoters() public {
        Assert.equal(friends[acc0].name, "Alice", "Should be Alice (Manager)");
        Assert.equal(friends[acc1].name, "Bob", "Should be Bob (Friend)");
        Assert.equal(friends[acc2].name, "Charlie", "Should be Charlie (Friend)");
        Assert.equal(friends[acc3].name, "Eve", "Should be Eve (Friend)");
        Assert.equal(friends[acc4].name, "", "Should be Empty String (No more voters)");
    }

    // 2.9 Check that a single voter knows all the venues that are available to vote
    // #sender: account-1
    function checkVoterKnowsAvailableVenues() public {
        Assert.equal(venues[1].name, "Venue 1", "Should be Venue 1");
        Assert.equal(venues[2].name, "Venue 2", "Should be Venue 2");
        Assert.equal(venues[3].name, "Venue 3", "Should be Venue 3");
        Assert.equal(venues[4].name, "Venue 4", "Should be Venue 4");
        Assert.equal(venues[5].name, "Venue 5", "Should be Venue 5");
        Assert.equal(venues[6].name, "", "No other available venues");
    }

    /// Vote as Charlie (acc2)
    /// #sender: account-2
    function bobVotesOnce() public {
        Assert.equal(friends[acc2].voted, 0, "Failed with unexpected reason");
        doVote(2);
        Assert.equal(friends[acc2].voted, 1, "Failed with unexpected reason");
    }

    // 1.2 Check that duplicate votes cannot be made by friends
    /// Vote as Charlie (acc2)
    /// #sender: account-2
    function bobCantVoteTwice() public {
        Assert.equal(numVotes, 1, "Only 1 vote has been made");
        Assert.equal(doVote(2), false, "Failed with unexpected reason");
        // The contract does not accept duplicate votes, so no new votes should be added
        Assert.equal(numVotes, 1, "Still only 1 vote should exist");
    }

    // Sets the state to 2, meaning contract disabled, and voting stage is concluded
    function concludeVotingStage() public {
        nextState();
    }

    // 2.10 Check that a voter cannot vote after voting ends (state = 2)
    /// Vote as Eve (acc3)
    /// #sender: account-3
    function voterCantVoteAfterVotingEnds() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 2));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    // 2.11 Check that a venue has been successfully selected after the voting has concluded
    function checkVenueHasBeenPicked() public {
        // This will be the venue that the manager and friends will dine at
        Assert.equal(mostVotedVenue, "Venue 2", "Venue 2 has 2 votes, and it should be picked");
    }
}



contract LunchVenue_UpdatedTests_Disabled is LunchVenue {
    using BytesLib for bytes;

    //=======================================//
    //       Disabled Contract Testing       //
    //=======================================//

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are 'beforeEach', 'beforeAll', 'afterEach', & 'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);      // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    // 2.1 Check that friends can be added before voting state (when state = 0)
    function checkFriendsAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Alice", acc0), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Bob", acc1), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Charlie", acc2), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Eve", acc3), 4, "Should be equal to 4");
    }

    // 2.2 Check that venues can be added before voting state (when state = 0)
    function checkVenuesAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Venue 1", address(0)), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Venue 2", address(0)), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Venue 3", address(0)), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Venue 4", address(0)), 4, "Should be equal to 4");
        Assert.equal(addFriendOrVenue("Venue 5", address(0)), 5, "Should be equal to 5");
    }
    
    // 4.1 Check that contract cannot be disabled by friends or others
    /// Vote as Charlie
    /// #sender: account-2
    function friendsCannotDisableContract() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("nextState()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Can only be executed by the manager", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    // 4.2 Check that contract can be disabled by manager
    function managerDisablesContract() public {
        nextState();
        nextState();
        // By setting next state twice, setting state = 2, this indicates that contract is disabled
        Assert.equal(votingState, 2, "State should be 2, meaning disabled contract");
    }

    // 4.3 Check that no friends can be added after contract disabled
    function checkFriendsCantBeAddedAfterDisabled() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Michael", acc4));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    // 4.4 Check that no venues can be added after contract disabled
    function checkVenuesCantBeAddedAfterDisabled() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Venue 7", address(0)));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    /// Vote as Charlie
    /// #sender: account-2
    // 4.5 Check that votes are not registered after contract disabled
    function checkVotesDontWorkAfterDisabled() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }

    // 4.6 Check that state cannot be changed after contract disabled
    function checkStateCantBeUpdatedAfterDisabled() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("nextState()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract disabled, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }
}



contract LunchVenue_UpdatedTests_Timeout is LunchVenue {
    using BytesLib for bytes;

    //=======================================//
    //       Contract Timeout Testing        //
    //=======================================//

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are 'beforeEach', 'beforeAll', 'afterEach', & 'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);      // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    // 2.1 Check that friends can be added before voting state (when state = 0)
    function checkFriendsAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Alice", acc0), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Bob", acc1), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Charlie", acc2), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Eve", acc3), 4, "Should be equal to 4");
    }
    

    // 2.2 Check that venues can be added before voting state (when state = 0)
    function checkVenuesAddedBeforeVote() public {
        Assert.equal(addFriendOrVenue("Venue 1", address(0)), 1, "Should be equal to 1");
        Assert.equal(addFriendOrVenue("Venue 2", address(0)), 2, "Should be equal to 2");
        Assert.equal(addFriendOrVenue("Venue 3", address(0)), 3, "Should be equal to 3");
        Assert.equal(addFriendOrVenue("Venue 4", address(0)), 4, "Should be equal to 4");
        Assert.equal(addFriendOrVenue("Venue 5", address(0)), 5, "Should be equal to 5");
    }

    // Simulating the situation where timeout happened before quorum reached
    function simulateTimeoutHappened() public {
        /*
            The modifier 'beforeDisabled' checks if current block number is less than 
            startBlock + timeoutPeriod. As both of the latter variables are 0, the current
            block number can never be less than 0. As such, the condition will fail, resulting
            in the ability to simulate the situation in which a timeout has occured.
        */
        
        // Setting timeout period to 0 and start block to 0
        timeoutPeriod = 0;
        startBlock = 0;
        Assert.equal(timeoutPeriod, startBlock, "Something went wrong, not equal, not 0");
    }

    // 3.1 Check that votes are not registered after contract timeout
    /// Vote as Charlie
    /// #sender: account-2
    function checkVotesDontWorkAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract timeout, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }


    // 3.2 Check that friends cannot be added after contract timeout
    function checkFriendsCantBeAddedAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Michael", acc4));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract timeout, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }


    // 3.3 Check that venues cannot be added after contract timeout
    function checkVenuesCantBeAddedAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriendOrVenue(string,address)", "Venue 6", address(0)));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract timeout, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }


    // 3.4 Check that the state cannot be changed after contract timeout
    function checkStateCantBeUpdatedAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("nextState()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, "Contract timeout, cannot update state", "Failed with unexpected reason");
        } else {
            Assert.ok(false, "Method Execution should fail");
        }
    }
}