// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../lib/erc1363-payable-token/contracts/payment/ERC1363Payable.sol";
import "./LinearBondingCurve.sol";
import "./ERC1363Token.sol";
import "forge-std/console.sol";
import {UD60x18, ud, convert} from "@prb/math/UD60x18.sol";


// ToDo - Inherit from ERC20, mint
contract Pool is ERC1363Payable {
    LinearBondingCurve public bondingCurve;
    ERC1363Token private tokenToMint;

    event Received(address indexed from, uint256 amount);

    constructor(IERC1363 _acceptedToken, LinearBondingCurve _bondingCurve, ERC1363Token tokenToMint_)
        ERC1363Payable(_acceptedToken)
    {
        bondingCurve = _bondingCurve;
        tokenToMint = tokenToMint_;
    }

    function _transferReceived(address operator, address sender, uint256 amount, bytes memory data) internal override {
        uint256 ethPriceInERC1363Token = bondingCurve.getPrice(acceptedToken().totalSupply());
        uint256 ethToTransfer = ethPriceInERC1363Token * amount;
        (bool sent, bytes memory data) = address(sender).call{value: ethToTransfer}("");
        require(sent, "Failed to send ETH to sender");
    }

    receive() external payable {
        console.log("entered receive");
        emit Received(msg.sender, msg.value);
        // ToDo - Mint tokens to user
        uint256 ethPriceInERC1363Token = bondingCurve.getPrice(acceptedToken().totalSupply());
        console.log("ethPriceInERC1363Token", ethPriceInERC1363Token);
        console.log("msg.value", msg.value);
        UD60x18 ud60MsgValue = ud(msg.value).div(ud(ethPriceInERC1363Token));
        uint256 tokensToTransfer = convert(ud60MsgValue);
        console.log("tokensToTransfer", tokensToTransfer);
        // ToDo - mint tokens to address
        tokenToMint.mint(msg.sender, tokensToTransfer);
    }
}
