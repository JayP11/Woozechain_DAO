// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/TokenFactory.sol";
import "../contracts/Token.sol";
import "../contracts/TimeLock.sol";
import "../contracts/GovernanceFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory tokenFactory;
    GovernanceFactory govFactory;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        govFactory = new GovernanceFactory();
        tokenFactory = new TokenFactory(address(govFactory));
    }

    function testConstructorZeroAddress() public {
        vm.expectRevert("zero governance factory");
        new TokenFactory(address(0));
    }

    function testCreateTokenArrayMismatch() public {
        uint256[] memory supplies = new uint256[](1);
        address[] memory holders = new address[](2);

        vm.expectRevert("holders/supplies length mismatch");
        tokenFactory.createToken("Test", "T", supplies, holders, true);
    }

    function testCallContractsSuccess() public {
        uint256[] memory supplies = new uint256[](1);
        supplies[0] = 1000 ether;
        address[] memory holders = new address[](1);
        holders[0] = alice;

        address[4] memory contracts = tokenFactory.callContracts(
            "Test Token",
            "TT",
            supplies,
            holders,
            1 days,
            10,
            1,
            50400,
            "Governor",
            true
        );

        // Verify all contracts returned
        assertTrue(contracts[0] != address(0)); // token
        assertTrue(contracts[1] != address(0)); // timelock
        assertTrue(contracts[2] != address(0)); // governor
        assertTrue(contracts[3] != address(0)); // treasury
    }

    function testCallContractsEmitsEvent() public {
        uint256[] memory supplies = new uint256[](1);
        supplies[0] = 1000 ether;
        address[] memory holders = new address[](1);
        holders[0] = alice;

        // Just check that the event is emitted, don't check specific addresses
        vm.expectEmit(false, false, false, false);
        emit TokenFactory.DAOContractsCreated(
            address(0),
            address(0),
            address(0),
            address(0)
        );

        tokenFactory.callContracts(
            "Test",
            "T",
            supplies,
            holders,
            1 days,
            10,
            1,
            50400,
            "Gov",
            true
        );
    }

    function testCreateTimeLock() public {
        address[] memory proposers = new address[](1);
        proposers[0] = alice;
        address[] memory executors = new address[](1);
        executors[0] = bob;

        tokenFactory.createTimeLock(1 days, proposers, executors, alice);

        // Should not revert
        address timelockAddr = tokenFactory.getTimeLockContract(0);
        assertTrue(timelockAddr != address(0));
    }

    function testGettersWork() public {
        uint256[] memory supplies = new uint256[](1);
        supplies[0] = 1000 ether;
        address[] memory holders = new address[](1);
        holders[0] = alice;

        tokenFactory.createToken("Test", "T", supplies, holders, true);
        tokenFactory.createTimeLock(
            1 days,
            new address[](0),
            new address[](0),
            alice
        );

        // Should not revert
        tokenFactory.getTokenContract(0);
        tokenFactory.getTimeLockContract(0);
    }
}
