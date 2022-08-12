// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";


/* Errors */
error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** @title Raffle contract 
 *  @author Mason Sepulveda
 * @notice This contract contains an immutable decentralized smart contract tha
 * @dev This contract implements VRF v2 and Chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {

    /*Type declerations */
    enum RaffleState {
        OPEN, 
        CALCULATING
    } //uint256 0 = OPEN, 1 = CALCULATING


    /* State variables */
    address payable[] private s_players;
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_lastTimeStamp;
    uint256 private i_interval;

    //Lottery Variables
    address private s_recentWinner;
    RaffleState private s_raffleState;
    

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    /**
     * FUNCTIONS
     */


    function enterRaffle() public payable{
        
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        //Named events with the funtion named reversed
        emit RaffleEnter(msg.sender); 
    }

    /* @dev This is the function that the chainlink keeper nodes call
    * they look for the ^upkeepNeeded^ to return true.
    * The following should be ture in order to return true
    * 1.Our time interval should have passed
    * 2. The lottery should have 1 player, and have some ETH
    * 3. Then our subscription needs to be funded with LINK
    * 4. Lottery shoujld be in a "open" state.
    */
    function checkUpkeep(bytes memory /*checkData*/) 
            public override returns (bool upkeepNeeded, bytes memory /* performData */){
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

    }

    function performUpkeep(bytes calldata /* performData */) external override{
        //Request random number
        //once we get it, do something with it
        //2 transcation process
        (bool upkeepNeeded, ) = checkUpkeep("");

        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance, 
                s_players.length, 
                uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
            );
            emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) 
    internal 
    override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if(!success){
            revert Raffle__TransferFailed();
        }
        
        emit WinnerPicked(recentWinner);
    }

    /* View/Pure functions */
    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }
    //function pickRandomWinner() {}

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState){
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256){
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns(uint256) {
        return REQUEST_CONFIRMATIONS;
    }
    
    function getInterval() public view returns (uint256){
        return i_interval;
    }
}

//Raffle


// Enter the lottery (paying some amount)

//pick a random winner (verifiably random)

//winner to be selected every X minutes -> completely automated (chainlink keepers)