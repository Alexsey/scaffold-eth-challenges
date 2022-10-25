// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DEX Templatje
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and
 *   🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo.
 *   Also return variable names that may need to be specified exactly may be referenced (if you ar
 *   confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
  /* ========== GLOBAL VARIABLES ========== */

  using Math for uint256;
  using SafeMath for uint256; // outlines use of SafeMath for uint256 variables
  IERC20 token; // instantiates the imported contract

  mapping (address => uint) liquidity;

  /* ========== EVENTS ========== */

  event EthToTokenSwap(address trader, uint ethInput, uint tokenOutput);
  event TokenToEthSwap(address trader, uint tokenInput, uint ethOutput);
  event LiquidityProvided(address lp, uint amountOfEth, uint amountOfTokens);
  event LiquidityRemoved(address lp, uint amountOfEth, uint amountOfTokens);

  constructor(address token_addr) {
    token = IERC20(token_addr);
  }

  function init(uint256 tokens) public payable {
    token.transferFrom(msg.sender, address(this), tokens);
  }

  function price(
      uint256 xInput,
      uint256 xReserves,
      uint256 yReserves
  ) public view returns (uint256 yOutput) {
    return yReserves.mul(xInput.mul(997))
         / xReserves.mul(1000).add(xInput.mul(997));
  }

  function getLiquidity(address lp) public view returns (uint256) {
    return liquidity[lp];
  }

  function ethToToken() public payable returns (uint256 tokenOutput) {
    require(msg.value > 0, "Some ETH is required");

    uint ethInput = msg.value;
    uint ethReserve = address(this).balance.sub(msg.value);
    uint tokenReserve = token.balanceOf(address(this));
    tokenOutput = price(ethInput, ethReserve, tokenReserve);

    bool areTokensSent = token.transfer(msg.sender, tokenOutput);
    require(areTokensSent, "DEX has failed to send tokens");

    emit EthToTokenSwap(msg.sender, msg.value, tokenOutput);
  }

  function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
    require(tokenInput > 0, "Some tokens are required");

    console.log(tokenInput);
    console.log(token.balanceOf(msg.sender));
    uint tokenReserve = token.balanceOf(address(this));
    uint ethReserve = address(this).balance;
    ethOutput = price(tokenInput, tokenReserve, ethReserve);

    bool areTokensObtained = token.transferFrom(msg.sender, address(this), tokenInput);
    require(areTokensObtained, "DEX has failed to obtain tokens");
    (bool isEthSent, ) = msg.sender.call{ value: ethOutput }("");
    require(isEthSent, "DEX has failed to send ETH");

    emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
  }

  function deposit() public payable returns (uint256 tokensDeposit) {
    require(msg.value > 0, "Some ETH is required");

    uint ethDeposit = msg.value;
    uint ethReserve = address(this).balance.sub(ethDeposit);
    uint tokenReserve = token.balanceOf(address(this));
    tokensDeposit = tokenReserve.mul(ethDeposit).div(ethReserve);

    bool areTokensObtained = token.transferFrom(msg.sender, address(this), tokensDeposit);
    require(areTokensObtained, "DEX has failed to obtain tokens");

    liquidity[msg.sender] = liquidity[msg.sender].add(ethDeposit.mul(tokensDeposit).sqrt());

    emit LiquidityProvided(msg.sender, ethDeposit, tokensDeposit);
  }

  function withdraw(uint256 amount) public returns (uint256 ethWithdraw, uint256 tokenWithdraw) {
    require(amount <= liquidity[msg.sender], string(abi.encodePacked(
      "Cannot withdraw ", Strings.toString(amount),
      " - you own only ", Strings.toString(liquidity[msg.sender])
    )));

    uint ethReserve = address(this).balance;
    uint tokenReserve = token.balanceOf(address(this));
    ethWithdraw = amount.mul(ethReserve.sqrt()).div(tokenReserve.sqrt());
    tokenWithdraw = amount.mul(tokenReserve.sqrt()).div(ethReserve.sqrt());

    (bool isEthSent, ) = msg.sender.call{ value: ethWithdraw }("");
    require(isEthSent, "DEX has failed to send ETH");
    bool areTokensSent = token.transfer(msg.sender, tokenWithdraw);
    require(areTokensSent, "DEX has failed to send tokens");

    liquidity[msg.sender] = liquidity[msg.sender].sub(amount);

    emit LiquidityRemoved(msg.sender, ethWithdraw, tokenWithdraw);
  }

  receive () external payable {}
}