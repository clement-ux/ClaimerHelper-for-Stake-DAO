// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";

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
import {MerkleProofFile} from "test/fixtures/MerkleProofFile.t.sol";

contract ClaimRewardModularTest is Test, Constants, MerkleProofFile {
    address public constant ALICE = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public constant BOB = 0xb0e83C2D71A991017e0116d58c5765Abc57384af;
    address public constant LOCAL_DEPLOYER = address(0xDE);
    address public constant FAKE = address(0xFA4E);

    address[] public gaugesList1;
    address[] public gaugesList2;

    uint256 public constant BASE_UNIT = 1e18;
    uint256 public constant SLIPPAGE = 1e16;
    uint256[] public claimable;

    ClaimRewardModular public claimer;
    IERC20 public sdfrax3crv = IERC20(SD_FRAX_3CRV);
    IERC20 public frax3crv = IERC20(FRAX_3CRV);
    IERC20 public frax = IERC20(FRAX);
    IERC20 public gno = IERC20(GNO);
    IERC20 public crv3 = IERC20(CRV3);
    IERC20 public crv = IERC20(CRV);
    IERC20 public angle = IERC20(ANGLE);
    IERC20 public sdt = IERC20(SDT);
    IERC20 public ageur = IERC20(AG_EUR);
    IERC20 public sdcrv = IERC20(SD_CRV);
    IERC20 public sdbal = IERC20(SD_BAL);
    IERC20 public sdfxs = IERC20(SD_FXS);
    IERC20 public sdangle = IERC20(SD_ANGLE);
    IERC20 public bal = IERC20(BAL);
    IVeSDT public vesdt = IVeSDT(VE_SDT);

    // Parameters for claimAndExtraActions functions
    bool[] executeActions;
    IMultiMerkleStash.claimParam[] claimParams;
    IMultiMerkleStash.claimParam[] claimParamsCustom;
    bool stakeBribes;
    bool swapVeSDTRewards;
    uint256 choice;
    uint256 minAmountSDT;
    bool[] lockeds;
    bool[] stakeds;
    bool[] buys;
    uint256[] minAmounts;
    bool lockSDT;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 16_150_119);
        vm.selectFork(forkId);
        generateMerkleProof();

        vm.startPrank(LOCAL_DEPLOYER);
        claimer = new ClaimRewardModular();
        vm.stopPrank();

        vm.startPrank(STAKE_DAO_MULTISIG);
        ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).set_claimer(address(claimer));
        vm.stopPrank();

        vm.prank(ILiquidityGauge(GAUGE_SDCRV).admin());
        ILiquidityGauge(GAUGE_SDCRV).set_claimer(address(claimer));
        vm.prank(ILiquidityGauge(GAUGE_SDANGLE).admin());
        ILiquidityGauge(GAUGE_SDANGLE).set_claimer(address(claimer));
        vm.prank(ILiquidityGauge(GAUGE_SDBAL).admin());
        ILiquidityGauge(GAUGE_SDBAL).set_claimer(address(claimer));
        vm.prank(ILiquidityGauge(GAUGE_SDAPW).admin());
        ILiquidityGauge(GAUGE_SDAPW).set_claimer(address(claimer));
        vm.prank(ILiquidityGauge(GAUGE_SDBPT).admin());
        ILiquidityGauge(GAUGE_SDBPT).set_claimer(address(claimer));
        vm.prank(ILiquidityGauge(GAUGE_SDFXS).admin());
        ILiquidityGauge(GAUGE_SDFXS).set_claimer(address(claimer));
        // Add fake reward into gauge sdCRV
        vm.prank(ILiquidityGauge(GAUGE_SDCRV).admin());
        ILiquidityGauge(GAUGE_SDCRV).add_reward(FXS, FAKE);

        vm.startPrank(ALICE);
        sdfrax3crv.approve(address(claimer), type(uint256).max);
        sdt.approve(address(claimer), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(BOB);
        sdcrv.approve(address(claimer), type(uint256).max);
        sdbal.approve(address(claimer), type(uint256).max);
        sdfxs.approve(address(claimer), type(uint256).max);
        sdangle.approve(address(claimer), type(uint256).max);
        vm.stopPrank();

        deal(SD_CRV, claimer.multiMerkleStash(), 1_000_000e18);
        deal(SD_BAL, claimer.multiMerkleStash(), 1_000_000e18);
        deal(SD_ANGLE, claimer.multiMerkleStash(), 1_000_000e18);
        deal(SD_FXS, claimer.multiMerkleStash(), 1_000_000e18);

        gaugesList1.push(GAUGE_GUNI_AGEUR_ETH);
        gaugesList1.push(GAUGE_SDCRV);
        gaugesList1.push(GAUGE_SDANGLE);
        gaugesList2.push(GAUGE_SDCRV);
        gaugesList2.push(GAUGE_SDANGLE);
        gaugesList2.push(GAUGE_SDFXS);
        gaugesList2.push(GAUGE_SDBAL);
        gaugesList2.push(GAUGE_SDBPT);
        gaugesList2.push(GAUGE_SDAPW);

        baseClaim();
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////
    function testAddDepositor() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addDepositor(address(0), CRV_DEPOSITOR);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addDepositor(CRV, address(0));

        claimer.addDepositor(CRV, CRV_DEPOSITOR);

        assertEq(claimer.depositors(CRV), CRV_DEPOSITOR);
        assertEq(claimer.depositorsIndex(CRV_DEPOSITOR), 0);
        assertEq(claimer.depositorsCount(), 1);
        assertEq(crv.allowance(address(claimer), CRV_DEPOSITOR), type(uint256).max);

        vm.expectRevert(ClaimRewardModular.ALREADY_ADDED.selector);
        claimer.addDepositor(CRV, CRV_DEPOSITOR);
    }

    function testUpdateDepositor() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updateDepositor(address(0), CRV_DEPOSITOR);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updateDepositor(CRV, address(0));
        vm.expectRevert(ClaimRewardModular.NOT_ADDED.selector);
        claimer.updateDepositor(CRV, CRV_DEPOSITOR);

        claimer.addDepositor(CRV, CRV_DEPOSITOR);
        claimer.updateDepositor(CRV, FAKE);

        assertEq(claimer.depositors(CRV), FAKE);
        assertEq(claimer.depositorsIndex(FAKE), 0);
        assertEq(claimer.depositorsCount(), 1);
        assertEq(crv.allowance(address(claimer), CRV_DEPOSITOR), 0);
        assertEq(crv.allowance(address(claimer), FAKE), type(uint256).max);
    }

    function testAddPool() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addPool(address(0), POOL_CRV_SDCRV);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addPool(CRV, address(0));

        claimer.addPool(CRV, POOL_CRV_SDCRV);

        assertEq(claimer.pools(CRV), POOL_CRV_SDCRV);
        assertEq(claimer.poolsIndex(POOL_CRV_SDCRV), 0);
        assertEq(claimer.poolsCount(), 1);
        assertEq(crv.allowance(address(claimer), POOL_CRV_SDCRV), type(uint256).max);

        vm.expectRevert(ClaimRewardModular.ALREADY_ADDED.selector);
        claimer.addPool(CRV, POOL_CRV_SDCRV);
    }

    function testUpdatePool() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updatePool(address(0), POOL_CRV_SDCRV);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updatePool(CRV, address(0));
        vm.expectRevert(ClaimRewardModular.NOT_ADDED.selector);
        claimer.updatePool(CRV, POOL_CRV_SDCRV);

        claimer.addPool(CRV, POOL_CRV_SDCRV);
        claimer.updatePool(CRV, FAKE);

        assertEq(claimer.pools(CRV), FAKE);
        assertEq(claimer.poolsIndex(FAKE), 0);
        assertEq(claimer.poolsCount(), 1);
        assertEq(crv.allowance(address(claimer), POOL_CRV_SDCRV), 0);
        assertEq(crv.allowance(address(claimer), FAKE), type(uint256).max);
    }

    function testAddSdGauge() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addSdGauge(address(0), GAUGE_SDCRV);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.addSdGauge(SD_CRV, address(0));

        claimer.addSdGauge(SD_CRV, GAUGE_SDCRV);

        assertEq(claimer.gauges(SD_CRV), GAUGE_SDCRV);
        assertEq(claimer.gaugesIndex(GAUGE_SDCRV), 0);
        assertEq(claimer.gaugesCount(), 1);
        assertEq(sdcrv.allowance(address(claimer), GAUGE_SDCRV), type(uint256).max);

        vm.expectRevert(ClaimRewardModular.ALREADY_ADDED.selector);
        claimer.addSdGauge(SD_CRV, GAUGE_SDCRV);
    }

    function testUpdateSdGauge() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updateSdGauge(address(0), GAUGE_SDCRV);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updateSdGauge(SD_CRV, address(0));
        vm.expectRevert(ClaimRewardModular.NOT_ADDED.selector);
        claimer.updateSdGauge(SD_CRV, GAUGE_SDCRV);

        claimer.addSdGauge(SD_CRV, GAUGE_SDCRV);
        claimer.updateSdGauge(SD_CRV, FAKE);

        assertEq(claimer.gauges(SD_CRV), FAKE);
        assertEq(claimer.gaugesIndex(FAKE), 0);
        assertEq(claimer.gaugesCount(), 1);
        assertEq(sdcrv.allowance(address(claimer), GAUGE_SDCRV), 0);
        assertEq(sdcrv.allowance(address(claimer), FAKE), type(uint256).max);
    }

    function testToggleBlacklistOnPool() public {
        assertEq(claimer.blacklisted(FAKE), false);

        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.toggleBlacklistOnGauge(address(0));
        claimer.toggleBlacklistOnGauge(FAKE);
        assertEq(claimer.blacklisted(FAKE), true);
        claimer.toggleBlacklistOnGauge(FAKE);
        assertEq(claimer.blacklisted(FAKE), false);
    }

    function testSetGov() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.setGovernance(address(0));
        claimer.setGovernance(ALICE);
        assertEq(claimer.governance(), ALICE);
    }

    function testInit() public {
        assertEq(claimer.initialization(), false);
        vm.expectRevert(ClaimRewardModular.AUTH_ONLY_GOVERNANCE.selector);
        claimer.init();
        vm.startPrank(LOCAL_DEPLOYER);
        claimer.init();
        vm.expectRevert(ClaimRewardModular.ALREADY_INITIALIZED.selector);
        claimer.init();
    }

    function testSetSlippage() public {
        vm.prank(LOCAL_DEPLOYER);
        claimer.setSlippage(1e17);
        assertEq(claimer.slippage(), 1e17);
    }

    function testSetMulti() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.setMultiMerkleStash(address(0));
        claimer.setMultiMerkleStash(FAKE);
        assertEq(claimer.multiMerkleStash(), FAKE);
    }

    function testSetDistrib() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.setVeSDTFeeDistributor(address(0));
        claimer.setVeSDTFeeDistributor(FAKE);
        assertEq(claimer.veSDTFeeDistributor(), FAKE);
    }

    function testRescue() public {
        deal(CRV, address(claimer), 100);
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.rescueERC20(CRV, 100, address(0));
        claimer.rescueERC20(CRV, 100, FAKE);

        assertEq(crv.balanceOf(FAKE), 100);
    }

    function testTokenSdToken() public {
        vm.startPrank(LOCAL_DEPLOYER);
        vm.expectRevert(ClaimRewardModular.ADDRESS_NULL.selector);
        claimer.updateTokenSdToken(address(0), FAKE);
        claimer.updateTokenSdToken(FAKE, CRV);
        assertEq(claimer.tokenSdToken(FAKE), CRV);
    }

    ////////////////////////////////////////////////////////////////
    /// --- BRIBES
    ///////////////////////////////////////////////////////////////
    function testClaimBribesOnlyNotLockSDT() public {
        executeActions[0] = true;
        lockSDT = true; // Should have zero effect because only claim bribes and stakeBribes is false

        uint256 balanceBeforeGNO = gno.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBefore3CRV = crv3.balanceOf(ALICE);
        uint256 balanceBeforeVeSDT = vesdt.balanceOf(ALICE);
        claim(ALICE);
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
        stakeBribes = true;
        lockSDT = true;

        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );

        uint256 balanceBeforeGNO = gno.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBefore3CRV = crv3.balanceOf(ALICE);
        uint256 balanceBeforeVeSDT = vesdt.balanceOf(ALICE);
        IVeSDT.LockedBalance memory lockedBefore = vesdt.locked(ALICE);
        vm.prank(ALICE);
        claimer.claimAndExtraActions(executeActions, gaugesList1, actions);
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

    function testClaimBribesSdTKNSimple() public {
        updateRoot();

        executeActions[0] = true; // claim bribes

        // Create the Actions structure
        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParamsCustom,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );

        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        uint256 balanceBeforeSDCRV = sdcrv.balanceOf(BOB);
        uint256 balanceBeforeSDBAL = sdbal.balanceOf(BOB);
        uint256 balanceBeforeSDFXS = sdfxs.balanceOf(BOB);
        uint256 balanceBeforeSDANGLE = sdangle.balanceOf(BOB);
        vm.prank(BOB);
        claimer.claimAndExtraActions(executeActions, gaugesList2, actions);

        assertEq(sdcrv.balanceOf(BOB), balanceBeforeSDCRV + amountToClaimCustomSdCRV);
        assertEq(sdbal.balanceOf(BOB), balanceBeforeSDBAL + amountToClaimCustomSdBAL);
        assertEq(sdfxs.balanceOf(BOB), balanceBeforeSDFXS + amountToClaimCustomSdFXS);
        assertEq(sdangle.balanceOf(BOB), balanceBeforeSDANGLE + amountToClaimCustomSdANGLE);
    }

    function testClaimBribesSdTKNStake() public {
        updateRoot();
        executeActions[0] = true; // claim bribes
        stakeBribes = true;
        stakeds[0] = true; // fxs
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true; // bal
        stakeds[4] = true; // apw

        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        // Create the Actions structure
        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParamsCustom,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );

        uint256 balanceBeforeGaugeSdCRV = IERC20(GAUGE_SDCRV).balanceOf(BOB);
        uint256 balanceBeforeGaugeSdBAL = IERC20(GAUGE_SDBAL).balanceOf(BOB);
        uint256 balanceBeforeGaugeSdFXS = IERC20(GAUGE_SDFXS).balanceOf(BOB);
        uint256 balanceBeforeGaugeSdANGLE = IERC20(GAUGE_SDANGLE).balanceOf(BOB);
        vm.prank(BOB);
        claimer.claimAndExtraActions(executeActions, gaugesList2, actions);
        uint256 balanceAfterGaugeSdCRV = IERC20(GAUGE_SDCRV).balanceOf(BOB);
        uint256 balanceAfterGaugeSdBAL = IERC20(GAUGE_SDBAL).balanceOf(BOB);
        uint256 balanceAfterGaugeSdFXS = IERC20(GAUGE_SDFXS).balanceOf(BOB);
        uint256 balanceAfterGaugeSdANGLE = IERC20(GAUGE_SDANGLE).balanceOf(BOB);

        assertEq(balanceAfterGaugeSdBAL, balanceBeforeGaugeSdBAL + amountToClaimCustomSdBAL, "1");
        assertEq(balanceAfterGaugeSdCRV, balanceBeforeGaugeSdCRV + amountToClaimCustomSdCRV, "2");
        assertEq(balanceAfterGaugeSdFXS, balanceBeforeGaugeSdFXS + amountToClaimCustomSdFXS, "3");
        assertEq(balanceAfterGaugeSdANGLE, balanceBeforeGaugeSdANGLE + amountToClaimCustomSdANGLE, "4");
    }

    ////////////////////////////////////////////////////////////////
    /// --- SDFRAX3CRV
    ///////////////////////////////////////////////////////////////
    function testClaimVeSDTRewardNoSwap() public {
        executeActions[1] = true;

        uint256 balanceBefore = sdfrax3crv.balanceOf(ALICE);
        claim(ALICE);
        uint256 balanceAfter = sdfrax3crv.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap0() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;

        uint256 balanceBefore = frax3crv.balanceOf(ALICE);
        claim(ALICE);
        uint256 balanceAfter = frax3crv.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap1() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 1;

        uint256 balanceBefore = frax.balanceOf(ALICE);
        claim(ALICE);
        uint256 balanceAfter = frax.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap2NoLock() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 2;

        uint256 balanceBefore = sdt.balanceOf(ALICE);
        claim(ALICE);
        uint256 balanceAfter = sdt.balanceOf(ALICE);

        assertGt(balanceAfter, balanceBefore);
    }

    function testClaimVeSDTRewardSwap2Lock() public {
        executeActions[1] = true;
        swapVeSDTRewards = true;
        choice = 2;
        lockSDT = true;

        IVeSDT.LockedBalance memory lockedBefore = vesdt.locked(ALICE);
        claim(ALICE);
        IVeSDT.LockedBalance memory lockedAfter = vesdt.locked(ALICE);

        assertGt(lockedAfter.amount, lockedBefore.amount);
    }

    ////////////////////////////////////////////////////////////////
    /// --- GAUGES
    ///////////////////////////////////////////////////////////////
    function testClaimGaugesSimple() public {
        executeActions[2] = true;

        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = angle.balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        claim(ALICE);

        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR);
        assertEq(angle.balanceOf(ALICE), balanceBeforeANGLE + claimableANGLE);
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3);
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV + claimableCRV);
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT);
    }

    function testClaimGaugesBuyWithoutStaking() public {
        executeActions[2] = true;
        buys[1] = true; // angle
        buys[2] = true; // crv
        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 dy = IStableSwap(POOL_CRV_SDCRV).get_dy(0, 1, claimableCRV);
        minAmounts[2] = dy * (BASE_UNIT - SLIPPAGE) / BASE_UNIT;

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = angle.balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBeforeSDCRV = sdcrv.balanceOf(ALICE);
        uint256 balanceBeforeSDANGLE = sdangle.balanceOf(ALICE);
        claim(ALICE);
        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR);
        assertEq(angle.balanceOf(ALICE), balanceBeforeANGLE);
        assertGt(sdangle.balanceOf(ALICE), balanceBeforeSDANGLE);
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3);
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV);
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT);
        assertEq(sdcrv.balanceOf(ALICE), balanceBeforeSDCRV + dy);
    }

    function testClaimGaugesBuyStaking() public {
        executeActions[2] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;
        buys[0] = true;
        buys[1] = true; // angle
        buys[2] = true; // crv
        buys[3] = true;
        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 dy = IStableSwap(POOL_CRV_SDCRV).get_dy(0, 1, claimableCRV);
        minAmounts[2] = dy * (BASE_UNIT - SLIPPAGE) / BASE_UNIT;

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = angle.balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBeforeSDCRVGauge = IERC20(GAUGE_SDCRV).balanceOf(ALICE);
        uint256 balanceBeforeSDANGLEGAUGE = IERC20(GAUGE_SDANGLE).balanceOf(ALICE);
        claim(ALICE);
        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR);
        assertEq(angle.balanceOf(ALICE), balanceBeforeANGLE);
        assertGt(IERC20(GAUGE_SDANGLE).balanceOf(ALICE), balanceBeforeSDANGLEGAUGE);
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3);
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV);
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT);
        assertEq(IERC20(GAUGE_SDCRV).balanceOf(ALICE), balanceBeforeSDCRVGauge + dy);
    }

    function testClaimGaugesMintWithoutStaking() public {
        executeActions[2] = true;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;
        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = sdangle.balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBeforeSDCRV = sdcrv.balanceOf(ALICE);
        claim(ALICE);
        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR, "1");
        assertApproxEqRel(sdangle.balanceOf(ALICE), balanceBeforeANGLE + claimableANGLE, 1e15, "2");
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3, "3");
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV, "4");
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT, "5");
        assertApproxEqRel(sdcrv.balanceOf(ALICE), balanceBeforeSDCRV + claimableCRV, 1e15, "6"); // due to incentives fee to lock on depositor
    }

    function testClaimGaugesMintStaking() public {
        executeActions[2] = true;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;
        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = IERC20(GAUGE_SDANGLE).balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        uint256 balanceBeforeSDCRVGauge = IERC20(GAUGE_SDCRV).balanceOf(ALICE);
        claim(ALICE);
        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR);
        assertApproxEqRel(IERC20(GAUGE_SDANGLE).balanceOf(ALICE), balanceBeforeANGLE + claimableANGLE, 1e15);
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3);
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV);
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT);
        assertApproxEqRel(IERC20(GAUGE_SDCRV).balanceOf(ALICE), balanceBeforeSDCRVGauge + claimableCRV, 1e15);
    }

    function testClaimGaugesSimpleBalancer() public {
        executeActions[2] = true;

        (,,,,, uint256 claimableBAL) = claimableAmount(BOB);
        uint256 balanceBeforeBal = bal.balanceOf(BOB);
        claim(BOB);
        assertEq(bal.balanceOf(BOB), balanceBeforeBal + claimableBAL, "2");
    }

    function testClaimGaugesBuyWithoutStakingBalancer() public {
        executeActions[2] = true;
        buys[0] = true;
        buys[1] = true; // angle
        buys[2] = true; // crv
        buys[3] = true;

        (uint256 claimableSDT,,,,, uint256 claimableBAL) = claimableAmount(BOB);
        uint256 balanceBeforeSDT = sdt.balanceOf(BOB);
        uint256 balanceBeforeSDBAL = sdbal.balanceOf(BOB);
        claim(BOB);
        assertEq(sdt.balanceOf(BOB), balanceBeforeSDT + claimableSDT, "1");
        assertApproxEqRel(sdbal.balanceOf(BOB), balanceBeforeSDBAL + (claimableBAL * 622 / 1533), 4e16, "2"); // current price between
    }

    function testClaimGaugesBuyAndStakingBalancer() public {
        executeActions[2] = true;
        buys[0] = true;
        buys[1] = true; // angle
        buys[2] = true; // crv
        buys[3] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;

        (,,,,, uint256 claimableBAL) = claimableAmount(BOB);
        uint256 balanceBeforeSDBALGauge = IERC20(GAUGE_SDBAL).balanceOf(BOB);
        claim(BOB);
        assertApproxEqRel(
            IERC20(GAUGE_SDBAL).balanceOf(BOB), balanceBeforeSDBALGauge + (claimableBAL * 622 / 1533), 5e16, "2"
        );
    }

    function testClaimGaugesMintWithoutStakingBalancer() public {
        executeActions[2] = true;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;

        (,,,,, uint256 claimableBAL) = claimableAmount(BOB);
        uint256 balanceBeforeSDBAL = sdbal.balanceOf(BOB);
        claim(BOB);
        assertApproxEqRel(sdbal.balanceOf(BOB), balanceBeforeSDBAL + (claimableBAL * 622 / 1533), 4e16, "2"); // current price between
    }

    function testClaimGaugesMintAndStakingBalancer() public {
        executeActions[2] = true;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;

        (,,,,, uint256 claimableBAL) = claimableAmount(BOB);
        uint256 balanceBeforeSDBALGauge = IERC20(GAUGE_SDBAL).balanceOf(BOB);
        claim(BOB);
        assertApproxEqRel(
            IERC20(GAUGE_SDBAL).balanceOf(BOB), balanceBeforeSDBALGauge + (claimableBAL * 622 / 1533), 5e16, "2"
        );
    }

    ////////////////////////////////////////////////////////////////
    /// --- CLAIM REWARDS
    ///////////////////////////////////////////////////////////////

    function testClaimReward() public {
        vm.prank(LOCAL_DEPLOYER);
        claimer.init();
        (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
        ) = claimableAmount(ALICE);

        uint256 balanceBeforeCRV3 = crv3.balanceOf(ALICE);
        uint256 balanceBeforeCRV = crv.balanceOf(ALICE);
        uint256 balanceBeforeANGLE = angle.balanceOf(ALICE);
        uint256 balanceBeforeAGEUR = ageur.balanceOf(ALICE);
        uint256 balanceBeforeSDT = sdt.balanceOf(ALICE);
        vm.prank(ALICE);
        claimer.claimRewards(gaugesList1);

        assertEq(ageur.balanceOf(ALICE), balanceBeforeAGEUR + claimableAGEUR);
        assertEq(angle.balanceOf(ALICE), balanceBeforeANGLE + claimableANGLE);
        assertEq(crv3.balanceOf(ALICE), balanceBeforeCRV3 + claimableCRV3);
        assertEq(crv.balanceOf(ALICE), balanceBeforeCRV + claimableCRV);
        assertEq(sdt.balanceOf(ALICE), balanceBeforeSDT + claimableSDT);
    }

    function testClaimRewardRevert() public {
        vm.startPrank(LOCAL_DEPLOYER);
        claimer.init();
        claimer.toggleBlacklistOnGauge(gaugesList1[0]);
        vm.stopPrank();
        vm.prank(ALICE);
        vm.expectRevert(ClaimRewardModular.BLACKLISTED_GAUGE.selector);
        claimer.claimRewards(gaugesList1);
    }

    function testClaimExtraRevert0() public {
        executeActions[2] = true;

        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        lockeds.push(false);

        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );
        vm.prank(ALICE);
        vm.expectRevert(ClaimRewardModular.DIFFERENT_LENGTH.selector);
        claimer.claimAndExtraActions(executeActions, gaugesList1, actions);

        stakeds.push(true);
        actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );
        vm.prank(ALICE);
        vm.expectRevert(ClaimRewardModular.DIFFERENT_LENGTH.selector);
        claimer.claimAndExtraActions(executeActions, gaugesList1, actions);

        buys.push(true);
        actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );
        vm.prank(ALICE);
        vm.expectRevert(ClaimRewardModular.DIFFERENT_LENGTH.selector);
        claimer.claimAndExtraActions(executeActions, gaugesList1, actions);
    }

    function testClaimExtraRevert1() public {
        executeActions[2] = true;

        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        vm.prank(LOCAL_DEPLOYER);
        claimer.toggleBlacklistOnGauge(GAUGE_SDCRV);

        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );
        vm.prank(ALICE);
        vm.expectRevert(ClaimRewardModular.BLACKLISTED_GAUGE.selector);
        claimer.claimAndExtraActions(executeActions, gaugesList1, actions);
    }

    function testClaimExtraCompletALICE() public {
        executeActions[0] = true;
        executeActions[1] = true;
        executeActions[2] = true;
        stakeBribes = true;
        choice = 2;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;
        lockSDT = true;

        claim(ALICE);
    }

    function testClaimExtraCompletBOB() public {
        executeActions[0] = true;
        executeActions[1] = true;
        executeActions[2] = true;
        stakeBribes = true;
        choice = 2;
        lockeds[0] = true;
        lockeds[1] = true; // angle
        lockeds[2] = true; // crv
        lockeds[3] = true;
        stakeds[0] = true;
        stakeds[1] = true; // angle
        stakeds[2] = true; // crv
        stakeds[3] = true;
        lockSDT = true;
        updateRoot();
        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();
        // Create the Actions structure
        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParamsCustom,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );

        vm.prank(BOB);
        claimer.claimAndExtraActions(executeActions, gaugesList2, actions);
    }

    ////////////////////////////////////////////////////////////////
    /// --- HELPERS
    ///////////////////////////////////////////////////////////////
    function claim(address user) public {
        // Create the Actions structure
        ClaimRewardModular.Actions memory actions = ClaimRewardModular.Actions(
            claimParams,
            stakeBribes,
            swapVeSDTRewards,
            choice,
            minAmountSDT,
            lockeds,
            stakeds,
            buys,
            minAmounts,
            lockSDT
        );
        vm.startPrank(LOCAL_DEPLOYER);
        addDepositorsAndPools();
        claimer.init();
        vm.stopPrank();

        vm.startPrank(user);
        if (user == ALICE) claimer.claimAndExtraActions(executeActions, gaugesList1, actions);
        if (user == BOB) claimer.claimAndExtraActions(executeActions, gaugesList2, actions);
        vm.stopPrank();
    }

    function baseClaim() public {
        // List of actions to execute
        //bool[] memory executeActions = new bool[](3);
        executeActions.push(false); // Claim rewards from bribes
        executeActions.push(false); // Claim rewards from veSDT
        executeActions.push(false); // Claim rewards from lockers/strategies
        stakeBribes = false;

        // Params for claiming bribes
        // Bribes in 3CRV
        claimParams.push(IMultiMerkleStash.claimParam(CRV3, claimer3CRV1Index, amountToClaim3CRV1, merkleProof3CRV1));
        // Bribes in GNO
        claimParams.push(IMultiMerkleStash.claimParam(GNO, claimerGNOIndex, amountToClaimGNO, merkleProofGNO));
        // Bribes in SDT
        claimParams.push(IMultiMerkleStash.claimParam(SDT, claimerSDTIndex, amountToClaimSDT, merkleProofSDT));

        // Bribes in sdCRV
        claimParamsCustom.push(
            IMultiMerkleStash.claimParam(SD_CRV, 0, amountToClaimCustomSdCRV, merkleProofCustomSdCRV)
        );
        claimParamsCustom.push(
            IMultiMerkleStash.claimParam(SD_BAL, 0, amountToClaimCustomSdBAL, merkleProofCustomSdBAL)
        );
        claimParamsCustom.push(
            IMultiMerkleStash.claimParam(SD_ANGLE, 0, amountToClaimCustomSdANGLE, merkleProofCustomSdANGLE)
        );
        claimParamsCustom.push(
            IMultiMerkleStash.claimParam(SD_FXS, 0, amountToClaimCustomSdFXS, merkleProofCustomSdFXS)
        );
        // Params for rewards from veSDT
        swapVeSDTRewards = false;
        choice = 0;
        minAmountSDT = 0;

        // List of actions to do
        lockeds.push(false); // fxs
        lockeds.push(false); // angle
        lockeds.push(false); // crv
        lockeds.push(false); // bal
        lockeds.push(false); // apw
        stakeds.push(false); // fxs
        stakeds.push(false); // angle
        stakeds.push(false); // crv
        stakeds.push(false); // bal
        stakeds.push(false); //apw
        buys.push(false); // fxs
        buys.push(false); // angle
        buys.push(false); // crv
        buys.push(false); // bal
        buys.push(false); // apw
        minAmounts.push(0); // fxs
        minAmounts.push(0); // angle
        minAmounts.push(0); // crv
        minAmounts.push(0); // bal
        minAmounts.push(0); // apw

        // Lock SDT
        lockSDT = false;
    }

    function addDepositorsAndPools() public {
        claimer.addDepositor(FXS, FXS_DEPOSITOR);
        claimer.addDepositor(ANGLE, ANGLE_DEPOSITOR);
        claimer.addDepositor(CRV, CRV_DEPOSITOR);
        claimer.addDepositor(BAL, BAL_DEPOSITOR);
        claimer.addDepositor(APW, APW_DEPOSITOR);
        claimer.addPool(FXS, POOL_FXS_SDFXS);
        claimer.addPool(ANGLE, POOL_ANGLE_SDANGLE);
        claimer.addPool(CRV, POOL_CRV_SDCRV);
        claimer.addPool(BAL, POOL_BAL_SDBAL);
        claimer.addPool(APW, POOL_APW_SDAPW);
        claimer.addSdGauge(SD_FXS, GAUGE_SDFXS);
        claimer.addSdGauge(SD_ANGLE, GAUGE_SDANGLE);
        claimer.addSdGauge(SD_CRV, GAUGE_SDCRV);
        claimer.addSdGauge(SD_BAL, GAUGE_SDBAL);
    }

    function claimableAmount(address user)
        public
        view
        returns (
            uint256 claimableSDT,
            uint256 claimableCRV,
            uint256 claimableCRV3,
            uint256 claimableANGLE,
            uint256 claimableAGEUR,
            uint256 claimableBAL
        )
    {
        claimableSDT = ILiquidityGauge(GAUGE_SDCRV).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_SDANGLE).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_SDFXS).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_SDBAL).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_SDBPT).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_SDAPW).claimable_reward(user, SDT)
            + ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).claimable_reward(user, SDT);
        claimableCRV = ILiquidityGauge(GAUGE_SDCRV).claimable_reward(user, CRV);
        claimableCRV3 = ILiquidityGauge(GAUGE_SDCRV).claimable_reward(user, CRV3);
        claimableAGEUR = ILiquidityGauge(GAUGE_SDANGLE).claimable_reward(user, AG_EUR);
        claimableANGLE = ILiquidityGauge(GAUGE_SDANGLE).claimable_reward(user, ANGLE)
            + ILiquidityGauge(GAUGE_GUNI_AGEUR_ETH).claimable_reward(user, ANGLE);
        claimableBAL = ILiquidityGauge(GAUGE_SDBAL).claimable_reward(user, BAL);
    }

    function updateRoot() public {
        vm.startPrank(IMultiMerkleStash(claimer.multiMerkleStash()).owner());
        IMultiMerkleStash(claimer.multiMerkleStash()).updateMerkleRoot(SD_CRV, merkleRootCustomSdCRV);
        IMultiMerkleStash(claimer.multiMerkleStash()).updateMerkleRoot(SD_BAL, merkleRootCustomSdBAL);
        IMultiMerkleStash(claimer.multiMerkleStash()).updateMerkleRoot(SD_ANGLE, merkleRootCustomSdANGLE);
        IMultiMerkleStash(claimer.multiMerkleStash()).updateMerkleRoot(SD_FXS, merkleRootCustomSdFXS);
        vm.stopPrank();
    }
}
