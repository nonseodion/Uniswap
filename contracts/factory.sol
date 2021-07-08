// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract UniswapFactory {
    mapping(address => address) private exchanges;
    
    function getExchange(address token) external view returns(address){
        return exchanges[token];
    }
}