// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IMetapool {
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver)
        external
        returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy, address _receiver)
        external
        payable
        returns (uint256);

    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}
