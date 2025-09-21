# ðŸ† Digital Sports Memorabilia (Memorabilia)

> A decentralized registry for digital sports memorabilia, ensuring provable authenticity and scarcity on the Stacks blockchain.

## âœ¨ Features

ðŸ… **Authentic NFTs**: Create verified digital sports memorabilia with on-chain authenticity
ðŸ”’ **Scarcity Control**: Limited edition collections with enforced maximum supply
ðŸƒâ€â™‚ï¸ **Athlete Verification**: Permissioned creator system for verified athletes and organizations
ðŸ’° **Built-in Marketplace**: List, buy, and trade memorabilia with automatic royalty distribution
ðŸŽ¯ **Rich Metadata**: Store athlete info, sport, rarity, edition numbers, and timestamps
ðŸ“ˆ **Royalty System**: Creators earn ongoing royalties from secondary sales
âš¡ **SIP-009 Compliant**: Fully compatible with Stacks NFT standards

## ðŸš€ Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testnet/mainnet deployment

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Check contract compilation:

```bash
clarinet check
```

### Deployment

```bash
# Deploy to testnet
clarinet deployments generate --testnet
clarinet deployments apply --testnet

# Deploy to mainnet
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## ðŸ“‹ Contract Functions

### Admin Functions

#### `set-verified-creator`
Authorize creators (athletes, organizations) to mint memorabilia
```clarity
(contract-call? .Memorabilia set-verified-creator 'SP123... true)
```

### Minting Functions

#### `mint-memorabilia`
Mint new sports memorabilia (verified creators only)
```clarity
(contract-call? .Memorabilia mint-memorabilia 
  recipient-address
  "Michael Jordan"
  "Basketball"
  "Game-worn jersey from NBA Finals 1998"
  "Legendary"
  u100  ; max editions
  "https://metadata.uri/1"
  u500) ; 5% royalty
```

### Marketplace Functions

#### `list-for-sale`
List memorabilia for sale
```clarity
(contract-call? .Memorabilia list-for-sale u1 u1000000) ; 1 STX
```

#### `buy-memorabilia`
Purchase listed memorabilia (includes royalty distribution)
```clarity
(contract-call? .Memorabilia buy-memorabilia u1)
```

#### `unlist-from-sale`
Remove listing from marketplace
```clarity
(contract-call? .Memorabilia unlist-from-sale u1)
```

### Transfer Functions

#### `transfer`
Transfer memorabilia to another address
```clarity
(contract-call? .Memorabilia transfer u1 sender-address recipient-address)
```

### Query Functions

#### `get-token-metadata`
Retrieve complete token information
```clarity
(contract-call? .Memorabilia get-token-metadata u1)
```

#### `get-token-authenticity`
Check verification status and details
```clarity
(contract-call? .Memorabilia get-token-authenticity u1)
```

#### `get-collection-info`
Get supply information for a collection
```clarity
(contract-call? .Memorabilia get-collection-info "Michael Jordan" "Jersey")
```

## ðŸ—ï¸ Contract Architecture

### Core Components

- **NFT Token**: SIP-009 compliant non-fungible token
- **Metadata Storage**: Comprehensive athlete and item information
- **Authenticity System**: On-chain verification tracking
- **Scarcity Enforcement**: Collection-based supply limits
- **Marketplace**: Built-in trading functionality
- **Royalty System**: Creator compensation on secondary sales

### Data Structures

```clarity
; Token metadata structure
{
  athlete: (string-ascii 100),
  sport: (string-ascii 50),
  description: (string-ascii 500),
  rarity: (string-ascii 20),
  edition-number: uint,
  total-editions: uint,
  creation-timestamp: uint,
  uri: (string-ascii 256)
}
```

## ðŸ§ª Testing

```bash
# Run all tests
npm install
npm test

# Run specific test file
clarinet test tests/memorabilia_test.ts
```

## ðŸ”§ Development

### Local Development

```bash
# Start local blockchain
clarinet integrate

# Deploy contracts locally
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Contract Validation

```bash
# Check contract syntax and types
clarinet check

# Analyze contract
clarinet analyze
```

## ðŸ“Š Use Cases

ðŸ€ **Professional Sports**: Game-worn jerseys, signed equipment, historic moments
ðŸ† **Championships**: Limited edition commemorative items from major events
ðŸ“¸ **Collectibles**: Digital trading cards, rare photographs, exclusive content
ðŸŽ® **Gaming**: Esports memorabilia, tournament-specific items
ðŸŸï¸ **Venues**: Stadium-specific memorabilia, seat certificates, historic artifacts

## ðŸ›¡ï¸ Security Features

- **Creator Verification**: Only authorized addresses can mint
- **Supply Limits**: Enforced scarcity through collection caps
- **Ownership Validation**: All transfers verified on-chain
- **Authentic Metadata**: Immutable storage prevents tampering
- **Royalty Protection**: Built-in creator compensation

## ðŸ“„ License

This project is open source and available under the MIT License.

## ðŸ¤ Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ðŸ“ž Support

For support and questions, please open an issue in the repository.

---

*Built with â¤ï¸ for the sports community using Stacks blockchain technology* ðŸ—ï¸âš¡

# Digital-Sports-Memorabilia

