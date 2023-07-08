// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

contract LinearBondingCurve {
    uint256 public m;
    uint256 public b;

    constructor(uint256 _m, uint256 _b) {
        m = _m;
        b = _b;
    }

    // ToDo - Fixed point math
    function getPrice(uint256 tokenSupply) external view returns (uint256) {
        // y - m*x + b
        return m * tokenSupply + b;
    }
}
