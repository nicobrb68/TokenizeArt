# Default contract address on Ethereum Sepolia (overridden by .env if present)
-include .env
export

CONTRACT_ADDRESS ?= 0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b
PORT ?= 8081

.PHONY: all install compile deploy mint verify web info clean fclean re help

# Default target: install dependencies and compile smart contracts
all: install compile

# Install Node.js dependencies
install:
	npm install

# Compile Solidity contracts with Hardhat
compile:
	npx hardhat compile

# Deploy contract and link SSTORE2 SVG chunks on Sepolia
deploy:
	npx hardhat run deployment/deploy.ts --network sepolia

# Mint IPFS and 100% On-Chain NFTs on Sepolia
mint:
	npx hardhat run mint/mint.ts --network sepolia

# Verify smart contract source code on Etherscan
verify:
	npx hardhat verify --network sepolia $(CONTRACT_ADDRESS)

# Serve the Web3 DApp and collection explorer locally
web:
	@echo "Starting TokenizeArt DApp on http://localhost:$\(PORT\)"
	python3 -m http.server $(PORT) --directory website

# Display deployed contract links and on-chain proofs for evaluation
info:
	@echo "\=\=\= TokenizeArt42 (Sepolia Testnet) ==="
	@echo "Contract   : $(CONTRACT_ADDRESS)"
	@echo "Etherscan  : https://sepolia.etherscan.io/address/$\(CONTRACT_ADDRESS\)\#code"
	@echo "Sourcify   : https://sourcify.dev/server/repo-ui/11155111/$\(CONTRACT_ADDRESS\)"
	@echo "SSTORE2 #1 : 0xdC24EB1D4b2A0dEc73973FE71118b90156a233b6"
	@echo "SSTORE2 #2 : 0x5752f776B35507529C893911b2c2546F66153FEF"
	@echo "IPFS URI   : ipfs://bafkreidhzty33rqegajaqo75ilyvtoz4ri5ezzb66yn7mga5p2hwkxhveu"

# Remove Hardhat build artifacts and cache
clean:
	rm -rf artifacts cache

# Full cleanup including node_modules
fclean: clean
	rm -rf node_modules

# Rebuild everything from scratch
re: fclean all

# Display available Makefile targets
help:
	@echo "Available targets:"
	@echo "  make all      - Install dependencies and compile contracts"
	@echo "  make compile  - Compile Solidity contracts"
	@echo "  make deploy   - Deploy contract and SSTORE2 SVG chunks to Sepolia"
	@echo "  make mint     - Mint IPFS and On-Chain NFTs on Sepolia"
	@echo "  make verify   - Verify contract source code on Etherscan"
	@echo "  make web      - Launch local DApp server (default PORT=8081)"
	@echo "  make info     - Print contract addresses and Etherscan proofs"
	@echo "  make clean    - Remove Hardhat cache and artifacts"
	@echo "  make fclean   - Remove cache, artifacts, and node_modules"
	@echo "  make re       - Full clean and rebuild"
