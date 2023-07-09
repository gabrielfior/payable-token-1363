// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "forge-std/Test.sol";
import "../src/Pool.sol";
import "../src/LinearBondingCurve.sol";
import "../lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "../src/PoolToken.sol";

contract PoolTest is Test {
    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);
    event Received(address indexed from, uint256 amount);

    PoolToken public poolToken;
    Pool public pool;
    LinearBondingCurve public bondingCurve;

    // users - also see utils.createUsers(2)
    address alice = address(1);
    address bob = address(2);

    // Bonding curve
    uint256 m = 2;
    uint256 b = 0;

    function setUp() public {
        vm.startPrank(alice);
        poolToken = new PoolToken("name","symbol");
        bondingCurve = new LinearBondingCurve(m,b);
        pool = new Pool(poolToken, bondingCurve);
        poolToken.transferOwnership(address(pool));
        vm.stopPrank();
    }

    function testSendEther_triggersReceive() public {
        uint256 amountInWei = 0.01 ether;
        // Increase supply of poolToken by sending it to random address, so that we have a tokenPrice > 0 in linearBondingCurve
        // We could also have the pool mint it to a diff user, but we wanted to test only the receive function.
        uint256 totalSupply = 10;
        deal(address(poolToken), address(3), totalSupply, true);
        hoax(alice, amountInWei);
        vm.expectEmit(true, true, false, true);
        emit Received(alice, amountInWei);
        (bool sent, ) = address(pool).call{value: amountInWei}("");
        require(sent, "Failed to send Ether");
        
        uint256 expectedBalance = amountInWei / (totalSupply * m);
        assertEq(poolToken.balanceOf(alice), expectedBalance);
    }

    function testSendERC1363_eventEmitted() public {
        uint256 poolTokensForBob = 10;
        // initial balance for pool to be able to transfer ETH back to users
        deal(address(pool), 1 ether);
        deal(address(poolToken), bob, poolTokensForBob, true);

        vm.startPrank(bob);
        poolToken.approve(address(pool), poolTokensForBob);

        vm.expectEmit(true, true, false, true);
        emit TokensReceived(bob, bob, poolTokensForBob, "");
        poolToken.transferAndCall(address(pool), poolTokensForBob);

        uint256 expectedEthReturned = poolTokensForBob * poolToken.totalSupply() * m;
        assertEq(bob.balance, expectedEthReturned);

        vm.stopPrank();
    }
}
