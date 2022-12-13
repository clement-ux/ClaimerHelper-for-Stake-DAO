// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Test} from "lib/forge-std/src/Test.sol";

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IStableSwap} from "src/interfaces/IStableSwap.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {ClaimRewardModular} from "src/ClaimRewardModular.sol";
import {Constants} from "test/fixtures/Constants.sol";
import {MerkleProofFile} from "test/fixtures/MerkleProofFile.sol";

contract ClaimRewardModularTest is Test, Constants, MerkleProofFile {
    address public constant ALICE = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public constant LOCAL_DEPLOYER = address(0xDE);

    address[] public gauges;

    ClaimRewardModular public claimer;
    IERC20 public sdfrax3crv = IERC20(SD_FRAX_3CRV);
    IERC20 public frax3crv = IERC20(FRAX_3CRV);
    IERC20 public frax = IERC20(FRAX);
    IERC20 public gno = IERC20(GNO);
    IERC20 public crv3 = IERC20(CRV3);
    IERC20 public sdt = IERC20(SDT);
    IVeSDT public vesdt = IVeSDT(VE_SDT);

    bool[] executeActions;
    IMultiMerkleStash.claimParam[] claimParams;
    bool swapVeSDTRewards;
    uint256 choice;
    bool[] lockeds;
    bool[] stakeds;
    bool[] buys;
    bool lockSDT;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 16_150_119);
        vm.selectFork(forkId);
        generateMerkleProof();

        vm.startPrank(LOCAL_DEPLOYER);
        claimer = new ClaimRewardModular();
        claimer.addDepositor(FXS, FXS_DEPOSITOR);
        claimer.addDepositor(ANGLE, ANGLE_DEPOSITOR);
        claimer.addDepositor(CRV, CRV_DEPOSITOR);
        claimer.addPool(FXS, POOL_FXS_SDFXS);
        claimer.addPool(ANGLE, POOL_ANGLE_SDANGLE);
        claimer.addPool(CRV, POOL_CRV_SDCRV);
        claimer.init();
        vm.stopPrank();

        vm.startPrank(STAKE_DAO_MULTISIG);
        ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).set_claimer(address(claimer));
        vm.stopPrank();

        vm.startPrank(STDDEPLOYER);
        ILiquidityGauge(GAUGE_SDCRV).set_claimer(address(claimer));
        ILiquidityGauge(GAUGE_SDANGLE).set_claimer(address(claimer));
        vm.stopPrank();

        vm.startPrank(ALICE);
        sdfrax3crv.approve(address(claimer), type(uint256).max);
        sdt.approve(address(claimer), type(uint256).max);
        vm.stopPrank();

        gauges.push(GAUGE_GUNI_AGEUR_ETH);
        gauges.push(GAUGE_SDCRV);
        gauges.push(GAUGE_SDANGLE);

        baseClaim();
    }

    function baseClaim() public {
        // List of actions to execute
        //bool[] memory executeActions = new bool[](3);
        executeActions.push(false); // Claim rewards from bribes
        executeActions.push(false); // Claim rewards from veSDT
        executeActions.push(false); // Claim rewards from lockers/strategies

        // Params for claiming bribes
        // Bribes in 3CRV
        claimParams.push(IMultiMerkleStash.claimParam(CRV3, claimer3CRV1Index, amountToClaim3CRV1, merkleProof3CRV1));
        // Bribes in GNO
        claimParams.push(IMultiMerkleStash.claimParam(GNO, claimerGNOIndex, amountToClaimGNO, merkleProofGNO));
        // Bribes in SDT
        claimParams.push(IMultiMerkleStash.claimParam(SDT, claimerSDTIndex, amountToClaimSDT, merkleProofSDT));

        // Params for rewards from veSDT
        swapVeSDTRewards = false;
        choice = 0;

        // List of actions to do
        lockeds.push(false); // fxs
        lockeds.push(false); // angle
        lockeds.push(false); // crv
        stakeds.push(false); // fxs
        stakeds.push(false); // angle
        stakeds.push(false); // crv
        buys.push(false); // fxs
        buys.push(false); // angle
        buys.push(false); // crv

        // Lock SDT
        lockSDT = false;
    }

    function testClaimBribesOnlyNotLockSDT() public {
        executeActions[0] = true;

        uint256 balanceBeforeGNO = gno.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBefore3CRV = crv3.balanceOf(ALICE);
        uint256 balanceBeforeVeSDT = vesdt.balanceOf(ALICE);
        claim();
        uint256 balanceAfterGNO = gno.balanceOf(ALICE);
        uint256 balanceAfterSDT = sdt.balanceOf(ALICE);
        uint256 balanceAfter3CRV = crv3.balanceOf(ALICE);
        uint256 balanceAfterVeSDT = vesdt.balanceOf(ALICE);

        assertGt(balanceAfterGNO, balanceBeforeGNO);
        assertEq(balanceAfterSDT, balanceBeforeSDT + amountToClaimSDT);
        assertGt(balanceAfter3CRV, balanceBefore3CRV);
        assertEq(balanceAfterVeSDT, balanceBeforeVeSDT);
    }

    function testClaimBribesOnlyAndLockSDT() public {
        executeActions[0] = true;
        lockSDT = true;

        uint256 balanceBeforeGNO = gno.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBefore3CRV = crv3.balanceOf(ALICE);
        uint256 balanceBeforeVeSDT = vesdt.balanceOf(ALICE);
        IVeSDT.LockedBalance memory lockedBefore = vesdt.locked(ALICE);
        claim();
        uint256 balanceAfterGNO = gno.balanceOf(ALICE);
        uint256 balanceAfterSDT = sdt.balanceOf(ALICE);
        uint256 balanceAfter3CRV = crv3.balanceOf(ALICE);
        uint256 balanceAfterVeSDT = vesdt.balanceOf(ALICE);
        IVeSDT.LockedBalance memory lockedAfter = vesdt.locked(ALICE);

        assertGt(balanceAfterGNO, balanceBeforeGNO, "1");
        assertEq(balanceAfterSDT, balanceBeforeSDT, "2");
        assertGt(balanceAfter3CRV, balanceBefore3CRV, "3");
        assertGt(balanceAfterVeSDT, balanceBeforeVeSDT, "4");
        assertEq(lockedAfter.amount, lockedBefore.amount + int256(amountToClaimSDT), "5");
    }

    function testClaimVeSDTRewardNoSwap() public {
        executeActions[1] = true;

        uint256 balanceBefore = sdfrax3crv.balanceOf(ALICE);
        claim();
        uint256 balanceAfter = sdfrax3crv.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap0() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;

        uint256 balanceBefore = frax3crv.balanceOf(ALICE);
        claim();
        uint256 balanceAfter = frax3crv.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap1() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 1;

        uint256 balanceBefore = frax.balanceOf(ALICE);
        claim();
        uint256 balanceAfter = frax.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap2NoLock() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 2;

        uint256 balanceBefore = sdt.balanceOf(ALICE);
        claim();
        uint256 balanceAfter = sdt.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap2Lock() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 2;
        lockSDT = true;

        IVeSDT.LockedBalance memory lockedBefore = vesdt.locked(ALICE);
        claim();
        IVeSDT.LockedBalance memory lockedAfter = vesdt.locked(ALICE);

        assertGt(lockedAfter.amount, lockedBefore.amount);
    }

    ////////////////////////////////////////////////////////////////
    /// --- HELPERS
    ///////////////////////////////////////////////////////////////
    function claim() public {
        // Create the Actions structure
        ClaimRewardModular.Actions memory actions =
            ClaimRewardModular.Actions(claimParams, swapVeSDTRewards, choice, lockeds, stakeds, buys, lockSDT);
        vm.prank(ALICE);
        claimer.claimAndExtraActions(executeActions, gauges, actions);
    }
}
