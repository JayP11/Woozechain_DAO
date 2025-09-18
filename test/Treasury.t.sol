// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Treasury.sol";

contract TreasuryTest is Test {
    Treasury public treasury;
    address public owner = makeAddr("owner");
    address public payee = makeAddr("payee");
    address public userX = makeAddr("userX");
    uint256 constant DEPLOY_AMOUNT = 1 ether;

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        treasury = new Treasury{value: DEPLOY_AMOUNT}(payee);
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(treasury.totalFunds(), DEPLOY_AMOUNT);
        assertEq(treasury.payee(), payee);
        assertEq(treasury.isReleased(), false);
        assertEq(treasury.owner(), owner);
    }

    function testReleaseFundsToNonOwner() public {
        vm.prank(userX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                userX
            )
        );
        treasury.releaseFunds();
    }

    function testReleaseFunds() public {
        uint256 initialPayeeBalance = address(payee).balance;
        vm.startPrank(owner);
        treasury.releaseFunds();
        assertEq(treasury.isReleased(), true);
        assertEq(payee.balance, initialPayeeBalance + DEPLOY_AMOUNT);

        vm.expectRevert("Funds already released");
        treasury.releaseFunds();
        vm.stopPrank();
    }

    /// @notice Test fund release with zero address payee
    function testReleaseFundsToZeroAddress() public {
        vm.startPrank(owner);

        vm.expectRevert("Payee cannot be zero address");
        new Treasury{value: DEPLOY_AMOUNT}(address(0));

        vm.stopPrank();
    }

    /// @notice Fuzz test for different deployment amounts
    function testFuzzDeploymentAmount(uint256 amount) public {
        vm.assume(amount <= 100 ether); // Reasonable upper bound
        vm.deal(owner, amount);

        vm.startPrank(owner);
        Treasury fuzzTreasury = new Treasury{value: amount}(payee);
        assertEq(fuzzTreasury.totalFunds(), amount);
        assertEq(fuzzTreasury.payee(), payee);
        assertEq(fuzzTreasury.isReleased(), false);
        vm.stopPrank();
    }
}
