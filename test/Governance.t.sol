// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../contracts/Governance.sol"; // adjust path if different
import "../contracts/Token.sol";

contract GovernanceTest is Test {
    Token token;
    TimelockController timelock;
    Governance governor;

    address proposer = address(0x1);
    address voter1 = address(0x2);
    address voter2 = address(0x3);

    uint256 constant TOTAL_SUPPLY = 1000000e18;
    uint256 constant MIN_DELAY = 1 days;
    uint256 constant VOTING_DELAY = 1;
    uint256 constant VOTING_PERIOD = 5;
    uint256 constant QUORUM_PERCENTAGE = 4;

    function setUp() public {
        // Token
        address[] memory tokenHolders = new address[](3);
        uint256[] memory initialSupplies = new uint256[](3);
        tokenHolders[0] = proposer;
        tokenHolders[1] = voter1;
        tokenHolders[2] = voter2;
        initialSupplies[0] = (TOTAL_SUPPLY * 50) / 100;
        initialSupplies[1] = (TOTAL_SUPPLY * 30) / 100;
        initialSupplies[2] = (TOTAL_SUPPLY * 20) / 100;

        token = new Token(
            "GovToken",
            "GT",
            tokenHolders,
            initialSupplies,
            true
        );

        // TimeLock - Fixed: Don't give proposer individual proposer role
        address[] memory proposers = new address[](0); // Empty array initially
        address[] memory executors = new address[](1);
        executors[0] = address(0); // anyone can execute
        timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            address(this)
        );

        // Governance
        governor = new Governance(
            token,
            timelock,
            QUORUM_PERCENTAGE,
            VOTING_DELAY,
            VOTING_PERIOD,
            "MyGovernor"
        );

        // Give governance contract the proposer role in timelock
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor)); // Add canceller role
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0)); // Anyone can execute

        // Renounce admin role
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));

        // Delegation
        vm.prank(proposer);
        token.delegate(proposer);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.roll(block.number + 1);
    }

    function testTokenSetup() public {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.balanceOf(proposer), (TOTAL_SUPPLY * 50) / 100);
        assertEq(token.balanceOf(voter1), (TOTAL_SUPPLY * 30) / 100);
        assertEq(token.balanceOf(voter2), (TOTAL_SUPPLY * 20) / 100);

        // Check voting power
        assertEq(token.getVotes(proposer), (TOTAL_SUPPLY * 50) / 100);
        assertEq(token.getVotes(voter1), (TOTAL_SUPPLY * 30) / 100);
        assertEq(token.getVotes(voter2), (TOTAL_SUPPLY * 20) / 100);
    }

    function testGovernanceConfiguration() public {
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.name(), "MyGovernor");
        assertEq(address(governor.token()), address(token));

        // Test quorum calculation
        uint256 expectedQuorum = (TOTAL_SUPPLY * QUORUM_PERCENTAGE) / 100;
        assertEq(governor.quorum(block.number - 1), expectedQuorum);
    }

    function testSupportsInterface() public {
        assertTrue(governor.supportsInterface(type(IGovernor).interfaceId));
    }

    function testCreateProposal() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            voter1,
            1000e18
        );

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Transfer tokens to voter1"
        );

        // Should be in Pending state initially
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Pending)
        );

        // After voting delay, should be Active
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Active)
        );
    }

    function testSuccessfulProposal() public {
        // First, proposer approves timelock to spend tokens on their behalf
        vm.prank(proposer);
        token.approve(address(timelock), 1000e18);

        // Create proposal to transfer tokens from proposer to voter1
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            proposer,
            voter1,
            1000e18
        );

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Transfer tokens from proposer to voter1"
        );

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote - proposer (50%) and voter1 (30%) vote yes = 80% > quorum
        vm.prank(proposer);
        governor.castVote(proposalId, 1); // For

        vm.prank(voter1);
        governor.castVote(proposalId, 1); // For

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Succeeded)
        );

        // Queue the proposal
        bytes32 descriptionHash = keccak256(
            bytes("Transfer tokens from proposer to voter1")
        );
        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Queued)
        );

        // Move past timelock delay
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute the proposal
        uint256 voter1BalanceBefore = token.balanceOf(voter1);
        uint256 proposerBalanceBefore = token.balanceOf(proposer);

        governor.execute(targets, values, calldatas, descriptionHash);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Executed)
        );

        // Verify the execution worked
        assertEq(token.balanceOf(voter1), voter1BalanceBefore + 1000e18);
        assertEq(token.balanceOf(proposer), proposerBalanceBefore - 1000e18);
    }

    function testDefectedProposal() public {
        // Create proposal to change timelock's min delay (this won't actually work without proper setup, but good for testing)
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(timelock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("updateDelay(uint256)", 2 days);

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Update timelock delay"
        );

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote against - voter1 (30%) and voter2 (20%) vote against = 50%
        // proposer (50%) votes for, but against votes win
        vm.prank(voter1);
        governor.castVote(proposalId, 0); // Against

        vm.prank(voter2);
        governor.castVote(proposalId, 0); // Against

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Defeated)
        );
    }

    // Add a simple test that demonstrates treasury functionality
    function testTreasuryProposal() public {
        // Send some ETH to timelock (simulating treasury)
        vm.deal(address(timelock), 10 ether);

        // Create proposal to send ETH from treasury to voter2
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = voter2;
        values[0] = 1 ether;
        calldatas[0] = "";

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Send 1 ETH to voter2"
        );

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote
        vm.prank(proposer);
        governor.castVote(proposalId, 1); // For

        vm.prank(voter1);
        governor.castVote(proposalId, 1); // For

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Succeeded)
        );

        // Queue the proposal
        bytes32 descriptionHash = keccak256(bytes("Send 1 ETH to voter2"));
        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Queued)
        );

        // Move past timelock delay
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute the proposal
        uint256 voter2BalanceBefore = voter2.balance;
        governor.execute(targets, values, calldatas, descriptionHash);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Executed)
        );

        // Verify the execution worked
        assertEq(voter2.balance, voter2BalanceBefore + 1 ether);
    }

    function testQuorumMetWithLowParticipation() public {
        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            voter1,
            1000e18
        );

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Transfer tokens"
        );

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);

        // Only voter2 (20%) votes - above quorum (4%) but check if it passes
        vm.prank(voter2);
        governor.castVote(proposalId, 1); // For

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Succeeded)
        );
    }

    function testCancelProposal() public {
        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            voter1,
            1000e18
        );

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Transfer tokens"
        );

        // Cancel the proposal
        bytes32 descriptionHash = keccak256(bytes("Transfer tokens"));
        vm.prank(proposer);
        governor.cancel(targets, values, calldatas, descriptionHash);

        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Canceled)
        );
    }

    function testGetVotes() public {
        uint256 proposerVotes = governor.getVotes(proposer, block.number - 1);
        uint256 voter1Votes = governor.getVotes(voter1, block.number - 1);
        uint256 voter2Votes = governor.getVotes(voter2, block.number - 1);

        assertEq(proposerVotes, (TOTAL_SUPPLY * 50) / 100);
        assertEq(voter1Votes, (TOTAL_SUPPLY * 30) / 100);
        assertEq(voter2Votes, (TOTAL_SUPPLY * 20) / 100);
    }

    function testProposalNeedsQueuing() public {
        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            voter1,
            1000e18
        );

        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Transfer tokens"
        );

        assertTrue(governor.proposalNeedsQueuing(proposalId));
    }

    function test_CreateProposalWithoutVotingPower() public {
        address noVotingPower = address(0x999);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            voter1,
            1000e18
        );

        vm.prank(noVotingPower);
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal by user with no voting power"
        );

        // The proposal should be created but will likely fail due to no votes
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Pending)
        );

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Active)
        );

        // Move past voting period without any votes
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Should be defeated due to no votes (doesn't meet quorum)
        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Defeated)
        );
    }
}
