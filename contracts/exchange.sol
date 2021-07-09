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
    event EthPurchase(address indexed buyer, uint indexed tokensSold, uint indexed ethBought);
    
    function setup(IERC20 _token) external{
        require(address(token) == address(0) && address(factory) == address(0));
        factory = UniswapFactory(msg.sender);
        token = _token;
    }
    
    //Ethereum to Tokens
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
    
    function ethToTokenTransferOutput(uint tokensBought, uint maxEth, uint deadline, address receiver) public payable returns(uint){
        require(receiver != address(this) && receiver != address(0));
        return ethToTokenOutput(tokensBought, maxEth, deadline, receiver);
    }
    
    
    //Tokens to Ethereum
    function tokenToEthInput(uint tokensSold, uint minEth, uint deadline, address receiver)public returns(uint){
        require(tokensSold > 0 && minEth > 0, "UniswapExchange: Invalid Input");
        require(deadline >= block.timestamp, "UniswapExchange: Deadline passed");
        
        uint tokenReserve = token.balanceOf(address(this));
        uint ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
        require(ethBought >= minEth, "UniswapExchange: Not enough Eth bought");
        
        require(token.transferFrom(msg.sender, address(this), tokensSold));
        (bool success,) = receiver.call{value: ethBought}("");
        require(success);
        
        emit EthPurchase(msg.sender, tokensSold, ethBought);
        return ethBought;
    }
    
    function tokenToEthInputSwap(uint tokensSold, uint minEth, uint deadline) public returns(uint){
        return tokenToEthInput(tokensSold, minEth, deadline, msg.sender);
    }
    
    function tokenToEthInputTransfer(uint tokensSold, uint minEth, uint deadline, address receiver) public returns(uint){
        require(receiver != address(this) && receiver != address(0));
        return tokenToEthInput(tokensSold, minEth, deadline, receiver);
    }
    
    function tokenToEthOutput(uint ethBought, uint maxTokens, uint deadline, address receiver) public returns(uint){
        require(ethBought > 0 && maxTokens > 0, "UniswapExchange: Invalid Input");
        require(deadline >= block.timestamp, "UniswapExchange: Deadline passed");
        
        uint tokenReserve = token.balanceOf(address(this));
        uint tokensSold = getOutputPrice(ethBought, address(this).balance, tokenReserve);
        require(tokensSold <= maxTokens, "UniswapExchange: Too much tokens sold");
        
        require(token.transferFrom(msg.sender, address(this), tokensSold));
        (bool success,) = receiver.call{value: ethBought}("");
        require(success);
        
        emit EthPurchase(msg.sender, tokensSold, ethBought);
        return tokensSold;
    }
    
    function tokenToEthOutputSwap(uint ethSold, uint maxTokens, uint deadline) public returns(uint){
        return tokenToEthOutput(ethSold, maxTokens, deadline, msg.sender);
    }
    
    function tokenToEthOutputTransfer(uint ethSold, uint maxTokens, uint deadline, address receiver) public returns(uint){
        require(receiver != address(this) && receiver != address(0));
        return tokenToEthOutput(ethSold, maxTokens, deadline, receiver);
    }
    
    
}