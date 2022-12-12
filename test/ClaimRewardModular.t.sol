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
import {Constants} from "test/fixtures/Constants.sol";
import {MerkleProofFile} from "test/fixtures/MerkleProofFile.sol";

contract ClaimRewardModularTest is Test, Constants, MerkleProofFile {
    address public constant ALICE = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public constant LOCAL_DEPLOYER = address(0xDE);

    address[] public gauges;

    ClaimRewardModular public claimer;
    IERC20 public sdfrax3crv = IERC20(SD_FRAX_3CRV);
    IERC20 public frax3crv = IERC20(FRAX_3CRV);

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

        gauges.push(GAUGE_GUNI_AGEUR_ETH);
        gauges.push(GAUGE_SDCRV);
        gauges.push(GAUGE_SDANGLE);
        //lockeds.push(true)
    }

    function testInit() public {
        bool[] memory executeActions = new bool[](3);
        executeActions[0] = true;
        executeActions[1] = true;
        executeActions[2] = true;

        bool[] memory lockeds = new bool[](3);
        bool[] memory stakeds = new bool[](3);
        bool[] memory buys = new bool[](3);
        lockeds[0] = false; // fxs
        lockeds[1] = true; // angle
        lockeds[2] = false; // crv
        stakeds[0] = false; // fxs
        stakeds[1] = true; // angle
        stakeds[2] = false; // crv
        buys[0] = false; // fxs
        buys[1] = false; // angle
        buys[2] = true; // crv

        IMultiMerkleStash.claimParam[] memory claimParams = new IMultiMerkleStash.claimParam[](1);
        IMultiMerkleStash.claimParam memory claimParam3CRV =
            IMultiMerkleStash.claimParam(CRV3, claimer3CRV1Index, amountToClaim3CRV1, merkleProof3CRV1);
        claimParams[0] = claimParam3CRV;

        ClaimRewardModular.Actions memory actions =
            ClaimRewardModular.Actions(claimParams, true, 2, lockeds, stakeds, buys, true);

        vm.startPrank(ALICE);
        sdfrax3crv.approve(address(claimer), type(uint256).max);
        claimer.claimAndExtraActions(executeActions, gauges, actions);
    }
}
