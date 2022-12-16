// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Script.sol";

import {ClaimRewardModular} from "src/ClaimRewardModular.sol";
import {Constants} from "test/fixtures/Constants.sol";

contract ClaimRewardModularScript is Script, Test, Constants {
    ClaimRewardModular public claimer;

    function run() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 16_150_119);
        vm.selectFork(forkId);

        vm.startBroadcast(address(0xBAD));
        // Deploye ClaimRewardModular contract
        claimer = new ClaimRewardModular();

        // Call setters
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
        vm.stopBroadcast();
    }
}
