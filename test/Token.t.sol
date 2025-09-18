// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Token.sol";

contract TokenTest is Test {
    Token public token;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    function setUp() public {
        // Test with multiple token holders
        address[] memory tokenHolders = new address[](2);
        uint256[] memory initialSupplies = new uint256[](2);

        tokenHolders[0] = owner;
        tokenHolders[1] = user1;

        initialSupplies[0] = 1000000 * 10 ** 18;
        initialSupplies[1] = 500000 * 10 ** 18;

        token = new Token(
            "TestToken",
            "TT",
            tokenHolders,
            initialSupplies,
            true
        );
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TT");
        assertEq(token.balanceOf(tokenHolders[0]), 1000000 * 10 ** 18);
        assertEq(token.balanceOf(tokenHolders[1]), 500000 * 10 ** 18);
        assertEq(token.totalSupply(), 1500000 * 10 ** 18);
    }

    function testConstructorArrayMismatch() public {
        address[] memory holders = new address[](2);
        uint256[] memory supplies = new uint256[](1);

        vm.expectRevert("Token: Arrays length mismatch");
        new Token("Test", "T", holders, supplies, true);
    }

    /// Transferability tests

    function testTransfer() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        uint256 user1Balance = token.balanceOf(user1);
        uint256 ownerBalance = token.balanceOf(owner);

        vm.prank(owner);
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(user1), user1Balance + transferAmount);
        assertEq(token.balanceOf(owner), ownerBalance - transferAmount);
    }

    function testTransferRevertsWhenNonTransferable() public {
        address[] memory holders = new address[](1);
        uint256[] memory supplies = new uint256[](1);
        holders[0] = owner;
        supplies[0] = 1000 * 10 ** 18;

        Token locked = new Token("Locked", "L", holders, supplies, false);

        vm.prank(owner);
        vm.expectRevert("Token is non-transferable");
        locked.transfer(user1, 1);
    }

    function testTransferFrom() public {
        uint256 allowanceAmount = 2000 * 10 ** 18;

        vm.prank(owner);
        token.approve(user1, allowanceAmount);

        vm.prank(user1);
        token.transferFrom(owner, user2, allowanceAmount);

        assertEq(token.balanceOf(user2), allowanceAmount);
        assertEq(
            token.balanceOf(owner),
            (1000000 * 10 ** 18) - allowanceAmount
        );
    }

    function testTransferFromRevertsWhenNonTransferable() public {
        address[] memory holders = new address[](1);
        uint256[] memory supplies = new uint256[](1);

        holders[0] = owner;
        supplies[0] = 1000 * 10 ** 18;

        Token locked = new Token("Locked", "L", holders, supplies, false);

        vm.prank(owner);
        vm.expectRevert("Token is non-transferable");
        locked.approve(user1, 100);

        vm.prank(user1);
        vm.expectRevert("Token is non-transferable");
        locked.transferFrom(owner, user2, 100);
    }

    function testApproveWhenTransferable() public {
        vm.prank(owner);
        bool success = token.approve(user1, 123 * 10 ** 18);
        assertTrue(success);
    }

    function testApproveUpdatesAllowance() public {
        vm.prank(owner);
        token.approve(user1, 123 * 10 ** 18);
        assertEq(token.allowance(owner, user1), 123 * 10 ** 18);
    }

    function testApproveBehavior() public {
        // Case 1: transferable token (should return true)
        vm.prank(owner);
        bool success1 = token.approve(user1, 123 * 10 ** 18);
        assertTrue(success1);
        assertEq(token.allowance(owner, user1), 123 * 10 ** 18);

        // Case 2: non-transferable token (should return false)
        address[] memory holders = new address[](1);
        uint256[] memory supplies = new uint256[](1);

        holders[0] = owner;
        supplies[0] = 1000 * 10 ** 18;

        Token locked = new Token("Locked", "L", holders, supplies, false);

        vm.prank(owner);
        vm.expectRevert("Token is non-transferable");
        locked.approve(user1, 123);
    }
}
