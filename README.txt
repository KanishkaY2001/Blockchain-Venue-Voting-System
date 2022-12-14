---------------------------------------------------------------------------------------------------

===================================
1. Participants may only vote once:
===================================

To solve the issue of allowing voters to place multiple votes, to monopolize a venue, I have utilized the Friend struct by adding a uint voted variable which dictates whether the voter has voted. Initially, this value is 0, which represents a non-vote, and as such, they may place a vote. However, after calling doVote function and successfully voting on a venue, this value becomes 1, which indicates that they have voted and may no longer vote. This is checked in the same function, where I check whether the value is 0, and if not, the vote may not be placed.

---------------------------------------------------------------------------------------------------

==================================
2. Stateful voting implementation:
==================================

To solve the issue of allowing new venues and friends to be added after voting starts, the doVote function utilises the votingState variable. This is essentially an enum state equivalent which represents the state of the contract. When this value is 0, it represents the pre-vote state, where friends and venues may be added. After this value becomes 1, by allowing the manager to call the nextState function, the state is essentially updated to the voting state. During this state, participants may vote on their favoured venue. After a quorum is reached, the state is automatically set to post-vote state, by setting votingState value to 2.

The reason that this works is because each of the functions in the contract makes use of the votingState by checking its value to ensure that the contract is in a specific state, before executing the code inside the conditional. For instance, the addFriendOrVenue function ensures that votingState is 0, as it represents pre-vote state. However, once voting begins, and the value of votingState is subsequently set to 1, you may notice that friends and venues may no longer be added. However, it is now possible to place votes using the doVote function. The nextState function, similarly, may also not be called after the votingState is set to 2, as it utilises the same beforeDisabled modifier, that ensures the votingState is less than 2.

The updated contract remains fairly transparent as voters may check which venues may be voted upon and the various friends who are voting on the venues by simply checking the venues and friends public mappings. If the voter is unsure of the ethereum addresses which exist in the friends mapping, they may visit etherscan and check the transactions that have taken place on the contract. This will, thereby, reveal the participant names and addresses. Unlike the original implementation, my updated version has made the numFriends and numVenues values internal, as it was not essential to have these as public, for the sake of saving some gas cost.

---------------------------------------------------------------------------------------------------

===========================
3. Contract timeout period:
===========================

Where the block number lacks, in providing an accurate stopwatch functionality, the wallclock time excels. However, its usage is not realistically feasible due to malicious users, network / syncing issues and the locality of nodes. Hence, although inconsistent, block numbers are comparatively more reliable.

The number to take into account is the block mining time, which on 03/06/2022 is 13.91. Albeit, this number fluctuates and to get a semi-accurate assumption, I have averaged, using mean, the average daily block times of the past month, from 1st of May to 1st of June. This resulted in 13.63 seconds, which I will use to estimate time.

I have chosen some arbitrary timeout period of 50, which represents 50 blocks into the future. This may be used as the timeout period to represent the timespan between the conception of the smart contract and lunch time. Using 50 blocks, this roughly equates to 11 minutes and 20 seconds ((50 * 13.63) / 60). Naturally, this value may be edited upon contract creation, but for the purpose of testing, this number seemed reasonable to work with. As such, any call made to the contract prior to (current block + 50th block) will be accepted. Subsequently, all other calls made afterwards will have no functional effect.

Added beforeDisabled modifier to all public functions to ensure that their core functionality may not be executed once the contract timeout period has passed. This is because the beforeDisabled modifier contains a require that checks for timeout. Through the use of this modifier, is it important to note that the contract may be disabled, in nature, without expicitly setting 'votingState' to 2, if a timeout occurs, as every function utilises this modifier.

Ethereum average mining time source:
https://ycharts.com/indicators/ethereum_average_block_time

---------------------------------------------------------------------------------------------------

==========================
4. Disabling the contract:
==========================

The 'votingState' and 'startBlock' + 'timeoutPeriod' state variables, produced for Tasks 2 and 3, respectively, serve a multi-purpose role in satisfying the requirement to essentially disable the lunch venue smart contract functionality.

All public functions (doVote, addFriendOrVenue, nextState) may not be called once 'votingState' is 2. There are two instances through which this may be achieved. The first is by allowing the manager to set the value to 2 manually by calling nextState function twice. The second is by allowing the doVote function to set 'votingState' to 2 , which is called automatically once a quorum is reached. If the contract timeout, defined in Task 3, is exceeded, the beforeDisabled modifier will similarly disable contract functionality, due to the use of require.

As such, once the value of 'votingState' is set to 2 and/or the timeout period is exceeded, the contract will cease to function as a lunch venue organizer. It is important to note that the state variables may still be viewed, but the core functionality is inaccessible. Moreover, 'votingState' cannot exceed a value of 2, as the nextState function may only execute if this value is less than 2.

