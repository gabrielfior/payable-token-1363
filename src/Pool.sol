// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../lib/erc1363-payable-token/contracts/payment/ERC1363Payable.sol";
import "./LinearBondingCurve.sol";
import "./ERC1363Token.sol";
import "forge-std/console.sol";
import {UD60x18, ud, convert} from "@prb/math/UD60x18.sol";

/*
- ERC1363: Token sale/buy contract with a linear bonding curve:
Token should use ERC1363
- When a user sends ETH to the contract with ERC1363 it should trigger the receive function and mint the correct amount of tokens
- When a user sends the token back to the contract it should return the correct amount of eth


*/

contract Pool is ERC1363Payable {
    LinearBondingCurve public bondingCurve;

    event Received(address indexed from, uint256 amount);

    constructor(ERC1363Token _acceptedToken, LinearBondingCurve _bondingCurve) ERC1363Payable(_acceptedToken) {
        bondingCurve = _bondingCurve;
    }

    function _transferReceived(address operator, address sender, uint256 amount, bytes memory data) internal override {
        // Todo - Fixed point math
        // ToDo - totalSupply is affected by other calls from LP tokens, hence pool must be owner.
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
        //acceptedToken().mint(msg.sender, tokensToTransfer);
        //acceptedToken().dummy();
    }
}
