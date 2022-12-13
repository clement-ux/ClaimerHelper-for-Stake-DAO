include .env
.PHONY: test

.EXPORT_ALL_VARIABLES:
ETHERSCAN_API_KEY==${ETHERSCAN_KEY}

default:; @forge fmt && forge build
test:; @forge fmt && forge test --match-contract ClaimRewardModularTest --match-test testClaimVeSDTRewardSwap2Lock -vvvv --etherscan-api-key ${ETHERSCAN_KEY}
test-gas-comparison:; @forge fmt && forge test --match-contract GasComparisonTest -vvv #v --etherscan-api-key ${ETHERSCAN_KEY}

gas-comparison:; @forge test --match-contract GasComparisonTest --gas-report