---------------------------------------------------------------------------------------------------

================================
5. Gas Consumption Optimization:
================================

To approach this issue, I need to establish bounds. One such bound is the gas cost itself. Primarily, the cost of deploying the original source code, as per my LunchVenue.sol file is 1,281,233 million gas. If I am able to produce a solution which satisfies all five tasks provided in this assignment and prodive a gas cost that is lower than the original contract cost, then I believe that I have successfully optimized this contract adequately. Moreover, the cost to transact with the contract is another essential factor of consideration. As such, the same rule will be applied, and my overall goal will be to reduce gas costs for both the deployer and the transactors.

-> I started by checking the initial gas rate with the added functionality that was required by this assignment. It was currently costing 1.534 million gas to deploy this contract. I started the refactoring journey by removing direct variable declaration, because uint defaults to 0 value, and string defaults to empty. The variables affected initially were numVenues, numFriends, numVotes, and votedVenue.

-> Modified Friend struct and removed name, as it was primarily being used to detect whether a voter's address has been mapped or not. Hence, I needed another medium of verifying this - through the use of uint voted (originally bool voted). uint is more cost-effective, and also allows me to use it to set the state, with 0 being a default value (i.e. no mapping). When the value is 1, there is a mapping and a new friend exists. When the value is 2, this friend has voted. As such, this variable servers multiple purposes and is relatively condensed. I had to modify areas of the code where the name and voted variables were being used, so that the functionality of the program remains the same. The modified functions were addFriend and doVote. Following this process, I saw no use for the Friend struct, as it only held a single value (uint voted). Therefore, I omitted this struct, and remade the friends mapping as a mapping from address to a uint which represeted the friend's vote. Subsequently, the addFriend and doVote functions had to be modified to account for the changes. During this stage, I was at a deployment gas price of ~1.4 million

-> It is inefficient to increment a value on one line and use the same variable on another line. For example: x++; return x. Instead, I have condensed this into a single line (i.e. return ++x;) for the numFriends, numVotes, and numVenues  variables. As such, my canVote() modifier had to be refactored to account for these changes.

-> I saw that the voterAddress variable in the Vote struct was virtually useless because it was only set and never used functionally. Hence, I removed this variable and this allowed the Vote struct to be condensed into a single variable. Thus, no longer requiring a struct to store this information. Consequently, I omitted the Vote struct and redesigned the votes mapping between uint to uint, representing the link between vote number and the venue number. A modification to the doVote and finalResult functions was required and I also took this opportunity to move the if-statement, which checked if quorem was met, into the nested if-statement block. This is because a quorem may only be met once numVotes is incremented. Thus, there was no use for having this logic outside the nested loop. Moreover, it allowed me to remove the validVote bool variable as functions return false by default. Allowing me to only need to explicitly return true if a valid vote had been made.

-> I had realized that the votingState and startBlock variables were not internal, and because they served no real purpose to the voters, I have made them internal. I had considered making votingState public, but it is very simple for the manager to inform their friends to vote through message / group chat. As such, the manager would implicitly be telling the voters the value of votingState. Similarly, the manager variable served no purpose to be public, as the manager can simply inform any voters about their address, if asked or required. This info can then be validated by searching through etherscan, for example. Although, because there is friendship involved, it is assumed that there is also a level of trust. A primary concern for this design choice is that the manager variable had consumed around ~30,000 gas, which is highly unnecessary. The variables introduced by my own logic are also internal, and I assumed that the only important variables, which should be made public, are numVenues, venues, numFriends, friends, and mostVotedVenue, as this will allow the voters to know who the other voters are / how many there are, through address identification, and also the range of venues to choose from. The mostVotedVenue is essentially a substitute for votedVenue. However, the string value of this variable must not be considered until the voting process is over, either through quorum, timeout, or manager disabling the contract.

-> I was at 1.304 million gas at this point and I found that the finalResult() function, results mapping, along with its logic that stems through multiple functions was highly redundant. As such, I refactored the code by removing this for loop, which is highly inefficient in the blockchain space, and replaced this logic with a much more rudimentary and simple concept through the use of mostVotedVenue and mostVotesVenueNumVotes, which indicate the most voted upon venue and the number of votes that this venue has received, respectively. The doVote function ensures that these values are updated on-demand, and when necessary, by checking if the latest vote results in a more popular vote. As such, the voters may retrieve the chosen venue by inspecting the public mostVotedVenue variable. It is important to note, however, that this value should only be considered after the voting process is over, as mentioned above. This is because the string value is highly likely to change as friends vote, which, if inspected during the voting process, will likely result in an inaccurate reading of the chosen venue. However, with this in mind, the optimisation process has resulted in a current deployment gas cost of approximately 1,278,037 units.

