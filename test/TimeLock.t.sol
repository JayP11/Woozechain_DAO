// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../contracts/TimeLock.sol";

contract TimeLockTest is Test {
    TimeLock public timeLock;
    address public proposer = makeAddr("proposer");
    address public executor = makeAddr("executor");
    address public admin = makeAddr("admin");
    uint256 public MIN_DELAY = 3600;

    function setUp() public {
        address[] memory proposers = new address[](1);
        proposers[0] = proposer;

        address[] memory executors = new address[](1);
        executors[0] = executor;

        timeLock = new TimeLock(MIN_DELAY, proposers, executors, admin);
    }

    /// @dev Check constructor sets the delay correctly
    function testConstructorSetsMinDelay() public {
        assertEq(timeLock.getMinDelay(), MIN_DELAY);
    }

    /// @dev Check role assignments
    function testConstructorAssignsRoles() public {
        // proposer got PROPOSER_ROLE
        assertTrue(timeLock.hasRole(timeLock.PROPOSER_ROLE(), proposer));
        // proposer also got CANCELLER_ROLE
        assertTrue(timeLock.hasRole(timeLock.CANCELLER_ROLE(), proposer));
        // executor got EXECUTOR_ROLE
        assertTrue(timeLock.hasRole(timeLock.EXECUTOR_ROLE(), executor));
        // admin got DEFAULT_ADMIN_ROLE
        assertTrue(timeLock.hasRole(timeLock.DEFAULT_ADMIN_ROLE(), admin));
        // contract itself also has DEFAULT_ADMIN_ROLE
        assertTrue(
            timeLock.hasRole(timeLock.DEFAULT_ADMIN_ROLE(), address(timeLock))
        );
    }
}
