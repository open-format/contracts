-include .env

rpc ?= anvil
verbose ?= -vvvv
args ?= ""

# Clean the repo
clean  :; forge clean

# Clean dependencies
install :; forge install & yarn install

# Remap dependencies
remappings :; forge remappings > remappings.txt

# deploy
# to run: `make deploy rpc="<chain>"` e.g `make deploy rpc="anvil"`
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

# core
deploy-Globals:; forge script scripts/core/Globals.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-Registry:; forge script scripts/core/Registry.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-Proxy:; forge script scripts/core/Proxy.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-Factory:; forge script scripts/core/Factory.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)

# token implementations
deploy-ERC721Base:; forge script scripts/tokens/ERC721Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-ERC721LazyMint:; forge script scripts/tokens/ERC721LazyMint.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-ERC20Base:; forge script scripts/tokens/ERC20Base.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)

# facets
deploy-SettingsFacet:; forge script scripts/facet/SettingsFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-ERC721FactoryFacet:; forge script scripts/facet/ERC721FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)
deploy-ERC20FactoryFacet:; forge script scripts/facet/ERC20FactoryFacet.s.sol:Deploy --rpc-url $(rpc) --broadcast $(verbose)