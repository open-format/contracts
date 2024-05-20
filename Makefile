-include .env

rpc ?= anvil
verbose ?= -vvvv
args ?= ""
legacy ?= --legacy
slow ?= --slow
gasPrice ?= ""

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install & yarn install

# Remap dependencies
remappings :; forge remappings > remappings.txt

# deploy
# to run: `make deploy rpc="<chain>"` e.g `make deploy rpc="anvil"`
# to specify a gas price:  make deploy rpc="anvil" gasPrice="--with-gas-price 45000000000 --skip-simulation
# TODO: compile all contracts at start then run scripts
deploy:; make \
	deploy-Globals \
	deploy-Registry \
	deploy-Proxy \
	deploy-AppFactory \
	deploy-ERC20Base \
	deploy-ERC721Base \
	deploy-ERC721LazyMint \
	deploy-ERC721Badge \
	deploy-RewardsFacet \
	deploy-SettingsFacet \
	deploy-ERC721FactoryFacet \
	deploy-ERC20FactoryFacet \
	deploy-ERC721LazyDropFacet \
	deploy-Billing \

# core
deploy-Globals:; forge script scripts/core/Globals.s.sol:Deploy --rpc-url $(rpc) --broadcast $(gasPrice) $(verbose) $(legacy) $(slow)
deploy-Registry:; forge script scripts/core/Registry.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-Proxy:; forge script scripts/core/Proxy.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-AppFactory:; forge script scripts/core/AppFactory.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)

# token implementations
deploy-ERC721Base:; forge script scripts/tokens/ERC721Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721LazyMint:; forge script scripts/tokens/ERC721LazyMint.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721Badge:; forge script scripts/tokens/ERC721Badge.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC20Base:; forge script scripts/tokens/ERC20Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)

# facets
deploy-RewardsFacet:; forge script scripts/facet/RewardsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721LazyDropFacet:; forge script scripts/facet/ERC721LazyDropFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-Billing:; forge script scripts/billing/Billing.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)

# patch
patch-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Patch --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# helpers

# example: `make CreateApp args="app name" rpc=anvil`
# Note: Uses a cast command to format the app name args to bytes32
CreateApp:; forge script \
	scripts/core/AppFactory.s.sol:CreateApp \
	--sig "run(string)" \
	--rpc-url $(rpc) \
	--broadcast \
	$(legacy) \
	$(slow) \
	$(verbose) \
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


hasCreatorAccess:; forge script scripts/facet/SettingsFacet.s.sol:hasCreatorAccess --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# example `make createERC721Base`
# Note: make sure app is setup with correct permissions and APP_ID env is set.
createERC721Base:; forge script scripts/facet/ERC721FactoryFacet.s.sol:CreateBase --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# example `make createERC721Badge`
# Note: make sure app is setup with correct permissions and APP_ID env is set.
createERC721Badge:; forge script scripts/facet/ERC721FactoryFacet.s.sol:CreateBadge --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# example: make ERC721Badge.mintTo args="0xaf4c80136581212185f37c5e8809120d8fbf6224"
ERC721Badge.mintTo:; forge script \
	scripts/tokens/ERC721Badge.s.sol:MintTo \
	--sig "run(address)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) $(args)

# example: make ERC721Badge.setBaseURI args="0xaf4c80136581212185f37c5e8809120d8fbf6224 someotherurl"
ERC721Badge.setBaseURI:; forge script \
	scripts/tokens/ERC721Badge.s.sol:SetBaseURI \
	--sig "run(address,string)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) \
	$(word 1, $(args)) $(word 2, $(args))

# Run all update scripts
update:; make \
	update-ERC721FactoryFacet \
	update-ERC20FactoryFacet \
	update-SettingsFacet-ExposeGlobals

# update
update-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
update-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# Add ERC721Badge contract
# Date 14.05.24
# updates ERC721FactoryFacet to change the createERC721 function to include a baseTokenURI paramerter
# deploys and registers ERC721Badge contract
# PR #122 https://github.com/open-format/contracts/pull/122
update-ERC721Badge:; make \
	update-ERC721FactoryFacet-add-createERC721WithTokenURI \
	deploy-ERC721Badge

update-ERC721FactoryFacet-add-createERC721WithTokenURI:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Update_Add_createERC721WithTokenURI --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)


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

update-SettingsFacet-ExposeGlobals:; forge script scripts/facet/SettingsFacet.s.sol:Update_ExposeGlobals --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)