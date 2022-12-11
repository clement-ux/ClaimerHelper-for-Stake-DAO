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
import {ClaimReward} from "src/ClaimReward.sol";
import {Constants} from "test/fixtures/Constants.sol";
import {MerkleProofFile} from "test/fixtures/MerkleProofFile.sol";

contract GasComparisonTest is Test, Constants, MerkleProofFile {
    address public constant OLD_CLAIMER = 0x633120100e108F03aCe79d6C78Aac9a56db1be0F;
    address public constant ALICE = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public constant LOCAL_DEPLOYER = address(0xDE);

    address[] public gauges;

    ClaimReward public oldClaimer;
    ClaimRewardModular public claimer;
    IERC20 public sdfrax3crv = IERC20(SD_FRAX_3CRV);
    IERC20 public frax3crv = IERC20(FRAX_3CRV);

    function setUp() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 16_150_119);
        vm.selectFork(forkId);
        generateMerkleProof();

        vm.startPrank(LOCAL_DEPLOYER);
        claimer = new ClaimRewardModular();
        oldClaimer = new ClaimReward();
        claimer.addDepositor(FXS, FXS_DEPOSITOR);
        claimer.addDepositor(ANGLE, ANGLE_DEPOSITOR);
        claimer.addDepositor(CRV, CRV_DEPOSITOR);
        claimer.addPool(FXS, POOL_FXS_SDFXS);
        claimer.addPool(ANGLE, POOL_ANGLE_SDANGLE);
        claimer.addPool(CRV, POOL_CRV_SDCRV);
        oldClaimer.addDepositor(FXS, FXS_DEPOSITOR);
        oldClaimer.addDepositor(ANGLE, ANGLE_DEPOSITOR);
        oldClaimer.addDepositor(CRV, CRV_DEPOSITOR);
        oldClaimer.enableGauge(GAUGE_GUNI_AGEUR_ETH);
        oldClaimer.enableGauge(GAUGE_SDCRV);
        oldClaimer.enableGauge(GAUGE_SDANGLE);
        vm.stopPrank();

        gauges.push(GAUGE_GUNI_AGEUR_ETH);
        gauges.push(GAUGE_SDCRV);
        gauges.push(GAUGE_SDANGLE);
        //lockeds.push(true)
    }

    function testOldClaimer() public {
        vm.startPrank(STAKE_DAO_MULTISIG);
        ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).set_claimer(address(oldClaimer));
        vm.stopPrank();

        vm.startPrank(STDDEPLOYER);
        ILiquidityGauge(GAUGE_SDCRV).set_claimer(address(oldClaimer));
        ILiquidityGauge(GAUGE_SDANGLE).set_claimer(address(oldClaimer));
        vm.stopPrank();

        vm.prank(ALICE);
        oldClaimer.claimRewards(gauges);
    }

    function testNewClaimer() public {
        vm.startPrank(STAKE_DAO_MULTISIG);
        ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).set_claimer(address(claimer));
        vm.stopPrank();

        vm.startPrank(STDDEPLOYER);
        ILiquidityGauge(GAUGE_SDCRV).set_claimer(address(claimer));
        ILiquidityGauge(GAUGE_SDANGLE).set_claimer(address(claimer));
        vm.stopPrank();

        vm.prank(ALICE);
        claimer.claimRewards(gauges);
    }
}
