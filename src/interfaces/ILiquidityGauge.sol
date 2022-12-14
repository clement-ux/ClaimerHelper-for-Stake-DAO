// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ILiquidityGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    // External

    function set_reward_distributor(address _rewardToken, address _newDistrib) external;

    function initialize(
        address staking_token,
        address admin,
        address SDT,
        address voting_escrow,
        address veBoost_proxy,
        address distributor
    ) external;

    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function claim_rewards_for(address _user, address _recipient) external;

    function deposit(uint256 _value, address _addr) external;

    function balanceOf(address) external returns (uint256);

    function claimable_tokens(address _user) external returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function commit_transfer_ownership(address) external;

    function claim_rewards(address) external;

    function add_reward(address, address) external;

    function set_claimer(address) external;

    // Views

    function admin() external view returns (address);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function working_balances(address _address) external view returns (uint256);

    function reward_tokens(uint256 _i) external view returns (address);

    function reward_data(address _tokenReward) external view returns (Reward memory);

    function reward_count() external view returns (uint256);
}
