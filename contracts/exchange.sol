//SPDX 
pragma solidity 0.8.0;

import "./UNI.sol";

contract UniswapExchange is UNI{
    function setup() external{
        
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
}