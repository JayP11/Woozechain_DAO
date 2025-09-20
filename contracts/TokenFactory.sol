// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";
import "./TimeLock.sol";
import "./GovernanceFactory.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TokenFactory {
    Token[] public tokens;
    TimeLock[] public timelocks;
    GovernanceFactory public immutable governanceFactory;

    constructor(address _governanceFactory) {
        require(_governanceFactory != address(0), "zero governance factory");
        governanceFactory = GovernanceFactory(_governanceFactory);
    }

    event DAOContractsCreated(
        address token,
        address timelock,
        address governor,
        address treasury
    );

    function createToken(
        string memory _name,
        string memory _symbol,
        uint256[] memory _initialSupply,
        address[] memory _tokenAddress,
        bool _daoType
    ) public returns (ERC20Votes) {
        require(
            _tokenAddress.length == _initialSupply.length,
            "holders/supplies length mismatch"
        );

        Token token = new Token(
            _name,
            _symbol,
            _tokenAddress,
            _initialSupply,
            _daoType
        );
        tokens.push(token);
        return ERC20Votes(token);
    }

    function createTimeLock(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executers,
        address _canceller
    ) public returns (TimelockController) {
        TimeLock timelock = new TimeLock(
            _minDelay,
            _proposers,
            _executers,
            _canceller
        );
        timelocks.push(timelock);
        return TimelockController(timelock);
    }

    function getTokenContract(uint256 index) public view returns (address) {
        return address(tokens[index]);
    }

    function getTimeLockContract(uint256 index) public view returns (address) {
        return address(timelocks[index]);
    }

    function callContracts(
        string memory _name,
        string memory _symbol,
        uint256[] memory _initialSupply,
        address[] memory _tokenAddress,
        uint256 _minDelay,
        uint256 _quorum,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        string memory _governor,
        bool _daoType
    ) public returns (address[4] memory) {
        GovernanceFactory _governanceFactory = governanceFactory;
        // GovernanceFactory _governanceFactory = GovernanceFactory(
        //     0x0aEE464EE517DfA77CcC6F2A11C34E400929428C
        // );
        address[4] memory combineAddresses;

        address[] memory proposers = new address[](1);
        proposers[0] = msg.sender;
        ERC20Votes tokenAddress = ERC20Votes(
            createToken(_name, _symbol, _initialSupply, _tokenAddress, _daoType)
        );
        TimelockController timelocker = TimelockController(
            createTimeLock(_minDelay, proposers, proposers, msg.sender)
        );

        address[2] memory _govFatory = _governanceFactory.callContracts(
            address(tokenAddress),
            address(timelocker),
            _quorum,
            _votingDelay,
            _votingPeriod,
            _governor
        );

        //bytes32 ROLE = timelocker.PROPOSER_ROLE();

        //timelocker.grantRole(ROLE, _govFatory[0]) ;
        //timelocker.grantRole(timelocker.EXECUTOR_ROLE(), _govFatory[0]);

        combineAddresses[0] = address(tokenAddress);
        combineAddresses[1] = address(timelocker);
        combineAddresses[2] = _govFatory[0];
        combineAddresses[3] = _govFatory[1];

        emit DAOContractsCreated(
            address(tokenAddress),
            address(timelocker),
            _govFatory[0],
            _govFatory[1]
        );

        return combineAddresses;
    }
}
