// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

    //==============================================================================//
    //                          Upated Lunch Venue Contract                         //
    //==============================================================================//

/// @title Updated contract to agree on the lunch venue
contract LunchVenue {

    //=======================================//
    //        Main Information Structs       //
    //=======================================//

    // Information about the voting friend
    struct Friend {
        string name; // The friend's name
        uint voted; // Indicates whether they've voted
    }

    // Information about the votable venues
    struct Venue {
        string name; // Venue's name
        uint votes; // How many votes this venue has
    }



    //=======================================//
    //        Publicly Accessible Info       //
    //=======================================//
    
    mapping (uint => Venue) public venues; // Map of all available venues, identified by a number
    mapping(address => Friend) public friends; // Map of friends who can vote, identified by address
    string public mostVotedVenue; // The current most popular venue, indicating chosen venue
    
    uint  internal numVenues; // Number of venues available to vote for
    uint  internal numFriends; // Number of friends who may vote
    uint internal numVotes; // Number of votes that have been made
    uint internal mostVotesVenueNumVotes; // Indicating the number of votes that the most popular venue has
    uint internal votingState; // [0 = pre-vote], [1 = voting], [2 = post-vote], describes the voting state
    uint internal startBlock = block.number; // The number of the block that will hold this contract
    uint internal timeoutPeriod = 50; // The amount of blocks after which the contract should be disabled
    address internal manager; // Manager of lunch venues



    //=======================================//
    //           Manager Constructor         //
    //=======================================//

    // Contract initializer, to set state on creation
    constructor () {
        manager = msg.sender; //Set the contract creator as the manager
    }



    //=======================================//
    //               Modifiers               //
    //=======================================//

    /// @notice Only manager can do (restricted to manager)
    modifier restricted() {
        require (msg.sender == manager, "Can only be executed by the manager");
        _;
    }

    /// @notice Only before the timeout period and before contract has been disabled
    modifier beforeDisabled() {
        require(votingState < 2, "Contract disabled, cannot update state");
        require(block.number < startBlock + timeoutPeriod, "Contract timeout, cannot update state");
        _;
    }



    //=======================================//
    //         Updating Voting State         //
    //=======================================//

    /// @notice Sets the next state of the voting process
    /// @dev Voting state may only progress forward (pre-vote -> vote -> post-vote)
    function nextState() public beforeDisabled restricted {
        ++votingState;
    }



    //=======================================//
    //       Updating State Information      //
    //=======================================//

    /// @notice Add a new friend who can vote on lunch venue, or add a venue which can be voted on
    /// @dev Friends and venues may be duplicated, it is not checked
    /// @param addr Friend's address, if adding a friend, or address(0) if adding a venue
    /// @param name Friend's name, or venue's name, depending on function usage
    /// @return Number of friends or venues added so far, depending on usage, or 0 if invalid use
    function addFriendOrVenue(string memory name, address addr) public beforeDisabled restricted returns (uint) {
        if (votingState == 0) { // Ensure voting period has not begun

            // Ensure zero address to indicate the addition of a new venue
            if (addr == address(0)) {
                venues[++numVenues].name = name;
                return numVenues;
            }

            // Valid friend address was given, hence add new friend
            friends[addr].name = name;
            return ++numFriends;
        }
        return 0;
    }



    //=======================================//
    //          Voting Functionality         //
    //=======================================//

    /// @notice Vote for a lunch venue
    /// @dev If any conditionals fail, a default value of false is returned, otherwise true (successful)
    /// @param venue Venue number being voted upon
    /// @return validVote Is the vote valid? A valid vote should be from a registered friend and to a registered venue
    function doVote(uint venue) public beforeDisabled returns (bool validVote){
        if (votingState == 1) { // Ensure that voting is enabled
            if (friends[msg.sender].voted == 0) { // Ensure voter may vote (only once)
                if (bytes(friends[msg.sender].name).length != 0) { //Ensure friend exists
                    if (bytes(venues[venue].name).length != 0) { //Ensure venue exists

                        friends[msg.sender].voted = 1; // Indicate that friend has voted
                        
                        // A new most-popular venue has been identified, update state
                        if (++venues[venue].votes > mostVotesVenueNumVotes) {
                            mostVotesVenueNumVotes = venues[venue].votes;
                            mostVotedVenue = venues[venue].name;
                        }
                        
                        // Quorum is met, disable the contract
                        if (++numVotes >= numFriends/2 + 1) {
                            votingState = 2;
                        }

                        return true;
                    }
                }
            }
        } 
    }
}