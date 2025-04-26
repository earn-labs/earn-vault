
-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install Cyfrin/foundry-devops --no-commit && forge install Openzeppelin/openzeppelin-contracts --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# test coverage
coverage:; @forge coverage --contracts src
coverage-report:; @forge coverage --contracts src --report debug > coverage.txt

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_MAIN} --fork-block-number <blocknumber> --fork-chain-id <fork id> --chain-id <custom id>

# security
slither :; slither ./src 

# deployment
deploy-local: 
	@forge script script/DeployEarnVault.s.sol:DeployEarnVault --rpc-url $(RPC_LOCALHOST) --private-key ${DEFAULT_ANVIL_KEY} --sender ${DEFAULT_ANVIL_ADDRESS} --broadcast 

deploy-testnet: 
	@forge script script/DeployEarnVault.s.sol:DeployEarnVault --rpc-url $(RPC_TEST) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --etherscan-api-key ${ETHERSCAN_KEY} -vvvv

verify:
	@set -e; \
	ARGS=$$(cast abi-encode "constructor(address,address)" 0xEcA5652Ebc9A3b7E9E14294197A86b02cD8C3A67 0xc8bdD7805fAd8dc59b753FEcCCDf17b98c17465b); \
	echo "ARGS: $$ARGS"; \
	forge verify-contract 0xEAB1C8352Eb83ABe78297ad629019254e14CB0aD src/EarnVault.sol:EarnVault \
	--rpc-url $(RPC_TEST) \
	--etherscan-api-key ${ETHERSCAN_KEY} \
	--num-of-optimizations 200 \
	--compiler-version v0.8.26+commit.8a97fa7a \
	--constructor-args $$ARGS \
	-vvvv

# cast abi-encode "constructor(address,address)" 

# command line interaction
contract-call:
	@cast call <contract address> "FunctionSignature(params)(returns)" arguments --rpc-url ${<RPC>}

-include ${FCT_PLUGIN_PATH}/makefile-external