-> A few days have passed and I came to a realization, after posting on Moodle forums, that I needed to include the name variable for the Friend struct. As such, I modified my code to make this inclusion. However, this had increased my deployment cost to 1.36 million gas. This goes against my set boundary. I found that a quick way to overcome this gas consumption increase is to combine the addVenue and addFriend functions, as, individually, they consumed too much gas (several 100,000). Therefore, I combined them into the addFriendOrVenue function which allows the manager to add friends by passing a valid address and a name. Moreover, if the manager passes a zero address, [address(0)], then the function will treat the operation such that the manager is attempting to add a venue. In this way, the function serves multiple purposes, while reducing gas cost. This does, however, make the marker's job a little more tedious as the function signature has changed. After this update, the deployment cost is approximately 1,226,055 units of gas.

-> During the production of unit tests, I noticed that there was sender address inconsistency, as addressed by James, and posted under week 2 in moodle. I had to make changes to my unit tests, and this had produced some errors on my end. As such, I adjusted my code by removing most of the modifiers and using if statements, where a modifier was used only once. However, I decided to keep the restricted and beforeDisabled modifiers, as they are used for multiple functions. After these changes, the deployment cost has become 1,226,955, which is only marginally higher than my previous lowest gas cost. As this allowed the unit tests to function, and allow the contract to operate as intended, I kept the changes and concluded my attempt to reduce gas costs.

In accorance to the bounds which have been set, the cost of this updated contract is exactly 54,278 units of gas cheaper than the original source code (1,281,233 gas), whilst also providing effective and efficient solutions to all issues that have been addressed on the assignment spec. Moreover, with the omission of the finalResult() function, which introduced an O(N) complexity, the worst case gas cost for a transactor is definitely lower than that which is offered by the original source code. The specific efficiency information to compare the costs of each contract has been provided below (which has been tested using injected web3, and the Ropseten testnet). Regardless, I have successfuly optimized gas consumption with my updated solution. I want to also note that these gas prices were taken directly from the Remix IDE during the period of working on this assignment (03/06/2022) - (08/06/2022), using the 0.8.0+commit.c7dfd78e compiler version, and also the JavaScript VM (London) Environment. As such, they should be taken with a grain of salt, when considering to launch with a different version, or during moments of fluctuating gas prices, in the near future. Most importantly, please read below for the gas costs, and observations made which explain how the updated source code helps to reduce gas consumption costs.


=================
Gas Cost Summary:
=================

LunchVenue.sol
==============
Contract Deployment: 0.002785287507 Ether (Costlier)

Adding Venues: 0.00057035 Ether (Cheaper)

Adding Friends: 0.000738105 Ether (Cheaper)

Voting On Venue: 0.00094891 Ether (Costlier)

Failure Vote: 0.0000603175 Ether (Costlier)

Total Eth Cost: 0.00510297 Ether (Overall Costlier)
---------------------------------------------------


LunchVenue_updated.sol
======================
Contract Deployment: 0.002667292507 Ether (Cheaper)

Adding Venues: 0.00064036 Ether (Costlier)

Adding Friends: 0.00079043 Ether (Costlier)

Changing State: 0.0001254525 Ether (Added Cost)

Voting On Venue: 0.00077122 Ether (Cheaper)

Failure Vote: 0.00006003 Ether (Cheaper)

Total Eth Cost: 0.005054785 Ether (Overall Cheaper)
---------------------------------------------------


My solution was ~0.94 % cheaper to use, in comparison to the original lunch venue contract. Moreover, it is important to note that my solution attempts to solve all five issues raised on the spec, and still remains slightly cheaper to deploy and invoke (overall), with varying trade-off costs for adding friends, venues, and voting on said venues.

Although the gas consumption difference is not substantial, the updated contract helps distribute the costs more evenly between participants. While the deployment cost for the updated contract is ~4.24% cheaper, the costs for adding venues and friends is costlier, by ~9.34%. This value is calculated by adding both costs together, as the ether costs are derived from calling the same function. 

However, the cost of voting is cheaper by a substantial ~18.72%, which I believe is a key element of what makes this solution better, in terms of saving gas consumption costs, as it is important to reduce invocation costs for participants. Moreover, it's important to recognise that these costs may not be accurate in the near future, due to gas fluctuation. As such, I believe that issue 9.5, as stated on the assignment spec, is satisfied.

---------------------------------------------------------------------------------------------------

==========================
6. Overall Voting Process:
==========================

