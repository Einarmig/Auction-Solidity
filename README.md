# 🧾 Auction Smart Contract 

This repository contains a smart contract for a decentralized auction system written in Solidity. It was developed as the final project of Module 2 in the smart contracts course.

## 📍 Overview

The contract manages a transparent and fair auction where multiple users can place bids on an item. It ensures fair competition, secure fund handling, and dynamic time management.

## 🛠️ Key Features

- Automatic auction initialization upon deployment.
- Bid reception with a required minimum increase of 5% over the current highest bid.
- Automatic refunds (with a 2% fee) to non-winning bidders when the auction ends.
- Partial refund claims for previous bids during the ongoing auction.
- Automatic auction time extension if a valid bid is placed within the last 10 minutes.
- Display of the current highest bidder and a full list of all bids.

## ✅ Implemented Features

| Feature                                              | Status |
|------------------------------------------------------|--------|
| Constructor initializes the auction                  | ✅     |
| Bidding function enforces +5% minimum increase       | ✅     |
| Winner and winning bid display                       | ✅     |
| Retrieval of all submitted bids                      | ✅     |
| Refunds to non-winners with 2% fee                   | ✅     |
| Deposit tracking by address                          | ✅     |
| Events for new bids and auction end                  | ✅     |
| Partial refunds allowed during the auction           | ✅     |
| Auto-extension of auction time                       | ✅     |
| Use of modifiers for time and access control         | ✅     |
| Deployed and verified on Sepolia testnet             | ✅     |

## 🚀 Deployment Details

- **Network**: Sepolia  tesnet
- **Contract Address**: 0xd4B2431cc892303F4f069C6Ab3303185Cec48a66
- **Verification**: ✅ Code verified on Etherscan



