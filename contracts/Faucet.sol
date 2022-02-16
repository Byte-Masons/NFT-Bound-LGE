pragma solidity ^0.8.10;

contract Faucet {

  address admin;

  constructor() {
    admin = msg.sender;
  }

  mapping(address => bool) private permitted;

  function send(address addr, uint amount) external returns (bool) {
    require(permitted[msg.sender] || msg.sender == admin, "epic fail");
    payable(addr).transfer(amount);
    return true;
  }

  function permit(address addr) external returns (bool) {
    require(msg.sender == admin, "fail");
    permitted[addr] = true;
    return true;
  }

  function rug() external payable returns (uint) {
    uint amt = msg.value;
    return amt;
  }

}
