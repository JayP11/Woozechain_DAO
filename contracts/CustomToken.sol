// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomToken is ERC20, Ownable {

    uint8 decimals_;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals
    ) 
        ERC20(_name, _symbol)
        Ownable(msg.sender) 
    {
        uint256 totalSupply_ = _totalSupply * (10 ** uint256(_decimals));
        _setupDecimals(_decimals);
        _mint(msg.sender, totalSupply_);
    }

    function _setupDecimals(uint8 _decimals) internal {
        decimals_ = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }

    function mintTo(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
