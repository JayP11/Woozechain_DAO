// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../contracts/Token.sol";
import {TimeLock} from "../contracts/TimeLock.sol";
import {Governance} from "../contracts/Governance.sol";
import {Treasury} from "../contracts/Treasury.sol";

contract DeployGovernanceScript is Script {
    // Configuration
    uint256 constant TOTAL_SUPPLY = 1000000e18;
    uint256 constant MIN_DELAY = 1 days;
    uint256 constant VOTING_DELAY = 1;
    uint256 constant VOTING_PERIOD = 5;
    uint256 constant QUORUM_PERCENTAGE = 4;
    
    // Deployed contracts
    Token public token;
    TimeLock public timelock;
    Governance public governor;
    Treasury public treasury;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Set up token distribution - give all tokens to deployer initially
        address[] memory tokenHolders = new address[](1);
        uint256[] memory initialSupplies = new uint256[](1);
        
        tokenHolders[0] = deployer;
        initialSupplies[0] = TOTAL_SUPPLY;

        // 1. Deploy Token
        console.log("Deploying Token...");
        token = new Token(
            "GovernanceToken",
            "GOV",
            tokenHolders,
            initialSupplies,
            true
        );
        console.log("Token deployed at:", address(token));

        // 2. Deploy TimeLock
        console.log("Deploying TimeLock...");
        address[] memory proposers = new address[](0); // Empty initially
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Anyone can execute
        
        timelock = new TimeLock(
            MIN_DELAY,
            proposers,
            executors,
            deployer
        );
        console.log("TimeLock deployed at:", address(timelock));

        // 3. Deploy Governance
        console.log("Deploying Governance...");
        governor = new Governance(
            token,
            timelock,
            QUORUM_PERCENTAGE,
            VOTING_DELAY,
            VOTING_PERIOD,
            "MyGovernor"
        );
        console.log("Governance deployed at:", address(governor));

        // 4. Deploy Treasury
        console.log("Deploying Treasury...");
        treasury = new Treasury{value: 0.1 ether}(deployer); // 0.1 ETH initial funding
        console.log("Treasury deployed at:", address(treasury));

        // 5. Set up roles
        console.log("Setting up roles...");
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        
        // Renounce admin role
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);

        // 6. Delegate voting power
        console.log("Setting up delegation...");
        token.delegate(deployer);

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("Token:", address(token));
        console.log("TimeLock:", address(timelock));
        console.log("Governance:", address(governor));
        console.log("Treasury:", address(treasury));
    }
}
