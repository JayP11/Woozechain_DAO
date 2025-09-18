// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/TokenFactory.sol";
import "../contracts/Token.sol";
import "../contracts/TimeLock.sol";
import "../contracts/GovernanceFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory factory;
    GovernanceFactory govFactory;
    address user1 = makeAddr("user1");

    function setUp() public {
        factory = new TokenFactory();
        govFactory = new GovernanceFactory();

        // Mock the hardcoded address in TokenFactory
        vm.etch(
            0x0aEE464EE517DfA77CcC6F2A11C34E400929428C,
            address(govFactory).code
        );
    }

    function testCreateToken() public {
        uint256[] memory supply = new uint256[](1);
        supply[0] = 1000e18;
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        ERC20Votes token = factory.createToken(
            "Test",
            "TST",
            supply,
            recipients,
            true
        );

        assertEq(Token(address(token)).name(), "Test");
        assertEq(Token(address(token)).symbol(), "TST");
        assertEq(token.totalSupply(), 1000e18);
        assertEq(token.balanceOf(user1), 1000e18);
        assertEq(factory.getTokenContract(0), address(token));
    }

    function testCreateTimeLock() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        TimelockController timelock = factory.createTimeLock(
            1 days,
            users,
            users,
            user1
        );

        assertEq(timelock.getMinDelay(), 1 days);
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), user1));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), user1));
        assertEq(factory.getTimeLockContract(0), address(timelock));
    }

    function testCallContracts() public {
        uint256[] memory supply = new uint256[](1);
        supply[0] = 1000e18;
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        // First call to get the contract addresses
        address[4] memory contracts = factory.callContracts(
            "DAO",
            "DAO",
            supply,
            recipients,
            1 days,
            4,
            1,
            50400,
            "Governor",
            true
        );

        // Set up the event expectation for the second call
        vm.expectEmit(true, true, true, true);
        emit TokenFactory.DAOContractsCreated(
            contracts[0], // token
            contracts[1], // timelock
            contracts[2], // governor
            contracts[3] // treasury
        );

        // Second call to emit the event
        address[4] memory contracts2 = factory.callContracts(
            "DAO",
            "DAO",
            supply,
            recipients,
            1 days,
            4,
            1,
            50400,
            "Governor",
            true
        );

        // Verify token properties for the first call
        Token token = Token(contracts[0]);
        assertEq(token.name(), "DAO");
        assertEq(token.totalSupply(), 1000e18);

        // Verify non-zero addresses for the first call
        assertTrue(contracts[0] != address(0), "Token address is zero");
        assertTrue(contracts[1] != address(0), "Timelock address is zero");
        assertTrue(contracts[2] != address(0), "Governor address is zero");
        assertTrue(contracts[3] != address(0), "Treasury address is zero");

        // Optionally, verify the second call's addresses are different
        assertTrue(
            contracts[0] != contracts2[0],
            "Token addresses should differ"
        );
    }

    function testMultipleTokenCreation() public {
        uint256[] memory supply = new uint256[](1);
        supply[0] = 500e18;
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        factory.createToken("Token1", "TK1", supply, recipients, true);
        factory.createToken("Token2", "TK2", supply, recipients, false);

        assertEq(Token(factory.getTokenContract(0)).name(), "Token1");
        assertEq(Token(factory.getTokenContract(1)).name(), "Token2");
    }
}
