// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IPoolSDTFXPB {
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver)
        external
        returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy, bool user_eth, address _receiver)
        external
        payable
        returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 _dx) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}
