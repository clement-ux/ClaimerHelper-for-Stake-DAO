// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Test} from "lib/forge-std/src/Test.sol";

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IMetapool} from "src/interfaces/IMetapool.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {ClaimRewardModular} from "src/ClaimRewardModular.sol";

contract ClaimRewardModularTest is Test, ClaimRewardModular {
    address public constant ALICE = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public constant LOCAL_DEPLOYER = address(0xDE);

    ClaimRewardModular public claimer;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 16_150_119);
        vm.selectFork(forkId);

        vm.prank(LOCAL_DEPLOYER);
        claimer = new ClaimRewardModular();
    }

    function testInit() public {
        claimer.init();
    }
}
