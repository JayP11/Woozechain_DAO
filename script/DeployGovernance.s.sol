// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../contracts/Token.sol";
import {TimeLock} from "../contracts/TimeLock.sol";
import {Governance} from "../contracts/Governance.sol";
import {Treasury} from "../contracts/Treasury.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";
import {GovernanceFactory} from "../contracts/GovernanceFactory.sol";

contract DeployGovernanceScript is Script {
    uint256 constant TOTAL_SUPPLY = 1000000e18;
    uint256 constant MIN_DELAY = 1 days;
    uint256 constant VOTING_DELAY = 1;
    uint256 constant VOTING_PERIOD = 5;
    uint256 constant QUORUM_PERCENTAGE = 4;

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

        address[] memory tokenHolders = new address[](1);
        uint256[] memory initialSupplies = new uint256[](1);

        tokenHolders[0] = deployer;
        initialSupplies[0] = TOTAL_SUPPLY;

        // 1. Deploy GovernanceFactory first
        console.log("Deploying GovernanceFactory...");
        GovernanceFactory governanceFactory = new GovernanceFactory();
        console.log(
            "GovernanceFactory deployed at:",
            address(governanceFactory)
        );

        // 2. Deploy TokenFactory with GovernanceFactory address
        console.log("Deploying TokenFactory...");
        TokenFactory tokenFactory = new TokenFactory(
            address(governanceFactory)
        );
        console.log("TokenFactory deployed at:", address(tokenFactory));

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("TokenFactory:", address(tokenFactory));
        console.log("GovernanceFactory:", address(governanceFactory));
        console.log("=========================");
    }
}
