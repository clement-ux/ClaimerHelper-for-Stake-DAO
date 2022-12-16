include .env
.PHONY: test

.EXPORT_ALL_VARIABLES:
ETHERSCAN_API_KEY==${ETHERSCAN_KEY}

default:; @forge fmt && forge build
test:; @forge fmt && forge test --match-contract ClaimRewardModularTest --match-test test -vvv --etherscan-api-key ${ETHERSCAN_KEY}

lrep:; @forge coverage --report debug > report.txt
lcov:; @forge coverage --report lcov
coverage:; @forge coverage --match-contract ClaimRewardModularTest

gas:; @forge test --gas-report 