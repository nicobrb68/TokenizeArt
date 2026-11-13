# TokenizeArt — 42 Mulhouse - City Edition (`ART42`)

**Author:** `nbarbosa` (42 Mulhouse)  
**Network:** Ethereum Sepolia Testnet (`Chain ID: 11155111`)  
**Token Standard:** ERC-721 (`ERC721URIStorage` + `Ownable`, OpenZeppelin v5)

---

## 1. Project Overview & Technical Choices

This project implements a custom ERC-721 non-fungible token collection celebrating **42 Mulhouse** and its iconic landmarks (*Temple Saint-Étienne* and *Tour de l'Europe*).

### Why Ethereum Sepolia & ERC-721?
* **ERC-721 Standard:** Each token represents a unique, non-fungible digital asset with individual ownership (`ownerOf`) and metadata resolution (`tokenURI`).
* **Ethereum Sepolia:** Selected for full EVM compatibility, native support in MetaMask, Etherscan source code verification, and deterministic gas profiling.
* **OpenZeppelin Contracts:** Used for battle-tested `ERC721URIStorage` and `Ownable` access control primitives.

### Hybrid Storage Architecture (IPFS + 100% On-Chain SSTORE2)
To satisfy both decentralized off-chain storage and permanent on-chain art preservation, `TokenizeArt42` supports two minting modes:

1. **Decentralized IPFS Minting (`mintIPFS`) — Mandatory Part:**
   * Restricted to the contract owner (`onlyOwner`).
   * Links a token ID to an immutable IPFS Content Identifier (`ipfs://...`) hosting the JSON metadata and vector artwork.
2. **100% On-Chain Vector Inscription (`mintOnChain`) — Bonus Part:**
   * Open to any user on Sepolia (`public`).
   * The custom `20,717-byte` vector SVG (`assets/nbarbosa42.svg`) is stored directly in Ethereum contract bytecode using the **SSTORE2 pattern** (`0x00 STOP` opcode prefix + raw UTF-8 SVG bytes), split across two data contracts (`10,501 bytes` and `10,218 bytes`) to stay well below EVM contract size (EIP-170) and transaction gas limits (EIP-7825).
   * At mint time, `mintOnChain()` only records a boolean flag (`_isOnChain[tokenId] = true`), keeping minting gas low. When `tokenURI(tokenId)` is called, the contract dynamically reassembles the SVG via `EXTCODECOPY` and encodes both the SVG image and JSON metadata into Base64 `data:` URIs at **zero gas cost**.

---

## 2. Deployed Contracts & On-Chain Proofs (Sepolia)

| Component | Identifier / Address | Explorer / Reference |
| :--- | :--- | :--- |
| **ERC-721 Contract (`TokenizeArt42`)** | `0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b` | [Verified on Etherscan](https://sepolia.etherscan.io/address/0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b#code) / [Sourcify](https://sourcify.dev/server/repo-ui/11155111/0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b) |
| **SSTORE2 SVG Chunk #1** | `0xdC24EB1D4b2A0dEc73973FE71118b90156a233b6` | [View Bytecode on Etherscan](https://sepolia.etherscan.io/address/0xdC24EB1D4b2A0dEc73973FE71118b90156a233b6) |
| **SSTORE2 SVG Chunk #2** | `0x5752f776B35507529C893911b2c2546F66153FEF` | [View Bytecode on Etherscan](https://sepolia.etherscan.io/address/0x5752f776B35507529C893911b2c2546F66153FEF) |
| **IPFS Metadata URI** | `ipfs://bafkreidhzty33rqegajaqo75ilyvtoz4ri5ezzb66yn7mga5p2hwkxhveu` | [View via IPFS Gateway](https://ipfs.io/ipfs/bafkreidhzty33rqegajaqo75ilyvtoz4ri5ezzb66yn7mga5p2hwkxhveu) |
| **Token #1 Mint Tx (IPFS)** | `0xd41d6765052ad6df0af1465cd0e5c91abdb175dd9f0b260c3c6a2c64e25bee24` | [View Tx on Etherscan](https://sepolia.etherscan.io/tx/0xd41d6765052ad6df0af1465cd0e5c91abdb175dd9f0b260c3c6a2c64e25bee24) |
| **Token #2 Mint Tx (On-Chain)** | `0xca3cf0673d187c63491abd3d689f7ffd3b3168f1e116a1339221a0c02a624fad` | [View Tx on Etherscan](https://sepolia.etherscan.io/tx/0xca3cf0673d187c63491abd3d689f7ffd3b3168f1e116a1339221a0c02a624fad) |

---

## 3. Repository Structure

```text
TokenizeArt/
├── assets/                  # Original vector artwork (nbarbosa42.svg) & metadata.json
├── code/                    # Solidity smart contract (TokenizeArt42.sol)
├── deployment/              # Hardhat deployment & SSTORE2 bytecode linking script
├── documentation/           # Project documentation & deployment proofs (this file)
├── mint/                    # Minting & on-chain Base64 verification script
├── website/                 # Interactive Web3 DApp & collection explorer (index.html)
├── hardhat.config.ts        # Hardhat & Sepolia network configuration
└── package.json             # Node.js dependencies
```

---

## 4. Installation, Compilation & Usage

### Prerequisites
* **Node.js** (`v20+`) and **npm**
* **MetaMask** browser extension configured on **Ethereum Sepolia**

### Environment Setup
Create a `.env` file at the root of the repository (never commit this file):
```env
PRIVATE_KEY="0x..."
ETHERSCAN_API_KEY="..."
CONTRACT_ADDRESS="0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b"
METADATA_URI="ipfs://bafkreidhzty33rqegajaqo75ilyvtoz4ri5ezzb66yn7mga5p2hwkxhveu"
```

### Compile & Run Scripts
```bash
# Install dependencies
npm install

# Compile Solidity smart contract
npx hardhat compile

# Run mint & on-chain Base64 integrity verification
npx hardhat run mint/mint.ts --network sepolia
```

### Launch the Minting DApp & Collection Explorer
```bash
python3 -m http.server 8081 --directory website
```
Open `http://localhost:8081` in your browser to inspect both minted tokens, verify the live SSTORE2 reassembly, import tokens directly into MetaMask (`wallet_watchAsset`), or mint a new on-chain edition.
