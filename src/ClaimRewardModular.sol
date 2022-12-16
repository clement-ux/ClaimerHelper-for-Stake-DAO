// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IDepositor} from "src/interfaces/IDepositor.sol";
import {IVeSDT} from "src/interfaces/IVeSDT.sol";
import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IStableSwap} from "src/interfaces/IStableSwap.sol";
import {IZap} from "src/interfaces/IZap.sol";
import {IZapBalancer} from "src/interfaces/IZapBalancer.sol";
import {IBalancerVault} from "src/interfaces/IBalancerVault.sol";
import {IBalancerStablePool} from "src/interfaces/IBalancerStablePool.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ClaimRewardModular {
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS
    ///////////////////////////////////////////////////////////////
    /// @notice Actions structure
    /// @param claims Merkleproof and co.
    /// @param stakeBribes Stake bribes (like SDT or sdCRV etc.)
    /// @param swapVeSDTRewards Swap rewards from veSDT
    /// @param choice Choice for swapping :
    /// 0 -> FRAX_3CRV; 1 -> FRAX; 2 -> SDT
    /// @param minAmountSDT minAmount received from swap
    /// @param locked if obtaining sdToken using depositor (minting)
    /// @param staked if stake sdToken on gauge
    /// @param buy if obtaining sdToken using pool(buying)
    /// @param minAmount min amount obtained for swapping to sdToken
    /// @param lockSDT if locking SDT into veSDT
    struct Actions {
        // For Bribes
        IMultiMerkleStash.claimParam[] claims;
        bool stakeBribes;
        // For veSDT rewards
        bool swapVeSDTRewards;
        uint256 choice;
        uint256 minAmountSDT;
        // For lockers and strategies rewards
        bool[] locked;
        bool[] staked;
        bool[] buy;
        uint256[] minAmount;
        // For relocking SDT into veSDT
        bool lockSDT;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ///////////////////////////////////////////////////////////////
    /* --- Tokens Addresses --- */
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant BPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ANGLE = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;

    /* --- sdTkns Adresses --- */
    address public constant SD_BAL = 0xF24d8651578a55b0C119B9910759a351A3458895;
    address public constant SD_CRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;
    address public constant SD_FXS = 0x402F878BDd1f5C66FdAF0fabaBcF74741B68ac36;
    address public constant SD_ANGLE = 0x752B4c6e92d96467fE9b9a2522EF07228E00F87c;

    address public constant VE_SDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
    address public constant SDT_FXBP = 0x3e3C6c7db23cdDEF80B694679aaF1bCd9517D0Ae;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;

    address public constant GC_LOCKERS = 0x75f8f7fa4b6DA6De9F4fE972c811b778cefce882;
    address public constant GC_STRATEGIES = 0x3F3F0776D411eb97Cfa4E3eb25F33c01ca4e7Ca8;
    address public constant CURVE_ZAPPER = 0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895;
    address public constant BALANCER_ZAPPER = 0x0496d64E43BD68045b8e21f89d8A6Ce6A00ce3Ec;
    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    uint256 private constant BASE_UNIT = 1e18;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARS
    ///////////////////////////////////////////////////////////////

    /// @notice Governance address
    address public governance;
    /// @notice Bribes rewards distributor
    address public multiMerkleStash = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;
    /// @notice veSDT rewards distributor
    address public veSDTFeeDistributor = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
    /// @notice Counter for depositor
    uint256 public depositorsCount;
    /// @notice Counter for pools
    uint256 public poolsCount;
    /// @notice Counter for staking gauge
    uint256 public gaugesCount;
    /// @notice Max slippage for swap
    uint256 public slippage = 1e16;

    /// @notice Token -> Depositors
    mapping(address => address) public depositors;
    /// @notice Depositos -> Index
    mapping(address => uint256) public depositorsIndex;
    /// @notice Tokens -> Pools
    mapping(address => address) public pools;
    /// @notice Pools -> Index
    mapping(address => uint256) public poolsIndex;
    /// @notice Tokens -> staking gauge
    mapping(address => address) public gauges;
    /// @notice staking gauge -> index
    mapping(address => uint256) public gaugesIndex;
    /// @notice Token -> sdToken
    mapping(address => address) public tokenSdToken;
    /// @notice Gauge -> is blacklisted or not
    mapping(address => bool) public blacklisted;

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert AUTH_ONLY_GOVERNANCE();
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////
    event DepositorAdded(address token, address depositor);
    event DepositorUpdated(address token, address depositor);
    event PoolAdded(address token, address pool);
    event PoolUpdated(address token, address pool);
    event GaugeAdded(address token, address gauge);
    event GaugeUpdated(address token, address gauge);
    event Recovered(address token, uint256 amount);
    event RewardsClaimed(address[] gauges);
    event BlacklistGauge(address gauge, bool blacklisted);
    event GovernanceChanged(address oldG, address newG);

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    error BLACKLISTED_GAUGE();

    error NOT_ADDED();
    error ALREADY_ADDED();
    error DIFFERENT_LENGTH();

    error ADDRESS_NULL();
    error BALANCE_NOT_NULL();

    error AUTH_ONLY_GOVERNANCE();

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    constructor() {
        governance = msg.sender;
        IERC20(SDT).safeApprove(VE_SDT, type(uint256).max);
        IERC20(BAL).safeApprove(BALANCER_VAULT, type(uint256).max);
        IERC20(BPT).safeApprove(BALANCER_VAULT, type(uint256).max);
        IERC20(FRAX).safeApprove(CURVE_ZAPPER, type(uint256).max);
        IERC20(FRAX_3CRV).safeApprove(FRAX_3CRV, type(uint256).max);
        IERC20(SD_FRAX_3CRV).safeApprove(SD_FRAX_3CRV, type(uint256).max);
        tokenSdToken[CRV] = SD_CRV;
        tokenSdToken[BAL] = SD_BAL;
        tokenSdToken[FXS] = SD_FXS;
        tokenSdToken[ANGLE] = SD_ANGLE;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EXTERNAL LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Simple function for claiming rewards from differents gauges
    /// @param _gauges List of gauges to claim rewards
    function claimRewards(address[] calldata _gauges) external {
        uint256 length = _gauges.length;
        for (uint8 i; i < length;) {
            address gauge = _gauges[i];
            if (blacklisted[gauge]) revert BLACKLISTED_GAUGE();
            ILiquidityGauge(_gauges[i]).claim_rewards_for(msg.sender, msg.sender);
            unchecked {
                ++i;
            }
        }
        emit RewardsClaimed(_gauges);
    }

    /// @notice Claim multiple rewards and do extra actions on top of it
    /// @dev user need to approve : SDT, SD_FRAX_3CRV, all sdTKN that user want to claim
    /// @param executeActions List of bool representing all actions to do.
    /// Index 0->Claim bribes; Index 1->Claim rewards from veSDT; Index 2->Claim rewards from `_gauges``
    /// @param _gauges List of gauges to claim rewards
    /// @param actions List of Actions to do with rewards obtained
    function claimAndExtraActions(bool[] calldata executeActions, address[] calldata _gauges, Actions calldata actions)
        external
    {
        if (executeActions[0]) _processBribes(actions);

        if (executeActions[1]) _processSdFrax3CRV(actions);

        if (executeActions[2]) _processGaugesClaim(_gauges, actions);

        _processSDT(actions.lockSDT);
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    ///////////////////////////////////////////////////////////////
    /// @notice Internal function for claiming bribes
    /// @param _actions List of Actions to do with rewards obtained
    function _processBribes(Actions calldata _actions) internal {
        Actions memory actions = _actions;
        IMultiMerkleStash(multiMerkleStash).claimMulti(msg.sender, actions.claims);
        if (actions.stakeBribes) {
            uint256 length = actions.claims.length;
            for (uint8 i; i < length;) {
                if (actions.claims[i].token == SDT && actions.lockSDT) {
                    IERC20(SDT).safeTransferFrom(msg.sender, address(this), actions.claims[i].amount);
                } else if (
                    gauges[actions.claims[i].token] != address(0)
                        && actions.staked[gaugesIndex[gauges[actions.claims[i].token]]]
                ) {
                    IERC20(actions.claims[i].token).safeTransferFrom(
                        msg.sender, address(this), actions.claims[i].amount
                    );
                    ILiquidityGauge(gauges[actions.claims[i].token]).deposit(actions.claims[i].amount, msg.sender);
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Internal function for claiming rewards from veSDT
    /// @param _actions List of Actions to do with rewards obtained
    function _processSdFrax3CRV(Actions calldata _actions) internal {
        Actions memory actions = _actions;
        uint256 claimed = IFeeDistributor(veSDTFeeDistributor).claim(msg.sender);
        if (actions.swapVeSDTRewards) {
            IERC20(SD_FRAX_3CRV).safeTransferFrom(msg.sender, address(this), claimed);
            IVault(SD_FRAX_3CRV).withdraw(claimed);
            uint256 balance = IERC20(FRAX_3CRV).balanceOf(address(this));
            if (actions.choice < 1) {
                IERC20(FRAX_3CRV).safeTransfer(msg.sender, balance);
            } else if (actions.choice < 2) {
                IStableSwap(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, msg.sender);
            } else {
                uint256 received = IStableSwap(FRAX_3CRV).remove_liquidity_one_coin(balance, 0, 0, address(this));
                if (!actions.lockSDT) _swapFRAXForSDT(received, actions.minAmountSDT, msg.sender);
                else _swapFRAXForSDT(received, actions.minAmountSDT, address(this));
            }
        }
    }

    /// @notice Internal function for claiming rewards from gauges
    /// @param _gauges List of gauges to claim rewards
    /// @param _actions List of Actions to do with rewards obtained
    function _processGaugesClaim(address[] memory _gauges, Actions memory _actions) internal {
        Actions memory actions = _actions;
        if (
            (actions.locked.length != depositorsCount) || (actions.locked.length != poolsCount)
                || (actions.locked.length != actions.staked.length) || (actions.locked.length != actions.buy.length)
                || (actions.locked.length != actions.minAmount.length)
        ) {
            revert DIFFERENT_LENGTH();
        }
        uint256 length = _gauges.length;
        // Claim rewards token from gauges
        for (uint8 index; index < length;) {
            address gauge = _gauges[index];
            if (blacklisted[gauge]) revert BLACKLISTED_GAUGE();
            ILiquidityGauge(gauge).claim_rewards_for(msg.sender, address(this));

            // skip the first reward token, it is SDT for any LGV4
            uint256 rewardCount = ILiquidityGauge(gauge).reward_count();
            for (uint8 j = 1; j < rewardCount;) {
                address token = ILiquidityGauge(gauge).reward_tokens(j);
                address depositor = depositors[token];
                address pool = pools[token];
                uint256 balance = IERC20(token).balanceOf(address(this));
                if (balance != 0) {
                    // Buy sdTKN from liquidity pool and stake it on gauge or not
                    if (pool != address(0) && actions.buy[poolsIndex[pool]]) {
                        // Don't stake sdTKN on gauge
                        if (!actions.staked[poolsIndex[pool]]) {
                            if (token == BAL) {
                                _swapBALForSDBAL(
                                    pool, balance, actions.minAmount[poolsIndex[pool]], payable(msg.sender)
                                );
                            } else {
                                _swapTKNForSdTKN(pool, balance, actions.minAmount[poolsIndex[pool]], msg.sender);
                            }
                        }
                        // Stake sdTKN on gauge
                        else {
                            uint256 received;
                            if (token == BAL) {
                                received = _swapBALForSDBAL(
                                    pool, balance, actions.minAmount[poolsIndex[pool]], payable(address(this))
                                );
                            } else {
                                received =
                                    _swapTKNForSdTKN(pool, balance, actions.minAmount[poolsIndex[pool]], address(this));
                            }
                            ILiquidityGauge(gauges[tokenSdToken[token]]).deposit(received, msg.sender);
                        }
                    }
                    // Mint sdTKN using depositor and stake it on gauge or not
                    else if (depositor != address(0) && actions.locked[depositorsIndex[depositor]]) {
                        if (token == BAL) {
                            _swapBALForBPT(balance, actions.minAmount[depositorsIndex[depositor]], address(this));
                            balance = IERC20(BPT).balanceOf(address(this));
                            IERC20(BPT).safeApprove(address(depositor), balance);
                        }
                        IDepositor(depositor).deposit(
                            balance, false, actions.staked[depositorsIndex[depositor]], msg.sender
                        );
                    }
                    // Transfer TKN to user
                    else {
                        IERC20(token).safeTransfer(msg.sender, balance);
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
        emit RewardsClaimed(_gauges);
    }

    /// @notice Internal function for locking SDT obtain from previous rewards or to transfert to user
    /// @param lockSDT Boolean for transfering SDT to user or relock them
    function _processSDT(bool lockSDT) internal {
        uint256 amount = IERC20(SDT).balanceOf(address(this));
        if (amount != 0) {
            if (lockSDT) {
                IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
            } else {
                IERC20(SDT).safeTransfer(msg.sender, amount);
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- HELPERS
    ///////////////////////////////////////////////////////////////
    /// @notice Helper for swapping Frax to SDT
    /// @param _amount Amount of Frax to swap
    /// @param _minAmount Minimum amount to receive from swap in SDT
    /// @param _receiver Receiver from the SDT obtained with swap
    function _swapFRAXForSDT(uint256 _amount, uint256 _minAmount, address _receiver) private returns (uint256 output) {
        // swap FRAX for SDT
        output = IZap(CURVE_ZAPPER).exchange(SDT_FXBP, 1, 0, _amount, _minAmount, false, _receiver);
    }

    /// @notice Helper for swapping any Token to sdToken
    /// @param _pool Address of the pool for the swap
    /// @param _amount Amount of Token to swap
    /// @param _minAmount Minimum amount to receive from swap in sdToken
    /// @param _receiver Receiver from the SDT obtained with swap
    function _swapTKNForSdTKN(address _pool, uint256 _amount, uint256 _minAmount, address _receiver)
        private
        returns (uint256 output)
    {
        // swap TKN for sdTKN
        output = IStableSwap(_pool).exchange(0, 1, _amount, _minAmount, _receiver);
    }

    /// @notice Helper for swapping Bal to Bpt
    /// @param amount Amount of Bal to swap
    /// @param minAmount Minimum amount to receive from swap in Bpt
    /// @param receiver Receiver from the SDT obtained with swap
    function _swapBALForBPT(uint256 amount, uint256 minAmount, address receiver) private {
        address[] memory assets = new address[](2);
        assets[0] = BAL;
        assets[1] = WETH;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = amount;
        maxAmountsIn[1] = 0; // 0 WETH

        IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
            assets,
            maxAmountsIn,
            abi.encode(IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, minAmount),
            false
        );
        IBalancerVault(BALANCER_VAULT).joinPool(
            bytes32(0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014), // poolId
            address(this),
            receiver,
            pr
        );
    }

    /// @notice Helper for swapping any Bal to sdBal
    /// @param pool Address of the pool for the swap
    /// @param amount Amount of Bal to swap
    /// @param minAmount Minimum amount to receive from swap in sdBal
    /// @param receiver Receiver from the SDT obtained with swap
    function _swapBALForSDBAL(address pool, uint256 amount, uint256 minAmount, address payable receiver)
        private
        returns (uint256 output)
    {
        _swapBALForBPT(amount, minAmount, address(this));
        amount = IERC20(BPT).balanceOf(address(this));
        minAmount = amount * (BASE_UNIT - slippage) / BASE_UNIT;

        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            IBalancerStablePool(pool).getPoolId(), IBalancerVault.SwapKind.GIVEN_IN, BPT, SD_BAL, amount, "0x"
        );
        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement(address(this), false, receiver, false);
        output = IBalancerVault(BALANCER_VAULT).swap(singleSwap, funds, minAmount, block.timestamp + 600);
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////
    /// @notice Add a new depositor
    /// @param token Token to deposit
    /// @param depositor Address of the depositor
    function addDepositor(address token, address depositor) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (depositor == address(0)) revert ADDRESS_NULL();
        if (depositors[token] != address(0)) revert ALREADY_ADDED();
        depositors[token] = depositor;
        depositorsIndex[depositor] = depositorsCount;
        ++depositorsCount;
        IERC20(token).safeApprove(depositor, type(uint256).max);
        emit DepositorAdded(token, depositor);
    }

    /// @notice Update a previous depositor
    /// @param token Token to deposit
    /// @param newDepositor Address of the newDepositor
    function updateDepositor(address token, address newDepositor) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (newDepositor == address(0)) revert ADDRESS_NULL();
        if (depositors[token] == address(0)) revert NOT_ADDED();
        IERC20(token).safeApprove(depositors[token], 0);
        depositors[token] = newDepositor;
        IERC20(token).safeApprove(newDepositor, type(uint256).max);
        emit DepositorUpdated(token, newDepositor);
    }

    /// @notice Add a new pools for token/sdToken
    /// @param token Token
    /// @param pool Address of the pool
    function addPool(address token, address pool) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (pool == address(0)) revert ADDRESS_NULL();
        if (pools[token] != address(0)) revert ALREADY_ADDED();
        pools[token] = pool;
        poolsIndex[pool] = poolsCount;
        ++poolsCount;
        IERC20(token).safeApprove(pool, type(uint256).max);
        emit PoolAdded(token, pool);
    }

    /// @notice Update a previous pool
    /// @param token Token
    /// @param newPool Address of the newPool
    function updatePool(address token, address newPool) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        if (newPool == address(0)) revert ADDRESS_NULL();
        if (pools[token] == address(0)) revert NOT_ADDED();
        IERC20(token).safeApprove(pools[token], 0);
        pools[token] = newPool;
        IERC20(token).safeApprove(newPool, type(uint256).max);
        emit PoolUpdated(token, newPool);
    }

    /// @notice Add a new gauge for staking sdToken
    /// @param sdToken sdToken
    /// @param gauge Address of the gauge
    function addSdGauge(address sdToken, address gauge) external onlyGovernance {
        if (sdToken == address(0)) revert ADDRESS_NULL();
        if (gauge == address(0)) revert ADDRESS_NULL();
        if (gauges[sdToken] != address(0)) revert ALREADY_ADDED();
        gauges[sdToken] = gauge;
        gaugesIndex[gauge] = gaugesCount;
        ++gaugesCount;
        IERC20(sdToken).safeApprove(gauge, type(uint256).max);
        emit GaugeAdded(sdToken, gauge);
    }

    /// @notice Update a previous gauge
    /// @param sdToken sdToken
    /// @param newGauge Address of the newGauge
    function updateSdGauge(address sdToken, address newGauge) external onlyGovernance {
        if (sdToken == address(0)) revert ADDRESS_NULL();
        if (newGauge == address(0)) revert ADDRESS_NULL();
        if (gauges[sdToken] == address(0)) revert NOT_ADDED();
        IERC20(sdToken).safeApprove(gauges[sdToken], 0);
        gauges[sdToken] = newGauge;
        IERC20(sdToken).safeApprove(newGauge, type(uint256).max);
        emit GaugeUpdated(sdToken, newGauge);
    }

    /// @notice Toggle a gauge to blacklisted
    /// @param gauge address of the gauge to toggle the blacklist
    function toggleBlacklistOnGauge(address gauge) external onlyGovernance {
        if (gauge == address(0)) revert ADDRESS_NULL();
        blacklisted[gauge] = !blacklisted[gauge];
        emit BlacklistGauge(gauge, blacklisted[gauge]);
    }

    /// @notice Update or create a relation between token and sdToken
    /// @param token Address of the token
    /// @param sdToken Address of the sdToken linked to `token`
    function updateTokenSdToken(address token, address sdToken) external onlyGovernance {
        if (token == address(0)) revert ADDRESS_NULL();
        tokenSdToken[token] = sdToken;
    }

    /// @notice Give ownership of the contract to anther address
    /// @param _governance address of the new governance
    function setGovernance(address _governance) external onlyGovernance {
        if (_governance == address(0)) revert ADDRESS_NULL();
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }

    /// @notice Set slippage
    /// @param _slippage new slippage value
    function setSlippage(uint256 _slippage) external onlyGovernance {
        slippage = _slippage;
    }

    /// @notice Set Bribes distributor
    /// @param _multiMerkleStash new address for bribes distributor
    function setMultiMerkleStash(address _multiMerkleStash) external onlyGovernance {
        if (_multiMerkleStash == address(0)) revert ADDRESS_NULL();
        multiMerkleStash = _multiMerkleStash;
    }

    /// @notice Set veSDT rewards distributor
    /// @param _veSDTFeeDistributor new address for veSDT rewards distributor
    function setVeSDTFeeDistributor(address _veSDTFeeDistributor) external onlyGovernance {
        if (_veSDTFeeDistributor == address(0)) revert ADDRESS_NULL();
        veSDTFeeDistributor = _veSDTFeeDistributor;
    }

    /// @notice Rescue ERC20 token stuck on the contract
    /// @param _token address of the token to rescue
    /// @param _amount amount to rescue
    /// @param _recipient address for the rescue token
    function rescueERC20(address _token, uint256 _amount, address _recipient) external onlyGovernance {
        if (_recipient == address(0)) revert ADDRESS_NULL();
        IERC20(_token).safeTransfer(_recipient, _amount);

        emit Recovered(_token, _amount);
    }
}
