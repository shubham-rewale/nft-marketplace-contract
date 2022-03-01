// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20_Token_Sale_Contract is Ownable{

    IERC20 private tokenContract;
    uint private _etherRaised;

    event Bought(uint _amount, address _buyer);
    //event Sold(uint _amount, address _seller);

    constructor(IERC20 _instanceAddress) {
        require(address(_instanceAddress) != address(0), "Ttoken is the zero address");
        tokenContract = _instanceAddress;
    }

    function token() public view returns (IERC20) {
        return tokenContract;
    }

    function buy() public payable {
        uint amount = msg.value;
        uint256 exchangeBalance = tokenContract.balanceOf(address(this));
        require(amount > 0, "You need to send some ether");
        require(amount <= exchangeBalance, "Not enough tokens in the reserve");
        tokenContract.transfer(msg.sender, amount);
        _etherRaised += amount;
        emit Bought(amount, msg.sender);
    }

    receive() external payable {
        buy();
    }

    function getBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function amountOfEtherRaied() public view onlyOwner returns(uint) {
        return _etherRaised;
    }

    function withdrawEther(uint _amount, address payable _receipient) public onlyOwner {
        require(address(this).balance >= _amount, "Not enough balance present");
        require(_receipient != address(0), "Receipient address is zero address");
        _receipient.transfer(_amount);
    }
}