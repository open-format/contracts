-include .env

rpc ?= anvil
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
# TODO: compile all contracts at start then run scripts
deploy:; make \
	deploy-Globals \
	deploy-Registry \
	deploy-Proxy \
	deploy-Factory \
	deploy-ERC721Base \
	deploy-ERC721LazyMint \
	deploy-ERC20Base \
	deploy-SettingsFacet \
	deploy-ERC721FactoryFacet \
	deploy-ERC20FactoryFacet \
	deploy-ERC721LazyDropFacet \

# core
deploy-Globals:; forge script scripts/core/Globals.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-Registry:; forge script scripts/core/Registry.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-Proxy:; forge script scripts/core/Proxy.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-Factory:; forge script scripts/core/Factory.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)

# token implementations
deploy-ERC721Base:; forge script scripts/tokens/ERC721Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-ERC721LazyMint:; forge script scripts/tokens/ERC721LazyMint.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-ERC20Base:; forge script scripts/tokens/ERC20Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
# facets
deploy-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)
deploy-ERC721LazyDropFacet:; forge script scripts/facet/ERC721LazyDropFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose) $(legacy) $(slow)


# helpers

# example: `make CreateApp args="app name" rpc=anvil`
# Note: Uses a cast command to format the app name args to bytes32
CreateApp:; forge script \
	scripts/core/Factory.s.sol:CreateApp \
	--sig "run(string)" \
	--rpc-url $(rpc) \
	--broadcast \
	$(legacy) \
	$(slow) \
	$(verbose) \
	`cast --format-bytes32-string $(args)` 