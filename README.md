
🧾 Auction Smart Contract 
This repository contains a decentralized auction smart contract developed in Solidity as part of the final project for Module 2 of the blockchain development course.

📍 Overview
The smart contract enables a transparent and fair auction system where multiple users can place bids for an item. It enforces strict bidding rules, manages deposits securely, and ensures proper refunds and timing mechanisms for a fair process.

⚙️ Features
Feature	Status
Auction initialized on deployment	✅
Bidding function (must exceed previous bid by at least 5%)	✅
Display current highest bidder	✅
View list of all bids	✅
Refunds to non-winning bidders with 2% fee	✅
Funds linked to bidder addresses	✅
Event: New bid placed	✅
Event: Auction ended	✅
Partial refund of previous bids during the auction	✅
Auto-extension if a valid bid is placed in the last 10 minutes	✅
Access and time control via modifiers	✅
Deployed and verified on Sepolia network	✅

🛠️ Functionalities
🧱 Constructor
Automatically initializes the auction with:

Start time

End time (7 days from deployment)

Owner address

💰 bid()
Allows users to place bids.

A valid bid must:

Be higher than the current winning bid by at least 5%.

Be submitted before the auction ends.

If a valid bid is placed in the last 10 minutes, the auction is extended by that amount.

🥇 showWinner()
Returns the current highest bidder and bid amount.

📜 showOffers()
Returns the full list of bidders and their bids.

💸 refund()
Can be called by the owner after the auction ends.

Refunds all non-winning bidders (minus a 2% fee).

Sends accumulated fee to the contract owner.

🔁 partialClaim()
Allows users to partially reclaim previous non-winning bids during the auction.

📤 claim()
After the auction ends, users can claim their remaining refundable amount.

🔐 Data Structures

struct Biders {
    address bider;
    uint256 value;
    uint256 idOffer;
    bool offerReclaimed;
}
Each bid is recorded with:

The bidder’s address

The bid value

A unique identifier

Whether the bid was already partially reclaimed

🧠 Contract Design Highlights
Security: Uses require validations, onlyOwner modifier, and secure refund mechanisms.

Fair Bidding Rules: Enforces minimum increments and auction timing logic.

Gas Efficiency: Minimal storage duplication and linear data structures.

Transparency: Emits events for new bids and auction finalization.

🧪 Deployment Details
Network: Sepolia

Contract Address: 0x123...abc (Replace with actual address)

Etherscan Verification: ✅ Source code publicly verified

📄 License
This project is licensed under the MIT License. See the LICENSE file for details.

