-include .env

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install

# Remap dependencies
remappings :; forge remappings > remappings.txt
