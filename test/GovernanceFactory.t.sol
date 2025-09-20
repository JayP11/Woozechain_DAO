// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GovernanceFactory.sol";
import "../contracts/Token.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovernanceFactoryTest is Test {
    GovernanceFactory factory;
    Token token;
    // ERC20Votes tokenVotes;
    TimelockController timelock;

    address admin = makeAddr("admin");
    address proposer = makeAddr("proposer");
    address executor = makeAddr("executor");
    uint256 minDelay = 1 days;

    function setUp() public {
        address[] memory holders = new address[](1);
        holders[0] = admin;
        uint256[] memory supplies = new uint256[](1);
        supplies[0] = 1000000 * 10 ** 18;

        token = new Token("GovToken", "GT", holders, supplies, true);

        address[] memory proposers = new address[](1);
        proposers[0] = proposer;
        address[] memory executors = new address[](1);
        executors[0] = executor;

        timelock = new TimelockController(
            minDelay,
            proposers,
            executors,
            admin
        );

        factory = new GovernanceFactory();
    }

    function testCreateGovernance() public {
        address govAddr = factory.createGovernance(
            token,
            timelock,
            4,
            1,
            10,
            "MyGovernor"
        );
        assertTrue(govAddr != address(0), "Governance address is zero");
        assertEq(
            address(factory.governances(0)),
            govAddr,
            "Governance not stored"
        );
    }

    function testCreateTreasury() public {
        address treasuryAddr = factory.createTreasury(admin, address(timelock));
        assertTrue(treasuryAddr != address(0), "Treasury address is zero");
        assertEq(
            address(factory.treasurys(0)),
            treasuryAddr,
            "Treasury not stored"
        );
    }

    function testGetTreasuryContract() public {
        address treasuryAddr = factory.createTreasury(admin, address(timelock));
        address fetched = factory.getTreasuryContract(0);
        assertEq(fetched, treasuryAddr, "Treasury address mismatch");
    }

    function testCallContracts() public {
        vm.expectEmit(false, false, false, false);
        emit GovernanceFactory.ContractsCreated(address(factory), address(0));

        address[2] memory addrs = factory.callContracts(
            address(token),
            address(timelock),
            4,
            1,
            10,
            "MyGovernor"
        );

        address gov = addrs[0];
        address treas = addrs[1];

        assertEq(address(factory.governances(0)), gov, "Governance not stored");
        assertEq(address(factory.treasurys(0)), treas, "Treasury not stored");

        Treasury treasury = Treasury(payable(treas));
        assertEq(
            treasury.owner(),
            address(timelock),
            "Ownership not transferred"
        );
    }
}
