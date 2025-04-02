// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IPancakeFactory {
    function createPair (address tokenA, address tokenB) external returns (address pair);
}

contract MEGAToken {
    string public name = "MEGA Token BSC";
    string public symbol = "MEGA";
    uint public totalSupply;
    uint public decimals = 10;
    address public owner;
    address public pair;
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    mapping(address => uint) public  balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public isExcludedFromTax;

    uint public buyTax = 4;
    uint public sellTax = 4;
    address public taxWallet;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event OwnershipRenounced(address indexed previousOwner);

    constructor(uint _initialSupply, address _taxWallet, uint _decimals) {
        owner = msg.sender;
        taxWallet = _taxWallet;
        totalSupply = _initialSupply * (10 ** uint(_decimals));
        balanceOf[msg.sender] = totalSupply;

        IPancakeRouter router = IPancakeRouter(routerAddress);
        pair = IPancakeFactory(router.factory()).createPair(address(this), router.WETH());

        isExcludedFromTax[owner] = true;
        isExcludedFromTax[taxWallet] = true;
    }
    modifier onlyOwner() {
        require (msg.sender == owner, " Not owner");
        _;
    }

    function transfer (address _to, uint _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient Balance");
        uint taxAmount = 0;

        if (!isExcludedFromTax[msg.sender] && !isExcludedFromTax[_to]) {
            if (_to == pair)
            {
                taxAmount = (_amount * sellTax) / 100;
            } else if (msg.sender == pair)
            {
                taxAmount = (_amount * buyTax) / 100;
            }
             }
  
        uint finalAmount = _amount - taxAmount; 
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += taxAmount;

    if (taxAmount > 0) {
        balanceOf[taxWallet] += taxAmount;
        emit Transfer(msg.sender, taxWallet, taxAmount);
        return true;
    }
        }
   

    function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
        require(balanceOf[_from]>= _amount, "Insufficient Balance");
        require(allowance[_from] [msg.sender] >= _amount, "Allowance Eceeded");

        uint taxAmount = 0;
        if (!isExcludedFromTax[_from] && !isExcludedFromTax[_to]) {
            if (_to == pair) {
                taxAmount = (_amount * sellTax) / 100;
         } else if (_from == pair) {
            taxAmount = (_amount * buyTax) / 100;
         }
        }
        uint finalAmount = _amount - taxAmount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += finalAmount;
        allowance[_from] [msg.sender] -= _amount;
        emit Transfer (_from, taxWallet, taxAmount);
    
        emit Transfer(_from, _to, finalAmount);
        return true;
    }
       
        function burn(uint _amount) public onlyOwner {
        require(balanceOf[msg.sender] >= _amount, "Insufficient Balance");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address (0), _amount);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced (owner);
        owner = address (0);
    }
}

