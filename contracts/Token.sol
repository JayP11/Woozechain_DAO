// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes {
    bool private _transferable;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory tokenHolders,
        uint256[] memory initialSupplies,
        bool isTransferable
    ) ERC20(name, symbol) ERC20Permit(name) {
        require(
            tokenHolders.length == initialSupplies.length,
            "Token: Arrays length mismatch"
        );

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            _mint(tokenHolders[i], initialSupplies[i]);
        }

        _transferable = isTransferable;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_transferable, "Token is non-transferable");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_transferable, "Token is non-transferable");
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        require(_transferable, "Token is non-transferable");
        return super.approve(spender, amount);
    }

    // function approve(address, uint256) public view override returns (bool) {
    //     return !_transferable;
    // }

    // Required override (solves ERC20Votes logic via _update hook)
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(Nonces, ERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
