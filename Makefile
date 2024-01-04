-include .env

rpc ?= 'https://testnet.hashio.io/api'
#rpc ?= 'http://127.0.0.1:7546'
verbose ?= -vvvv
args ?= ""
legacy ?= --legacy
slow ?= --slow

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install & yarn install

# Remap dependencies
remappings :; forge remappings > remappings.txt

# deploy
# to run: `make deploy rpc="<chain>"` e.g `make deploy rpc="anvil"`
#	deploy-ERC721LazyMint \
# TODO: compile all contracts at start then run scripts
deploy:; make \
	deploy-Globals \
	deploy-Registry \
	deploy-Proxy \
	deploy-StarFactory \
	deploy-ERC20Base \
	deploy-ConstellationFactory \
	deploy-ERC721Base \
	deploy-RewardsFacet \
	deploy-SettingsFacet \
	deploy-ERC721FactoryFacet \
	deploy-ERC20FactoryFacet \
	deploy-ERC721LazyDropFacet \

# core
deploy-Globals:; forge script scripts/core/Globals.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-Registry:; forge script scripts/core/Registry.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-Proxy:; forge script scripts/core/Proxy.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-StarFactory:; forge script scripts/core/StarFactory.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ConstellationFactory:; forge script scripts/core/ConstellationFactory.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 


# token implementations
deploy-ERC721Base:; forge script scripts/tokens/ERC721Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ERC721LazyMint:; forge script scripts/tokens/ERC721LazyMint.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ERC20Base:; forge script scripts/tokens/ERC20Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
# facets
deploy-RewardsFacet:; forge script scripts/facet/RewardsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
deploy-ERC721LazyDropFacet:; forge script scripts/facet/ERC721LazyDropFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 

# patch
patch-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Patch --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)  --gas-price 1330000000000 --with-gas-price 1330000000000 

# helpers

# example: `make CreateApp args="app name" rpc=anvil`
# Note: Uses a cast command to format the app name args to bytes32
CreateApp:; forge script \
	scripts/core/StarFactory.s.sol:CreateApp \
	--sig "run(string)" \
	--rpc-url $(rpc) \
	--broadcast \
	$(legacy) \
	$(slow) \
	$(verbose) \
	--gas-price 1330000000000 \
	--with-gas-price 1330000000000 \
	--skip-simulation \
	--gas-limit 9999999999999 \
	`cast --format-bytes32-string $(args)`

# example: `make CreateConstellation args="constellation name" rpc=anvil`
# Note: Uses a cast command to format the app name args to bytes32
CreateConstellation:; forge script \
	scripts/core/ConstellationFactory.s.sol:CreateConstellation \
	--sig "run(string)" \
	--rpc-url $(rpc) \
	--broadcast \
	$(legacy) \
	$(slow) \
	$(verbose) \
	--gas-price 1330000000000 \
	--with-gas-price 1330000000000 \
	--skip-simulation \
	--gas-limit 9999999999999 \
	`cast --format-bytes32-string $(args)`

# example: `make SetPlatformFee args="0.01 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266" rpc=anvil`
# Note: Uses a cast command to convert the given price in Ether to Wei
SetPlatformFee:; forge script \
	scripts/core/Globals.s.sol:SetPlatformFee \
	--sig "run(uint256,address)" \
	--rpc-url $(rpc) \
	--broadcast \
  $(legacy) \
  $(slow) \
	$(verbose) \
	`cast --to-wei $(word 1, $(args))` $(word 2, $(args))


# Run all update scripts
update:; make \
	update-ERC721FactoryFacet \
	update-ERC20FactoryFacet \
	update-SettingsFacet-ExposeGlobals

# update
update-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
update-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 

# Add platform fee to tokens
# Date: 29.03.23
# redeploys erc20FactoryFacet, erc721FactoyFacet and replaces all functions on registry
# deploys new ERC721Base ERC721LazyMint ERC20 and replaces exisitng implementations on globals
# PR #91 https://github.com/open-format/contracts/pull/91
update-addPlatformFeeToTokens:; make \
	update-ERC721FactoryFacet \
	update-ERC20FactoryFacet \
	deploy-ERC721Base \
	deploy-ERC721LazyMint \
	deploy-ERC20Base \

# Expose globals
# deploys a new settings facet, replaces exisitng function selectors and adds new ones
# Date: 30.03.23

update-SettingsFacet-ExposeGlobals:; forge script scripts/facet/SettingsFacet.s.sol:Update_ExposeGlobals --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) --gas-price 1330000000000 --with-gas-price 1330000000000 
