-include .env

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install

# Remap dependencies
remappings :; forge remappings > remappings.txt

# deploy and setup contract on anvil
deploy-anvil :; forge script scripts/DeployToAnvil.s.sol:DeployRegistry --rpc-url anvil --broadcast -vvvv
deploy-mumbai :; forge script scripts/DeployToAnvil.s.sol:DeployRegistry --rpc-url mumbai --broadcast -vvvv