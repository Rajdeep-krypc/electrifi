// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract EnergyToken is ERC20Burnable,Ownable {

    address public energyManagementContract;
    constructor() ERC20("EnergyToken", "energy") {}

    modifier onlyEnergyManagement() {
        require(msg.sender == energyManagementContract, "Caller is not EnergyManagement contract");
        _;
    }

    function setEnergyManagementContract(address _energyManagementContract) external onlyOwner {
        energyManagementContract = _energyManagementContract;
    }

    function mint(address to, uint256 amount) public onlyEnergyManagement {
        _mint(to, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}