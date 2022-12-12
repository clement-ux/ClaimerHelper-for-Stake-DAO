// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/forge-std/src/Test.sol";

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IMetapool} from "src/interfaces/IMetapool.sol";
import {IPoolSDTFXPB} from "src/interfaces/IPoolSDTFXPB.sol";
import {IFraxUsdc} from "src/interfaces/IFraxUsdc.sol";
import {IZap} from "src/interfaces/IZap.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ClaimRewardModular {
    using SafeERC20 for IERC20;

    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
    address public constant VE_SDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant CRV_FRAX = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address public constant FRAX_USDC_POOL = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address public constant SDT_FXBP = 0x3e3C6c7db23cdDEF80B694679aaF1bCd9517D0Ae;
    address public constant GC_LOCKERS = 0x75f8f7fa4b6DA6De9F4fE972c811b778cefce882;
    address public constant GC_STRATEGIES = 0x3F3F0776D411eb97Cfa4E3eb25F33c01ca4e7Ca8;

    address public multiMerkleStash;
    address public governance;
    address public veSDTFeeDistributor;

    uint256 private constant MAX_REWARDS = 8;
    uint256 private constant BASE_UNIT = 1e18;
    uint256 public depositorsCount;
    uint256 public poolsCount;

    uint256 public slippage;

    bool public initialization;

    mapping(address => address) public depositors;
    mapping(address => uint256) public depositorsIndex;
    mapping(address => address) public pools;
    mapping(address => uint256) public poolsIndex;
    mapping(address => bool) public blacklisted;

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

    error GAUGE_NOT_ENABLE();
    error BLACKLISTED_GAUGE();
    error ALREADY_INITIALIZED();

    event GaugeEnabled(address gauge);
    event GaugeDisabled(address gauge);
    event DepositorEnabled(address token, address depositor);
    event PoolAdded(address token, address depositor);
    event Recovered(address token, uint256 amount);
    event RewardsClaimed(address[] gauges);
    event GovernanceChanged(address oldG, address newG);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    constructor() {
        governance = msg.sender;
        veSDTFeeDistributor = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
        multiMerkleStash = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;
        slippage = 1e16;
    }

    function init() external onlyGovernance {
        if (initialization) revert ALREADY_INITIALIZED();
        initialization = true;
        IERC20(SD_FRAX_3CRV).approve(SD_FRAX_3CRV, type(uint256).max);
        IERC20(FRAX_3CRV).approve(FRAX_3CRV, type(uint256).max);
        IERC20(FRAX).approve(SDT_FXBP, type(uint256).max);
        IERC20(CRV_FRAX).approve(SDT_FXBP, type(uint256).max);
        IERC20(SDT).approve(VE_SDT, type(uint256).max);
        IERC20(FRAX).approve(FRAX_USDC_POOL, type(uint256).max);
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
        if (executeActions[0]) _processBribes(actions.claims, msg.sender);

        if (executeActions[1]) _processSdFrax3CRV(actions.swapVeSDTRewards, actions.choice);

        if (executeActions[2]) _processGaugesClaim(gauges, actions);

        _processSDT(actions.lockSDT);
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    ///////////////////////////////////////////////////////////////
    function _processBribes(IMultiMerkleStash.claimParam[] calldata claims, address user) internal {
        uint256 balanceBefore = IERC20(SDT).balanceOf(user);
        IMultiMerkleStash(multiMerkleStash).claimMulti(user, claims);
        uint256 diff = IERC20(SDT).balanceOf(user) - balanceBefore;
        if (diff > 0) IERC20(SDT).safeTransferFrom(user, address(this), diff);
    }

    function _processSdFrax3CRV(bool swap, uint256 choice) internal {
        // Choice : 0 -> Obtain FRAX_3CRV
        // Choice : 1 -> Obtain FRAX
        // Choice : 2 -> Obtain SDT
        uint256 balance = IVault(SD_FRAX_3CRV).balanceOf(msg.sender);
        IFeeDistributor(veSDTFeeDistributor).claim(msg.sender);
        if (swap) {
            uint256 diff = IVault(SD_FRAX_3CRV).balanceOf(msg.sender) - balance;
            IERC20(SD_FRAX_3CRV).safeTransferFrom(msg.sender, address(this), diff);
            balance = IERC20(SD_FRAX_3CRV).balanceOf(address(this));
            IERC20(SD_FRAX_3CRV).approve(SD_FRAX_3CRV, balance);
            IVault(SD_FRAX_3CRV).withdraw(balance);
            balance = IERC20(FRAX_3CRV).balanceOf(address(this));
            if (choice == 0) IERC20(FRAX_3CRV).transfer(msg.sender, balance);
            if (choice == 1) IMetapool(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, msg.sender);
            if (choice > 1) {
                uint256 received = IMetapool(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, address(this));
                _swapFRAXForSDT(received, address(this));
            }
        }
    }

    function _processGaugesClaim(address[] memory _gauges, Actions memory _actions) internal {
        Actions memory lockStatus = _actions;
        require(lockStatus.locked.length == lockStatus.staked.length, "different length");
        require(lockStatus.locked.length == depositorsCount, "different depositors length");
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
            for (uint8 j = 1; j < MAX_REWARDS;) {
                address token = ILiquidityGauge(gauge).reward_tokens(j);
                if (token == address(0)) {
                    break;
                }
                address depositor = depositors[token];
                address pool = pools[token];
                uint256 balance = IERC20(token).balanceOf(address(this));
                if (balance != 0) {
                    // Buy sdTKN from liquidity pool and stake sdTKN on gauge
                    if (pool != address(0) && lockStatus.buy[poolsIndex[pool]]) {
                        IERC20(token).approve(pool, balance);
                        uint256 received = _swapTKNForSdTKN(pool, balance, address(this));
                        // No sure if the gauge are the good one here
                        address sdToken = IPoolSDTFXPB(pool).coins(1);
                        IERC20(sdToken).approve(gauge, received);
                        ILiquidityGauge(gauge).deposit(received, msg.sender);
                        console.log("1");
                    }
                    // Mint sdTKN using depositor
                    else if (depositor != address(0) && lockStatus.locked[depositorsIndex[depositor]]) {
                        IERC20(token).approve(depositor, balance);
                        if (lockStatus.staked[depositorsIndex[depositor]]) {
                            IDepositor(depositor).deposit(balance, false, true, msg.sender);
                        } else {
                            IDepositor(depositor).deposit(balance, false, false, msg.sender);
                        }
                        console.log("2");
                    }
                    // Transfer TKN to user
                    else {
                        SafeERC20.safeTransfer(IERC20(token), msg.sender, balance);
                        console.log("3");
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
                IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
            } else {
                SafeERC20.safeTransfer(IERC20(SDT), msg.sender, amount);
            }
            require(IERC20(SDT).balanceOf(address(this)) == 0, "wrong amount sent");
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- HELPERS
    ///////////////////////////////////////////////////////////////
    function _swapFRAXForSDT(uint256 _amount, address _receiver) private returns (uint256 output) {
        // Get crvFRAX LP
        IFraxUsdc(FRAX_USDC_POOL).add_liquidity([_amount, 0], 0);

        uint256 balance = IERC20(CRV_FRAX).balanceOf(address(this));
        // calculate amount received
        uint256 amount = IPoolSDTFXPB(SDT_FXBP).get_dy(1, 0, balance);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap ETH for STETH
        output = IPoolSDTFXPB(SDT_FXBP).exchange(1, 0, balance, minAmount, false, _receiver);
    }

    function _swapTKNForSdTKN(address _pool, uint256 _amount, address _receiver) private returns (uint256 output) {
        // calculate amount received
        uint256 amount = IMetapool(_pool).get_dy(0, 1, _amount);

        // calculate minimum amount received
        uint256 minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        // swap ETH for STETH
        output = IMetapool(_pool).exchange(0, 1, _amount, minAmount, _receiver);
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////
    function addDepositor(address _token, address _depositor) external onlyGovernance {
        require(_token != address(0), "can't be zero address");
        require(_depositor != address(0), "can't be zero address");
        require(depositors[_token] == address(0), "already added");
        depositors[_token] = _depositor;
        depositorsIndex[_depositor] = depositorsCount;
        ++depositorsCount;
        emit DepositorEnabled(_token, _depositor);
    }

    function toggleBlacklistOnPool(address pool) external onlyGovernance {
        require(pool != address(0), "address null");
        blacklisted[pool] = !blacklisted[pool];
    }

    function addPool(address token, address pool) external onlyGovernance {
        require(token != address(0), "can't be zero address");
        require(pool != address(0), "can't be zero address");
        require(pools[token] == address(0), "already added");
        pools[token] = pool;
        poolsIndex[pool] = poolsCount;
        ++poolsCount;
        emit PoolAdded(token, pool);
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "can't be zero address");
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }
}
