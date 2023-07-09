// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../lib/erc1363-payable-token/contracts/payment/ERC1363Payable.sol";
import "./LinearBondingCurve.sol";
import "./PoolToken.sol";
import {UD60x18, ud, convert} from "@prb/math/UD60x18.sol";


contract Pool is ERC1363Payable {
    LinearBondingCurve public bondingCurve;
    // The ERC1363 token accepted
    PoolToken private _acceptedToken;

    event Received(address indexed from, uint256 amount);

    constructor(PoolToken acceptedToken_, LinearBondingCurve _bondingCurve)
        ERC1363Payable(acceptedToken_)
    {
        bondingCurve = _bondingCurve;
        _acceptedToken = acceptedToken_;
    }

    function _transferReceived(address , address sender, uint256 amount, bytes memory ) internal override {
        uint256 ethPriceInERC1363Token = bondingCurve.getPrice(acceptedToken().totalSupply());
        uint256 ethToTransfer = ethPriceInERC1363Token * amount;
        (bool sent, ) = address(sender).call{value: ethToTransfer}("");
        require(sent, "Failed to send ETH to sender");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        uint256 ethPriceInERC1363Token = bondingCurve.getPrice(acceptedToken().totalSupply());
        UD60x18 ud60MsgValue = ud(msg.value).div(ud(ethPriceInERC1363Token));
        _acceptedToken.mint(msg.sender, convert(ud60MsgValue));
    }
}
