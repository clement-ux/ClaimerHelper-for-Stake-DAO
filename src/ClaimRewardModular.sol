// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IStableSwap} from "src/interfaces/IStableSwap.sol";
import {IZap} from "src/interfaces/IZap.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ClaimRewardModular {
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS
    ///////////////////////////////////////////////////////////////

    struct Actions {
        // For Bribes
        IMultiMerkleStash.claimParam[] claims;
        // For veSDT rewards
        bool swapVeSDTRewards;
        uint256 choice;
        // For lockers and strategies rewards
        bool[] locked;
        bool[] staked;
        bool[] buy;
        // For relocking SDT into veSDT
        bool lockSDT;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ///////////////////////////////////////////////////////////////

    address public constant VE_SDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
    address public constant SDT_FXBP = 0x3e3C6c7db23cdDEF80B694679aaF1bCd9517D0Ae;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;

    address public constant GC_LOCKERS = 0x75f8f7fa4b6DA6De9F4fE972c811b778cefce882;
    address public constant GC_STRATEGIES = 0x3F3F0776D411eb97Cfa4E3eb25F33c01ca4e7Ca8;
    address public constant CURVE_ZAPPER = 0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895;

    uint256 private constant MAX_REWARDS = 8;
    uint256 private constant BASE_UNIT = 1e18;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARS
    ///////////////////////////////////////////////////////////////

    address public governance;
    address public multiMerkleStash = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;
    address public veSDTFeeDistributor = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;

    uint256 public depositorsCount;
    uint256 public poolsCount;
    uint256 public slippage = 1e16;

    bool public initialization;

    mapping(address => address) public depositors;
    mapping(address => uint256) public depositorsIndex;
    mapping(address => address) public pools;
    mapping(address => uint256) public poolsIndex;
    mapping(address => bool) public blacklisted;

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    event GaugeEnabled(address gauge);
    event GaugeDisabled(address gauge);
    event DepositorEnabled(address token, address depositor);
    event PoolAdded(address token, address depositor);
    event Recovered(address token, uint256 amount);
    event RewardsClaimed(address[] gauges);
    event GovernanceChanged(address oldG, address newG);

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    error GAUGE_NOT_ENABLE();
    error BLACKLISTED_GAUGE();
    error ALREADY_INITIALIZED();
    error ALREADY_ADDED();
    error NOT_ADDED();
    error DIFFERENT_LENGTH();
    error BALANCE_NOT_NULL();
    error ADDRESS_NULL();

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    constructor() {
        governance = msg.sender;
    }

    function init() external onlyGovernance {
        if (initialization) revert ALREADY_INITIALIZED();
        initialization = true;
        IERC20(SD_FRAX_3CRV).approve(SD_FRAX_3CRV, type(uint256).max);
        IERC20(FRAX_3CRV).approve(FRAX_3CRV, type(uint256).max);
        IERC20(FRAX).approve(CURVE_ZAPPER, type(uint256).max);
        IERC20(SDT).approve(VE_SDT, type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////
    /// --- EXTERNAL LOGIC
    ///////////////////////////////////////////////////////////////

    function claimRewards(address[] calldata _gauges) external {
        uint256 length = _gauges.length;
        for (uint8 i; i < length;) {
            address gauge = _gauges[i];
            if (blacklisted[gauge]) revert BLACKLISTED_GAUGE();

            (bool success1,) = GC_LOCKERS.call(abi.encodeWithSignature("gauge_types(address)", gauge));
            (bool success2,) = GC_STRATEGIES.call(abi.encodeWithSignature("gauge_types(address)", gauge));
            if (!success1 && !success2) revert GAUGE_NOT_ENABLE(); // replace : require(gauges[gauge] > 0, "Gauge not enabled");

            ILiquidityGauge(_gauges[i]).claim_rewards_for(msg.sender, msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    // user need to approve this contract for the following token :
    // SDT, SD_FRAX_3CRV
    function claimAndExtraActions(bool[] calldata executeActions, address[] calldata gauges, Actions calldata actions)
        external
    {
        if (executeActions[0]) _processBribes(actions.claims, msg.sender, actions.lockSDT);

        if (executeActions[1]) _processSdFrax3CRV(actions.swapVeSDTRewards, actions.choice, actions.lockSDT);

        if (executeActions[2]) _processGaugesClaim(gauges, actions);

        _processSDT(actions.lockSDT);
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    ///////////////////////////////////////////////////////////////
    function _processBribes(IMultiMerkleStash.claimParam[] calldata claims, address user, bool lockSDT) internal {
        uint256 balanceBefore = IERC20(SDT).balanceOf(user);
        IMultiMerkleStash(multiMerkleStash).claimMulti(user, claims);
        if (lockSDT) {
            uint256 diff = IERC20(SDT).balanceOf(user) - balanceBefore;
            if (diff > 0) IERC20(SDT).safeTransferFrom(user, address(this), diff);
        }
    }

    function _processSdFrax3CRV(bool swapVeSDTRewards, uint256 choice, bool lockSDT) internal {
        // Choice : 0 -> Obtain FRAX_3CRV
        // Choice : 1 -> Obtain FRAX
        // Choice : 2 -> Obtain SDT
        uint256 balance = IVault(SD_FRAX_3CRV).balanceOf(msg.sender);
        IFeeDistributor(veSDTFeeDistributor).claim(msg.sender);
        if (swapVeSDTRewards) {
            uint256 diff = IERC20(SD_FRAX_3CRV).balanceOf(msg.sender) - balance;
            IERC20(SD_FRAX_3CRV).safeTransferFrom(msg.sender, address(this), diff);
            balance = IERC20(SD_FRAX_3CRV).balanceOf(address(this));
            IERC20(SD_FRAX_3CRV).approve(SD_FRAX_3CRV, balance);
            IVault(SD_FRAX_3CRV).withdraw(balance);
            balance = IERC20(FRAX_3CRV).balanceOf(address(this));
            if (choice < 1) {
                IERC20(FRAX_3CRV).transfer(msg.sender, balance);
            } else if (choice < 2) {
                IStableSwap(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, msg.sender);
            } else {
                uint256 received = IStableSwap(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, address(this));
                if (!lockSDT) _swapFRAXForSDT(received, msg.sender);
                else _swapFRAXForSDT(received, address(this));
            }
        }
    }

    function _processGaugesClaim(address[] memory _gauges, Actions memory _actions) internal {
        Actions memory lockStatus = _actions;
        if (lockStatus.locked.length != lockStatus.staked.length) revert DIFFERENT_LENGTH();
        if (lockStatus.locked.length != lockStatus.buy.length) revert DIFFERENT_LENGTH();
        if (lockStatus.locked.length != depositorsCount) revert DIFFERENT_LENGTH();

        uint256 length = _gauges.length;
        // Claim rewards token from gauges
        for (uint8 index; index < length;) {
            address gauge = _gauges[index];

            if (blacklisted[gauge]) revert BLACKLISTED_GAUGE();
            (bool success1,) = GC_LOCKERS.call(abi.encodeWithSignature("gauge_types(address)", gauge));
            (bool success2,) = GC_STRATEGIES.call(abi.encodeWithSignature("gauge_types(address)", gauge));
            if (!success1 && !success2) revert GAUGE_NOT_ENABLE(); // remplace : require(gauges[gauge] > 0, "Gauge not enabled");

            ILiquidityGauge(gauge).claim_rewards_for(msg.sender, address(this));

            // skip the first reward token, it is SDT for any LGV4
            // it loops at most until max rewards, it is hardcoded on LGV4
            uint256 rewardCount = ILiquidityGauge(gauge).reward_count();
            for (uint8 j = 1; j < rewardCount;) {
                address token = ILiquidityGauge(gauge).reward_tokens(j);
                address depositor = depositors[token];
                address pool = pools[token];
                uint256 balance = IERC20(token).balanceOf(address(this));

                if (balance != 0) {
                    // Buy sdTKN from liquidity pool
                    if (pool != address(0) && lockStatus.buy[poolsIndex[pool]]) {
                        // Don't stake sdTKN on gauge
                        if (!lockStatus.staked[poolsIndex[pool]]) {
                            _swapTKNForSdTKN(pool, balance, msg.sender);
                        }
                        // Stake sdTKN on gauge
                        else {
                            uint256 received = _swapTKNForSdTKN(pool, balance, address(this));
                            IERC20(IStableSwap(pool).coins(1)).approve(gauge, received);
                            ILiquidityGauge(gauge).deposit(received, msg.sender);
                        }
                        console.log("1");
                    }
                    // Mint sdTKN using depositor and stake it on gauge or not
                    else if (depositor != address(0) && lockStatus.locked[depositorsIndex[depositor]]) {
                        IDepositor(depositor).deposit(
                            balance, false, lockStatus.staked[depositorsIndex[depositor]], msg.sender
                        );
                        console.log("2");
                    }
                    // Transfer TKN to user
                    else {
                        IERC20(token).safeTransfer(msg.sender, balance);
                        console.log("3");
                    }
                    if (IERC20(token).balanceOf(address(this)) != 0) revert BALANCE_NOT_NULL();
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
                IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
            } else {
                SafeERC20.safeTransfer(IERC20(SDT), msg.sender, amount);
            }
            if (IERC20(SDT).balanceOf(address(this)) != 0) revert BALANCE_NOT_NULL();
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- HELPERS
    ///////////////////////////////////////////////////////////////
    function _swapFRAXForSDT(uint256 _amount, address _receiver) private returns (uint256 output) {
        // get_dy on the zapper for this _amount
        uint256 amount = IZap(CURVE_ZAPPER).get_dy(SDT_FXBP, 1, 0, _amount);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap FRAX for SDT
        output = IZap(CURVE_ZAPPER).exchange(SDT_FXBP, 1, 0, _amount, minAmount, false, _receiver);
    }

    function _swapTKNForSdTKN(address _pool, uint256 _amount, address _receiver) private returns (uint256 output) {
        // calculate amount received
        uint256 amount = IStableSwap(_pool).get_dy(0, 1, _amount);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap ETH for STETH
        output = IStableSwap(_pool).exchange(0, 1, _amount, minAmount, _receiver);
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////
    function addDepositor(address token, address depositor) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (depositor == address(0)) revert ADDRESS_NULL();
        if (depositors[token] != address(0)) revert ALREADY_ADDED();
        depositors[token] = depositor;
        depositorsIndex[depositor] = depositorsCount;
        ++depositorsCount;
        IERC20(token).approve(depositor, type(uint256).max);
        emit DepositorEnabled(token, depositor);
    }

    function updateDepositor(address token, address newDepositor) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (newDepositor == address(0)) revert ADDRESS_NULL();
        if (depositors[token] == address(0)) revert NOT_ADDED();
        IERC20(token).approve(depositors[token], 0);
        depositors[token] = newDepositor;
        IERC20(token).approve(newDepositor, type(uint256).max);
        emit DepositorEnabled(token, newDepositor);
    }

    function addPool(address token, address pool) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (pool == address(0)) revert ADDRESS_NULL();
        if (pools[token] != address(0)) revert ALREADY_ADDED();
        pools[token] = pool;
        poolsIndex[pool] = poolsCount;
        ++poolsCount;
        IERC20(token).approve(pool, type(uint256).max);
        emit PoolAdded(token, pool);
    }

    function updatePool(address token, address newPool) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (newPool == address(0)) revert ADDRESS_NULL();
        if (pools[token] == address(0)) revert NOT_ADDED();
        IERC20(token).approve(pools[token], type(uint256).max);
        pools[token] = newPool;
        IERC20(token).approve(newPool, type(uint256).max);
        emit PoolAdded(token, newPool);
    }

    function toggleBlacklistOnPool(address pool) external onlyGovernance {
        if (pool == address(0)) revert ADDRESS_NULL();
        blacklisted[pool] = !blacklisted[pool];
    }

    function setGovernance(address _governance) external onlyGovernance {
        if (_governance == address(0)) revert ADDRESS_NULL();
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }
}
