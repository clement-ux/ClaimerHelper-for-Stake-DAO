// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IMetapool} from "src/interfaces/IMetapool.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ClaimRewardModular {
    // using SafeERC20 for IERC20;
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
    address public constant VE_SDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant SDT_FXBP = 0x3e3C6c7db23cdDEF80B694679aaF1bCd9517D0Ae;
    address public constant SDCRV_CRV_POOL = 0xf7b55c3732ad8b2c2da7c24f30a69f55c54fb717;
    address public constant SDCRV_GAUGE = 0x7f50786A0b15723D741727882ee99a0BF34e3466;
    address public multiMerkleStash;
    address public governance;
    address public veSDTFeeDistributor;

    uint256 private constant MAX_REWARDS = 8;
    uint256 private constant BASE_UNIT = 1e18;

    uint256 public slippage;

    mapping(address => address) public depositors;
    mapping(address => uint256) public depositorsIndex;
    mapping(address => uint256) public gauges;
    mapping(address => address) public pools;

    struct LockStatus {
        bool[] locked;
        bool[] staked;
        bool[] buy;
        bool lockSDT;
    }

    uint256 public depositorsCount;

    error GAUGE_NOT_ENABLE();

    constructor() {
        governance = msg.sender;
        veSDTFeeDistributor = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
        multiMerkleStash = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;
        slippage = 1e16;
    }

    function claimRewards(address[] calldata _gauges) external {
        uint256 length = _gauges.length;
        for (uint8 i; i < length;) {
            if (gauges[_gauges[i]] < 1) revert GAUGE_NOT_ENABLE();
            ILiquidityGauge(_gauges[i]).claim_rewards_for(msg.sender, msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function claimAndExtraActions(
        address[] memory _gauges,
        LockStatus memory _lockStatus,
        IMultiMerkleStash.claimParam[] calldata claims,
        bool swap,
        uint256 choice
    ) external {
        _processBribes(claims, msg.sender);

        _processSdFrax3CRV(swap, choice);

        _processGaugesClaim(_gauges, _lockStatus);

        _processSDT(_lockStatus.lockSDT);
    }

    function _processBribes(IMultiMerkleStash.claimParam[] calldata claims, address user) internal {
        IMultiMerkleStash(multiMerkleStash).claimMulti(user, claims);
        // find amount of SDT claimed
        uint256 amountSDT;
        for (uint8 i; i < claims.length;) {
            if (claims[i].token == SDT) {
                amountSDT = claims[i].amount;
                break;
            }
            unchecked {
                ++i;
            }
        }
        IERC20(SDT).transferFrom(user, address(this), amountSDT);
    }

    // Choice : 0 -> Obtain FRAX_3CRV
    // Choice : 1 -> Obtain FRAX
    // Choice : 2 -> Obtain SDT
    function _processSdFrax3CRV(bool swap, uint256 choice) internal {
        uint256 balanceBefore = IVault(SD_FRAX_3CRV).balanceOf(msg.sender);
        IFeeDistributor(veSDTFeeDistributor).claim(msg.sender);
        if (swap) {
            uint256 diff = IVault(SD_FRAX_3CRV).balanceOf(msg.sender) - balanceBefore;
            IVault(SD_FRAX_3CRV).transferFrom(msg.sender, address(this), diff);
            IVault(SD_FRAX_3CRV).withdraw(IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
            uint256 balance = IERC20(FRAX_3CRV).balanceOf(address(this));
            if (choice == 0) IERC20(FRAX_3CRV).transfer(msg.sender, balance);
            if (choice == 1) IMetapool(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, msg.sender);
            if (choice > 1) {
                uint256 received = IMetapool(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, address(this));
                _swapFRAXForSDT(received, msg.sender);
            }
        }
    }

    function _processGaugesClaim(address[] memory _gauges, LockStatus memory _lockStatus) internal {
        LockStatus memory lockStatus = _lockStatus;
        require(lockStatus.locked.length == lockStatus.staked.length, "different length");
        require(lockStatus.locked.length == depositorsCount, "different depositors length");
        uint256 length = _gauges.length;
        // Claim rewards token from gauges
        for (uint8 index; index < length;) {
            address gauge = _gauges[index];
            require(gauges[gauge] > 0, "Gauge not enabled");
            ILiquidityGauge(gauge).claim_rewards_for(msg.sender, address(this));
            // skip the first reward token, it is SDT for any LGV4
            // it loops at most until max rewards, it is hardcoded on LGV4
            for (uint8 j = 1; j < MAX_REWARDS; ++j) {
                address token = ILiquidityGauge(gauge).reward_tokens(j);
                if (token == address(0)) {
                    break;
                }
                address depositor = depositors[token];
                address pool = pools[token];
                uint256 balance = IERC20(token).balanceOf(address(this));
                if (balance != 0) {
                    // Buy sdTKN from liquidity pool and stake sdTKN on gauge
                    if (pool != address(0) && lockStatus.buy[depositorsIndex[depositor]]) {
                        uint256 received = _swapTKNForSdTKN(pool, balance, address(this));
                        // No sure if the gauge are the good one here
                        ILiquidityGauge(gauge).deposit(received, msg.sender);
                    }
                    // Mint sdTKN using depositor
                    if (depositor != address(0) && lockStatus.locked[depositorsIndex[depositor]]) {
                        IERC20(token).approve(depositor, balance);
                        if (lockStatus.staked[depositorsIndex[depositor]]) {
                            IDepositor(depositor).deposit(balance, false, true, msg.sender);
                        } else {
                            IDepositor(depositor).deposit(balance, false, false, msg.sender);
                        }
                    }
                    // Transfer TKN to user
                    else {
                        SafeERC20.safeTransfer(IERC20(token), msg.sender, balance);
                    }
                    uint256 balanceLeft = IERC20(token).balanceOf(address(this));
                    require(balanceLeft == 0, "wrong amount sent");
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++index;
            }
        }
    }

    function _processSDT(bool lockSDT) internal {
        uint256 amount = IERC20(SDT).balanceOf(address(this));
        if (amount != 0) {
            if (lockSDT) {
                IERC20(SDT).approve(VE_SDT, amount);
                IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
            } else {
                SafeERC20.safeTransfer(IERC20(SDT), msg.sender, amount);
            }
            require(IERC20(SDT).balanceOf(address(this)) == 0, "wrong amount sent");
        }
    }


    function _swapFRAXForSDT(uint256 _amount, address _receiver) internal returns (uint256 output) {
        // calculate amount received
        uint256 amount = IMetapool(SDT_FXBP).get_dy(1, 0, _amount);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap ETH for STETH
        output = IMetapool(SDT_FXBP).exchange(1, 0, _amount, minAmount, _receiver);
    }

    function _swapTKNForSdTKN(address _pool, uint256 _amount, address _receiver) internal returns(uint256 output) {
        // calculate amount received
        uint256 amount = IMetapool(_pool).get_dy(0, 1, _amount);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap ETH for STETH
        output = IMetapool(_pool).exchange(0, 1, _amount, minAmount, _receiver);
    }
}

// VE_SDT Reward
// Lockers
// Strategie
// Bribes

//
// 0 claim sdFrax3CRV
// 1 claim sdFrax3CRV converted into 3CRV
// 2 claim sdFrax3CRV converted into SDT
