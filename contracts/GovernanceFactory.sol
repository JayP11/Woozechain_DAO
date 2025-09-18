// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./Governance.sol";
import "./Treasury.sol";
import "./TimeLock.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernanceFactory {
    Governance[] public governances;
    Treasury[] public treasurys;

    event ContractsCreated(
        address indexed governance,
        address indexed treasury
    );

    function createGovernance(
        ERC20Votes _tokenAddress,
        TimelockController _timeLockAddress,
        uint256 _quorum,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        string memory _governor
    ) public returns (address) {
        Governance governance = new Governance(
            _tokenAddress,
            _timeLockAddress,
            _quorum,
            _votingDelay,
            _votingPeriod,
            _governor
        );
        governances.push(governance);
        return address(governance);
    }

    function createTreasury(
        address _payee,
        address timelocker
    ) public returns (address) {
        Treasury treasury = new Treasury(_payee);
        treasurys.push(treasury);
        treasury.transferOwnership(timelocker);

        return address(treasury);
    }

    function getTreasuryContract(uint256 index) public view returns (address) {
        return address(treasurys[index]);
    }

    function callContracts(
        address tokenContractAddress,
        address timelocker,
        uint256 _quorum,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        string memory _governor
    ) external returns (address[2] memory) {
        address[2] memory addresses;

        //TimeLock _timeLock = TimeLock(payable(timelocker));

        address governance = createGovernance(
            ERC20Votes(tokenContractAddress),
            TimelockController(payable(timelocker)),
            _quorum,
            _votingDelay,
            _votingPeriod,
            _governor
        );
        address treasury = createTreasury(msg.sender, timelocker);

        //_timeLock.grantRole(_timeLock.PROPOSER_ROLE(), governance);
        // _timeLock.grantRole(_timeLock.EXECUTOR_ROLE(), governance);

        addresses[0] = governance;
        addresses[1] = treasury;

        emit ContractsCreated(governance, treasury);
        return addresses;
    }
}
