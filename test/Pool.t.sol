// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "forge-std/Test.sol";
import "../src/Pool.sol";
import "../src/LinearBondingCurve.sol";
import "../lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "../src/ERC1363Token.sol";
//import "forge-std/console.sol";

contract ContractBTest is Test {
    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);
    event Received(address indexed from, uint256 amount);

    ERC1363Token public erc1363token;
    Pool public pool;
    LinearBondingCurve public bondingCurve;
    address alice = address(1);
    address bob = address(2);

    function setUp() public {
        vm.prank(alice);
        erc1363token = new ERC1363Token("a","b");
        console.log("balance sender", erc1363token.balanceOf(alice));
        bondingCurve = new LinearBondingCurve(1,0);
        pool = new Pool(erc1363token, bondingCurve, erc1363token);
        // Init Pool's balance of 100 LP tokens, instead of minting
    }

    function testSendEther_triggersReceive() public {
        uint256 amountInWei = 0.01 ether;
        // increase supply of erc1363token
        uint256 totalSupply = 10;
        deal(address(erc1363token), address(3), totalSupply, true);
        hoax(alice, amountInWei);
        vm.expectEmit(true, true, false, true);
        emit Received(alice, amountInWei);
        address(pool).call{value: amountInWei}("");

        // ToDo - Assert tokens were received
        uint256 expectedBalance = amountInWei / totalSupply;
        // ToDo - Get amount from price
        assertEq(erc1363token.balanceOf(alice), expectedBalance);
    }

    function testSendERC1363_eventEmitted() public {
        uint256 erc1363TokensForBob = 10;
        vm.deal(address(pool), 1 ether);
        deal(address(erc1363token), bob, erc1363TokensForBob, true);
        console.log("total supply", erc1363token.totalSupply());
        console.log("balance1", erc1363token.balanceOf(bob));

        vm.startPrank(bob);
        erc1363token.approve(address(pool), erc1363TokensForBob);

        vm.expectEmit(true, true, false, true);
        emit TokensReceived(bob, bob, erc1363TokensForBob, "");
        erc1363token.transferAndCall(address(pool), erc1363TokensForBob);

        // We should get ETH back
        uint256 expectedEthReturned = erc1363TokensForBob * erc1363token.totalSupply();
        assertEq(bob.balance, expectedEthReturned);

        vm.stopPrank();
    }
}
