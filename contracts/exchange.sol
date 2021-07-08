// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UNI.sol";
import "./factory.sol";

contract UniswapExchange is UNI{
    
    UniswapFactory public factory;
    IERC20 token;
    
    //Events
    event TokenPurchase(address indexed buyer, uint indexed ethSold, uint indexed tokensBought);
    
    function setup(IERC20 _token) external{
        require(address(token) == address(0) && address(factory) == address(0));
        factory = UniswapFactory(msg.sender);
        token = _token;
    }
    
    function getInputPrice(uint inputAmount, uint inputReserve, uint outputReserve) public pure returns(uint){
        require(inputAmount > 0 && inputReserve > 0 && outputReserve > 0, "UniswapExchange: Invalid getInputPrice param(s)");
        uint inputAmount_withFee = inputAmount * 997;
        uint numerator = inputAmount_withFee * outputReserve;
        uint denominator = (1000 * inputReserve) + inputAmount_withFee;
        return numerator / denominator;
    }
    
    function getOutputPrice(uint outputAmount, uint outputReserve, uint inputReserve) public pure returns(uint){
        require(outputAmount > 0 && inputReserve > 0 && outputReserve > 0, "UniswapExchange: Invalid getOutputPrice param(s)");
        uint numerator = 1000 * inputReserve * outputAmount;
        uint denominator = 997 * (outputReserve - outputAmount);
        return (numerator / denominator) + 1;
    }
    
    
    function ethToTokenInput(uint ethSold, uint minTokens, uint deadline, address receiver) private returns(uint) {
        require(msg.value >= ethSold && ethSold > 0 && minTokens > 0, "UniswapExchange: Invalid Token Input");
        require(deadline >= block.timestamp, "UniswapExchange: deadline passed");
        
        uint tokenReserve = token.balanceOf(address(this));
        uint tokensBought = getInputPrice(ethSold, address(this).balance-ethSold, tokenReserve);
        require(tokensBought >= minTokens, "UniswapExchange: Not Enough tokens Bought");
        
        require(token.transfer(receiver, tokensBought));
        emit TokenPurchase(msg.sender, ethSold, tokensBought);
        return tokensBought;
    }
    
    function ethToTokenSwapInput(uint ethSold, uint minTokens, uint deadline) public payable returns(uint){
        return ethToTokenInput(ethSold, minTokens, deadline, msg.sender);
    }

    function ethToTokenTransferInput(uint ethSold, uint minTokens, uint deadline, address receiver) public payable returns(uint){
        require(address(this) != receiver && receiver != address(0));
        return ethToTokenInput(ethSold, minTokens, deadline, receiver);
    }
    
    
    function ethToTokenOutput(uint tokensBought, uint maxEth, uint deadline, address receiver) private returns(uint){
        require(tokensBought > 0 && maxEth > 0 && msg.value >= maxEth, "UniswapExchange: Invalid Swap Param");
        require(deadline >= block.timestamp, "UniswapExchange: deadline passed");
        uint tokenReserve = token.balanceOf(address(this));
        uint ethSold = getOutputPrice(tokensBought, tokenReserve, address(this).balance-maxEth);
        
        require(ethSold <= maxEth, "UniswapExchange: Not Enough Eth Sold");

        uint tokenRefund = maxEth - ethSold;
        if (tokenRefund > 0){
            (bool success, ) = msg.sender.call{value: tokenRefund }("");   
            require(success);
        }
        
        require(token.transfer(receiver, tokensBought));
        emit TokenPurchase(msg.sender, ethSold, tokensBought);
        return ethSold;
    }
    
    function ethToTokenSwapOutput(uint tokensBought, uint maxEth, uint deadline) public payable returns(uint){
        return ethToTokenOutput(tokensBought, maxEth, deadline, msg.sender);
    }
}