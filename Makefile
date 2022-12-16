include .env
.PHONY: test

.EXPORT_ALL_VARIABLES:
ETHERSCAN_API_KEY==${ETHERSCAN_KEY}

default:; @forge fmt && forge build
# Test
test:; @forge fmt && forge test --match-contract ClaimRewardModularTest --match-test test -vvv --etherscan-api-key ${ETHERSCAN_KEY}
# Deployment
test-deploy:; @forge script script/ClaimRewardModular.s.sol -vvvv

# Coverage 
lrep:; @forge coverage --report debug > report.txt
lcov:; @forge coverage --report lcov
coverage:; @forge coverage --match-contract ClaimRewardModularTest
# Gas
gas:; @forge test --gas-report 