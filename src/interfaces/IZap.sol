// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IZap {
    function add_liquidity(address _pool, uint256[3] memory _deposit_amounts, uint256 _min_mint_amount)
        external
        payable;
    function get_dy(address _pool, uint256 i, uint256 j, uint256 _dx)
        external
        view
        returns(uint256);
    function exchange(address _pool, uint256 i, uint256 j, uint256 _dx, uint256 _dy, bool use_eth, address _receiver)
        external
        payable
        returns(uint256);
}
