include .env
.PHONY: test

.EXPORT_ALL_VARIABLES:
ETHERSCAN_API_KEY==${ETHERSCAN_KEY}

default:; @forge fmt && forge build
test:; @forge fmt && forge test --match-contract ClaimRewardModularTest -vvvv --etherscan-api-key ${ETHERSCAN_KEY}