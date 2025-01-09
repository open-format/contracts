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
	deploy-ERC20Point \
	deploy-ERC721Base \
	deploy-ERC721LazyMint \
	deploy-ERC721Badge \
	deploy-RewardsFacet \
	deploy-SettingsFacet \
	deploy-ERC721FactoryFacet \
	deploy-ERC20FactoryFacet \
	deploy-ERC721LazyDropFacet \
	deploy-ChargeFacet \
	facet-versions \

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
deploy-ERC20Point:; forge script scripts/tokens/ERC20Point.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)

# facets
deploy-ChargeFacet:; forge script scripts/facet/ChargeFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-RewardsFacet:; forge script scripts/facet/RewardsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)
deploy-ERC721LazyDropFacet:; forge script scripts/facet/ERC721LazyDropFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(gasPrice) $(legacy) $(slow)

# patch
patch-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Patch --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# versions
facet-versions:; forge script scripts/versions/FacetVersions.s.sol:FacetVersions --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# Operations
# All things relating to Open Formats app and $OFT
ops-setup:; make \
	confirm-operations-wallet \
	ops-CreateOpenFormatApp \
	ops-DeployXP \
	ops-DeployOFT

ops-CreateOpenFormatApp:; forge script scripts/operations/OpenFormatApp.s.sol:CreateApp --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
ops-DeployXP:; forge script scripts/operations/OpenFormatApp.s.sol:DeployXP --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
ops-DeployOFT:; forge script scripts/operations/OpenFormatApp.s.sol:DeployOFT --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

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

# example: make ERC721Base.mintTo args="0xaf4c80136581212185f37c5e8809120d8fbf6224 sometokenuri"
ERC721Base.mintTo:; forge script \
	scripts/tokens/ERC721Base.s.sol:MintTo \
	--sig "run(address,string)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) \
	$(word 1, $(args)) $(word 2, $(args))

# example: make ChargeFacet.chargeUser args="0xaf4c80136581212185f37c5e8809120d8fbf6224 0xe182c3aaFF5AC9968Fb14bBa6f833A9530EeF904 1"
ChargeFacet.chargeUser:; forge script \
	scripts/facet/ChargeFacet.s.sol:ChargeUser \
	--sig "run(address,address,uint256)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) \
	$(word 1, $(args)) $(word 2, $(args)) `cast --to-wei $(word 3, $(args))`

# example: make ChargeFacet.setMinimumCreditBalance args="0xe182c3aaFF5AC9968Fb14bBa6f833A9530EeF904 1"
ChargeFacet.setMinimumCreditBalance:; forge script \
	scripts/facet/ChargeFacet.s.sol:SetMinimumCreditBalance \
	--sig "run(address,uint256)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) \
	$(word 1, $(args)) `cast --to-wei $(word 2, $(args))`

# example: make ChargeFacet.hasFunds args="0xaf4c80136581212185f37c5e8809120d8fbf6224 0xe182c3aaFF5AC9968Fb14bBa6f833A9530EeF904"
ChargeFacet.hasFunds:; forge script \
	scripts/facet/ChargeFacet.s.sol:HasFunds \
	--sig "run(address,address)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) \
	$(word 1, $(args)) $(word 2, $(args))

# pass the badge contract address as an argument
# example: make RewardFacet.mintBadge args="0xaf4c80136581212185f37c5e8809120d8fbf6224"
RewardsFacet.mintBadge:; forge script \
	scripts/facet/RewardsFacet.s.sol:mintBadge \
	--sig "run(address)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) $(args)

# pass the badge contract address as an argument
# example: make RewardFacet.batchMintBadge args="0xaf4c80136581212185f37c5e8809120d8fbf6224"
RewardsFacet.batchMintBadge:; forge script \
	scripts/facet/RewardsFacet.s.sol:batchMintBadge \
	--sig "run(address)" \
 	--rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow) $(args)

# Simulate create new app and issues rewards
# example: make SimulateAppAndRewards rpc="anvil" args="appName"
SimulateAppAndRewards:; forge script \
	scripts/utils/Simulate.s.sol:SimulateAppAndRewards \
	--sig "run(string)" \
	--rpc-url $(rpc) \
	--broadcast \
	$(legacy) \
	$(slow) \
	$(verbose) \
	`cast --format-bytes32-string $(args)`

# Run all update scripts
update:; make \
	update-ERC721FactoryFacet \
	update-ERC20FactoryFacet \
	update-SettingsFacet-ExposeGlobals

# update
update-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
update-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

update-RewardsFacet:; forge script scripts/facet/RewardsFacet.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
update-ERC20Base:; forge script scripts/tokens/ERC20Base.s.sol:Update --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# Add badge minting functionality
# Date 20.05.24
# updates ERC721RewardFacet to update mintERC721 function and add mintBadge and batchMintBadge functions
# deploys and registers RewardsFacet contract
# PR #126 https://github.com/open-format/contracts/pull/126
update-RewardsFacet-add-badgeMintingFunctionality:; forge script scripts/facet/RewardsFacet.s.sol:Update_Add_badgeMintingFunctionality --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

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

# Rename functions in charge facet on staging contracts
# Date 31.07.24 (Executed on arbitrum-sepolia-staging contracts)
# updates ChargeFacet to rename functions and use token naming convention instead of credits
update-ChargeFacet_useTokensNamingConvention:; forge script scripts/facet/ChargeFacet.s.sol:Update_useTokensNamingConvention --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# Expose globals
# deploys a new settings facet, replaces exisitng function selectors and adds new ones
# Date: 30.03.23

update-SettingsFacet-ExposeGlobals:; forge script scripts/facet/SettingsFacet.s.sol:Update_ExposeGlobals --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# utils - bash scripts
confirm-operations-wallet:; export WALLET_ADDRESS=$$(cast wallet address ${PRIVATE_KEY}) && \
	bash bin/confirm-operations-wallet.sh