The process would begin at the manager, as they deploy the smart contract. Following this, they will contact their friends and retrieve their crypto addresses which they will input to the contract using the addFriendOrVenue function, by passing the friend's address and name. After this, the manager will pick a number of potential venues to dine and add them to the contract using the addFriendOrVenue function, but this time, by passing a name and zero address [address[0]] to ensure that a venue is being added. When they are happy, they may begin the voting process by calling the nextState function which sets the contract to voting state. The manager may now inform their friends through text / message indicating that the voting process has begun, and provide a list of all venues along with their associated number. In reaction to this, the voters will proceed to check the public venues mapping to ensure that they are satisfied with their choice. After this, the voter will call the doVote function, while passing the venue number, to indicate their interest to have lunch at the location. To end this process, the manager will either disable the contract by calling the nextState function once more, the current block number will exceed the startBlock value, or a quorum, and thereby a decision, will be reached. The manager may now explain to the voters that the process has concluded and the voters may check the public mostVotedVenue variable to recognize the most popular, and voted for, venue. Following which, the manager and their friends may enjoy a delicious lunch! :D

---------------------------------------------------------------------------------------------------

====================================================
7. Unit tests for new functionality (53 test cases):
====================================================


1) Extending the Smart Contract Part 9.1:
=========================================
1.1 Check that voting is eligible before voters have voted for a venue
1.2 Check that duplicate votes cannot be made by friends


2) Extending the Smart Contract Part 9.2:
=========================================
2.1 Check that friends can be added before voting state (when state = 0)
2.2 Check that venues can be added before voting state (when state = 0)
2.3 Check that votes cannot be made before voting starts (before vote-open) (state = 0)
2.4 Check that the manager can set the next state
2.5 Check that friends cannot set the next state
2.6 Check that friends cannot be added after voting starts (state = 1)
2.7 Check that venues cannot be added after voting starts (state = 1)
2.8 Check that a single voter knows who all the other voters are
2.9 Check that a single voter knows all the venues that are available to vote
2.10 Check that a voter cannot vote after end-phase (state = 2)


3) Extending the Smart Contract Part 9.3:
=========================================
3.1 Check that votes are not registered after contract timeout
3.2 Check that friends cannot be added after contract timeout
3.3 Check that venues cannot be added after contract timeout
3.4 Check that the state cannot be changed after contract timeout


4) Extending the Smart Contract Part 9.4:
=========================================
4.1 Check that contract cannot be disabled by friends or others
4.2 Check that contract can be disabled by manager
4.3 Check that no friends can be added after contract disabled
4.4 Check that no venues can be added after contract disabled
4.5 Check that votes are not registered after contract disabled
4.6 Check that state cannot be changed after contract disabled




=======================================
8. Unit Testing Flow: updated_test.sol:
=======================================

TEST 0: (LunchVenue_ModifiedTests)
==================================
0.1 Modified version of given tests, that ensures everything works


TEST 1: (LunchVenue_UpdatedTests_General)
=========================================
2.1 Check that friends can be added before voting state (when state = 0)
2.2 Check that venues can be added before voting state (when state = 0)
1.1 Check that voting is eligible before voters have voted for a venue
2.3 Check that votes cannot be made before voting starts (before vote-open) (state = 0)
2.4 Check that the manager can set the next state
2.5 Check that friends cannot set the next state
2.6 Check that friends cannot be added after voting starts (state = 1)
2.7 Check that venues cannot be added after voting starts (state = 1)
2.8 Check that a single voter knows who all the other voters are
2.9 Check that a single voter knows all the venues that are available to vote
1.2 Check that duplicate votes cannot be made by friends
2.10 Check that a voter cannot vote after voting ends (state = 2)
2.11 Check that a venue has been selected after the voting has concluded


TEST 2: (LunchVenue_UpdatedTests_Disabled)
==========================================
2.1 Check that friends can be added before voting state (when state = 0)
2.2 Check that venues can be added before voting state (when state = 0)
3.1 Check that votes are not registered after contract timeout
3.2 Check that friends cannot be added after contract timeout
3.3 Check that venues cannot be added after contract timeout
3.4 Check that the state cannot be changed after contract timeout


TEST 3: (LunchVenue_UpdatedTests_Timeout)
=========================================
2.1 Check that friends can be added before voting state (when state = 0)
2.2 Check that venues can be added before voting state (when state = 0)
4.1 Check that contract cannot be disabled by friends or others
4.2 Check that contract can be disabled by manager
4.3 Check that no friends can be added after contract disabled
4.4 Check that no venues can be added after contract disabled
4.5 Check that votes are not registered after contract disabled
4.6 Check that state cannot be changed after contract disabled

