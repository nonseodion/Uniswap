//SPDX
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UNI is ERC20{
    constructor() ERC20("UNIToken", "UNI"){}
}