// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20_Token_Contract is ERC20 {
    constructor(uint256 _initialSupply) ERC20("Rupee", "Rs") {
        _mint(msg.sender, _initialSupply);
    }
}