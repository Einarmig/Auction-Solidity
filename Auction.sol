// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;


/* Devolucion softline:
1- claim() => no solicitado.
 
 Correccion: Borre la funcion y puse la logica de devolucion dentro del refund

2- Comentarios y documentacion de las funciones incompleto.

 Correccion: Aumente la documentación de las funciones no sé si es suficiente

3- Haces checkeos redundantes que podrías omitir.

 Correcion: Borre requires innecesarios de la funcion bid y otros se fueron al sacar la funcion claim

4- La implementación de eventos está presente, pero sería recomendable 
  incluir un evento para el reclamo de dinero, lo que ayudaría a comunicar el estado
  de la subasta de manera más efectiva

    Correcion: El evento fue colocado al final de partialRefund

5- No se están utilizando modificadores donde podrían ser convenientes. 
  Por ejemplo, podrías implementar un modificador para verificar si el usuario 
  tiene fondos disponibles antes de reclamar.

    Correccion: Agregue el modifir "canRefund"


/**
 * @title Auction
 * @dev Implements a bidding auction with refund and claim mechanisms.
 */
contract Auction {

    // === Structs ===
    struct Biders {
        address bider;
        uint256 value;
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
    uint256 private endTime;


    mapping(address => uint256) private balance;

    // === Events ===
    event NewHighestBid(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime); 
    event FinalWinner(address indexed winner, uint256 amount); 
    event PartialRefund(address indexed winner, uint256 amount);

    // === Constructor ===

    /**
     * @dev Initializes the auction contract and sets the owner and end time.
     */
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + AUCTIONDURATION;
    }

    // === Modifiers ===

    /**
     * @dev Ensures the auction is still ongoing.
     */
    modifier isActive() {
        require(block.timestamp < endTime, "Bid finished");
        _;
    }

    /**
     * @dev Ensures the auction has ended.
     */
    modifier isFinished() {
        require(block.timestamp > endTime, "Bid not finished yet");
        _;
    }

    /**
     * @dev Restricts function access to the contract owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner can run this function");
        _;
    }

    /**
     * @dev Ensures the caller has a refundable balance.
     */
    modifier canRefund() {
        require(balance[msg.sender] > 0, "Nothing to withdraw");
        _;
    }

    // === External Functions ===

    /**
     * @notice Allows users to place a new bid that is at least 5% higher than the current winning bid.
     * @dev Updates the winner - stores the bid
     * @dev Extend 10 minutes the auction if the new winner appears when the leftime is low than 10 minutes.
     */
    function bid() external payable isActive {
        require(msg.sender != address(0), "Invalid sender address"); 

        uint256 value = msg.value;
        address sender = msg.sender;
        uint256 offerWinning = _checkOffer(winner.value);

        if (value > offerWinning) {
            winner.value = value;
            winner.bider = sender;

            biders.push(Biders(sender, value));
            balance[sender] += value;

            emit NewHighestBid(sender, value); 

            uint256 timeLeft = endTime - block.timestamp;
            if (timeLeft <= TIME_EXTENSION) {
                endTime += timeLeft;
                emit AuctionExtended(endTime); 
            }
        }
    }

    /**
     * @notice Ends the auction, refunds losing bidders, and sends the fee to the owner.
     * @dev The owner collects a fee from each bid. 
     * @dev Losers are refunded their balance minus the fee.
     */
    function refund() external onlyOwner  isFinished {
        uint256 lengthOffers = biders.length;

        for (uint256 i = 0; i < lengthOffers; i++) {
            uint256 fee = _checkFee(biders[i].value);
            feeOwner += fee;
            if (winner.bider == biders[i].bider && winner.value == biders[i].value) {
                balance[biders[i].bider] = 0;
            } else {
                if (balance[biders[i].bider] > 0) {
                    (bool sentToBidder, ) = payable(biders[i].bider).call{value: balance[biders[i].bider]}("");
                    require(sentToBidder, "Transfer Failed");
                    balance[biders[i].bider] = 0;
                }
            }
        }

        (bool sentToOwner, ) = payable(owner).call{value: feeOwner}("");
        require(sentToOwner, "Transfer Failed");

        emit FinalWinner(winner.bider, winner.value); 
    }

    /**
     * @notice Allows a bidder to withdraw part of their balance during the auction.
     * @dev If the bidder is currently winning, only the non-winning part is withdrawable.
     */
    function partialRefund() external isActive canRefund {
        if (winner.bider == msg.sender) {
            balance[msg.sender] -= winner.value;
        }

        uint256 withdraw = balance[msg.sender];
        balance[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: withdraw}("");
        require(success, "Transfer Failed");

        emit PartialRefund(msg.sender, withdraw);
    }

    /**
     * @notice Returns the current highest bidder and their bid.
     * @return A struct containing the address and bid amount of the current winner.
     */
    function showWinner() external view returns (Biders memory) {
        return winner;
    }

    /**
     * @notice Returns all submitted bids.
     * @return An array of structs with each bidder and their respective bid.
     */
    function showOffers() external view returns (Biders[] memory) {
        return biders;
    }

    // === Internal Functions ===

    /**
     * @dev Calculates the minimum value required to outbid the current winner.
     * @param lastOffer The previous highest bid.
     * @return offerChecked The new minimum valid bid.
     */
    function _checkOffer(uint256 lastOffer) private pure returns (uint256 offerChecked) {
        offerChecked = (lastOffer * MIN_BID_INCREMENT_PERCENT) / REFACTOR;
    }

    /**
     * @dev Calculates the fee to be collected from a bid.
     * @param biderValue The amount bid by a user.
     * @return fee The calculated fee amount.
     */
    function _checkFee(uint256 biderValue) private pure returns (uint256 fee) {
        fee = (biderValue * FEE_PERCENT) / REFACTOR;
    }
}
