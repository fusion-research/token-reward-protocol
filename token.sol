pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with necessary safety checks.
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws an error on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: using 'if' is cheaper than asserting 'a' not being zero.
    // See https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
    
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Division of two integers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow if subtracted is greater than the number.
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws an error on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * @title Token
 * @dev 
 */
contract Token {
    using SafeMath for uint256;
    
    mapping (address => uint256) public   totalTokens; // The sum of locked + available tokens owned by the client.
    mapping (address => uint256) public   availableTokens; // Tokens that are not locked and available to use by the client.
    mapping (address => uint256) public   lockedTokens; // Keeping track of the client's locked tokens. 
    
    uint256 public A_lock; // The amount of tokens to lock in a pool.
    uint256 public A_spend; // The amount of tokens the client wishes to spend. 
    uint256 public M; // The reward paid out to the recipient based on a interest multiplier 'M'.
    
    uint256 public lockingTime; // Time period in which the tokens are unspendable.
    

    function Token(address client, uint256 clientBalance, uint256 lockTime,  uint256 m) public {
        totalTokens[client] = clientBalance;                                   
        lockingTime = lockTime;  
        M = m;
    }
    
    /**
     * @dev Lock the tokens (A_lock) for a specified time period from the recipient's address by an owner,
     * and apply a prepaid interest ('M')
     */
    function lock(address _from, address _to, uint256 A_lock, uint256 A_spend) public {
        uint256 lockUntil = now.add(lockingTime); // Calculating the lock time for the tokens.
        
        // restrictions
        require(now <= lockUntil); 
        require(availableTokens[_from] > A_lock + A_spend);
        
        totalTokens[_from] = totalTokens[_from].sub(A_spend); // Substracting the A_spend from client's (from) balance.
        lockedTokens[_from] = lockedTokens[_from].add(A_lock); // Add the tokens to the "lockedTokens" array.
        uint256 reward = (M.mul(A_lock)).add(A_spend); // Calculating the prepaid interest
        totalTokens[_to] = totalTokens[_to].add(reward); // Adding the interest/reward to the recipient's address.
    }
    
    /**
     * @dev Regains the tokens previously locked from the recipient,
     * after the elapse of time period -- 'lockingTime'.
     */
    function unlock(address _from, uint256 A_lock, uint256 A_spend) public {
        uint256 lockUntil = now.add(lockingTime);
        require(now > lockUntil);
        
        totalTokens[_from] = totalTokens[_from].add(A_spend); // Adding the locked tokens back to the client's address.
        lockedTokens[_from] = lockedTokens[_from].sub(A_lock); // Substracting the tokens from the "lockedTokens" array.
    }
    
    /**
     * @dev Get the total amount of tokens (locked + availableTokens).
     */
    function getTotalTokens(address client) public returns (uint256) {
        return totalTokens[client]; // The total client balance initialized before deploying the contract.
    }
    
    /**
     * @dev Get the available tokens to spend after the locked tokens are deducted.
     */
    function getAvailableTokens(address client) public returns (uint256) {
        availableTokens[client] = totalTokens[client].sub(lockedTokens[client]);
        return availableTokens[client];
    }
    
    /**
     * @dev Get the specified amount of locked tokens.
     */
    function getLockedTokens(address client) public returns (uint256) {
        return lockedTokens[client];
    }
}
