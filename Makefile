-include .env

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install

# Remap dependencies
remappings :; forge remappings > remappings.txt

# Verify smart contract
# e.g address=0x86935f11c86623dec8a25696e1c19a8659cbf95d
# e.g contract=./src/Diamond.sol:Diamond
verify-contract-mumbai :; forge verify-contract --verifier-url https://api-testnet.polygonscan.com/api/ ${address} ${contract} ${POLYGONSCAN_MUMBAI_API_KEY}