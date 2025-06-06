// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

/**
 * @title Auction
 * @dev Implements a bidding auction with refund and claim mechanisms.
 */
contract Auction {

    // === Structs ===
    struct Biders {
        address bider;
        uint256 value;
        uint256 idOffer;
        bool offerReclaimed;
    }

    // === State Variables ===
    Biders private winner; 
    Biders[] private biders; 

    address private immutable owner; 
    uint256 private immutable startTime;
    uint256 private constant AUCTIONDURATION = 7 days; 
    uint256 private constant MIN_BID_INCREMENT_PERCENT = 105;
    uint256 private constant FEE_PERCENT = 2;
    uint256 private constant REFACTOR = 100;
    uint256 private constant TIME_EXTENSION = 10 minutes; 
    uint256 private feeOwner;
    uint256 private partialClaims;
    uint256 private endTime;

    mapping(address => uint256) private numOffer; 
    mapping(address => uint256) private claims;

    // === Events ===
    event NewHighestBid(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime); 
    event FinalWinner(address indexed winner, uint256 amount); 

    // === Constructor ===
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + AUCTIONDURATION;
    }

  

    // === Modifiers ===
    modifier isActive() {
        require(block.timestamp < endTime, "Bid finished");
        _;
    }

    modifier isFinished() {
        require(block.timestamp > endTime, "Bid not finished yet");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner can run this function");
        _;
    }

    // === External Functions ===

    /// @notice Allows users to place a bid higher than the current one
    function bid() external payable isActive {
        require(msg.value > 0, "Bid must be greater than zero"); 
        require(msg.sender != address(0), "Invalid sender address"); 

        uint256 value = msg.value;
        address sender = msg.sender;
        uint256 offerWinning = _checkOffer(winner.value);

        if (value > offerWinning) {
            numOffer[sender]++;
            winner.value = value;
            winner.bider = sender;

            biders.push(Biders(sender, value, numOffer[sender], false));

            emit NewHighestBid(sender, value); 

            uint256 timeLeft = endTime - block.timestamp;
            if (timeLeft <= TIME_EXTENSION) {
                endTime += timeLeft;
                emit AuctionExtended(endTime); 
        }
        }

        
    }

    /// @notice Owner can refund the losing bidders and collect the fee after auction ends
    function refund() external onlyOwner isFinished {
        uint256 lengthOffers = biders.length;

        for (uint256 i = 0; i < lengthOffers; i++) {
            if (winner.bider == biders[i].bider && winner.value == biders[i].value) {
                feeOwner += _checkFee(biders[i].value);
            } else if (!biders[i].offerReclaimed) {
                feeOwner += _checkFee(biders[i].value);
                biders[i].value -= _checkFee(biders[i].value);
                claims[biders[i].bider] += biders[i].value;
            }
        }

        (bool success, ) = payable(owner).call{value: feeOwner}("");
        require(success, "Transfer Failed");

        emit FinalWinner(winner.bider, winner.value); 
    }

    /// @notice Allows a bidder to claim their refund
    function claim() external isFinished {
        require(claims[msg.sender] > 0, "No funds to claim"); 
        uint256 amount = claims[msg.sender];
        claims[msg.sender] = 0; 
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    /// @notice Allows partial claim of non-winning offers during active auction
    function partialClaim() external isActive {
        uint256 bidersLength = biders.length;
        for (uint256 i = 0; i < bidersLength; i++) {
            if (winner.bider == biders[i].bider && winner.value == biders[i].value) {
                continue;
            } else if (!biders[i].offerReclaimed) {
                biders[i].offerReclaimed = true;
                partialClaims += biders[i].value;
            }
        }

        uint256 amount = partialClaims;
        partialClaims = 0; 
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    /// @notice Returns the current highest bidder and value
    function showWinner() external view returns (Biders memory) {
        return winner;
    }

    /// @notice Returns the full list of bids
    function showOffers() external view returns (Biders[] memory) {
        return biders;
    }

    // === Internal Functions ===

    /// @dev Calculates the minimum value to beat the last offer
    function _checkOffer(uint256 lastOffer) private pure returns (uint256 offerChecked) {
        offerChecked = (lastOffer * MIN_BID_INCREMENT_PERCENT) / REFACTOR;
    }

    /// @dev Calculates fee from a bid
    function _checkFee(uint256 biderValue) private pure returns (uint256 fee) {
        fee = (biderValue * FEE_PERCENT) / REFACTOR;
    }
}
