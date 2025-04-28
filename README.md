# DecentralAuction

A decentralized auction platform built on blockchain technology for transparent and secure digital asset auctions.

## Overview

DecentralAuction is a smart contract-based auction system that allows users to create, bid on, and finalize auctions for digital assets without the need for intermediaries. The platform ensures transparency, prevents fraud, and automatically handles the transfer of assets and funds upon auction completion.

## Features

- **Create Auctions**: Users can create auctions for their digital assets, setting details like name, description, URI, duration, and starting price.
- **Bidding System**: Simple and transparent bidding process that ensures all bids are publicly verifiable.
- **Automated Settlement**: When auctions end, winners can claim their assets while creators receive payment automatically.
- **Fee Structure**: A transparent platform fee system that sustains development and operation.
- **Early Auction Ending**: Creators can end auctions early if needed.
- **Auction Cancellation**: Creators can cancel auctions that haven't received any bids.

## Contract Functions

### Read-Only Functions

- `get-auction`: Retrieve details about a specific auction
- `get-bid`: View bid information from a specific bidder on an auction
- `auction-exists`: Check if an auction exists
- `is-auction-active`: Verify if an auction is still active
- `has-auction-ended`: Check if an auction has ended
- `get-current-auction-id`: Get the next available auction ID
- `get-platform-fee-bps`: View the current platform fee percentage
- `calculate-platform-fee`: Calculate the platform fee for a given amount

### Public Functions

- `create-auction`: Create a new auction for a digital asset
- `place-bid`: Place a bid on an active auction
- `end-auction-early`: End an auction before its scheduled end time
- `claim-asset`: Claim an asset as the winning bidder
- `cancel-auction`: Cancel an auction that hasn't received any bids
- `update-platform-fee`: Admin function to update the platform fee
- `transfer-ownership`: Admin function to transfer contract ownership

## Getting Started

### Prerequisites

- A Stacks wallet
- STX tokens for transaction fees and bids

### Creating an Auction

1. Prepare your digital asset details (name, description, URI)
2. Determine auction duration and starting price
3. Call the `create-auction` function with these parameters

### Placing a Bid

1. Find an active auction using its ID
2. Ensure your bid exceeds the current highest bid
3. Call the `place-bid` function with the auction ID and your bid amount

### Claiming an Asset

1. Wait for the auction to end
2. If you're the highest bidder, call the `claim-asset` function
3. The asset will be transferred to you, and funds will be sent to the creator

## Platform Fees

The platform charges a small fee (default 5%) on successful auctions to sustain development and operation. This fee is automatically calculated and distributed when assets are claimed.

## Security Considerations

- All transactions are verified on-chain
- Only auction creators can end or cancel their auctions
- Only the highest bidder can claim assets after an auction ends
- Smart contract ownership is transferable for long-term sustainability

## Future Development

- Integration with NFT standards
- Multi-currency support
- Auction extensions for last-minute bids
- Featured auctions and discovery system
- Dispute resolution mechanism

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.