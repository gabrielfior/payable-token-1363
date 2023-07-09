// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "forge-std/console.sol";

contract ERC1363Token is ERC1363 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
