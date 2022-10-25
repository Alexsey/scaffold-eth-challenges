pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Balloons is ERC20 {
  event Approved(address owner, address spender, uint amountOfTokens);

  constructor() ERC20("Balloons", "BAL") {
    _mint(msg.sender, 1000 ether); // mints 1000 balloons!
  }

  function approve (address spender, uint amount) public virtual override returns (bool) {
    emit Approved(msg.sender, spender, amount);
    return super.approve(spender, amount);
  }
}
