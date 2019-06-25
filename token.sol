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


/**
 * @title Token
 * @dev A minimal lockable token.
 */
contract Token {
    using SafeMath for uint256;
    
    // A map of client addresses to their total amount of tokens (locked + available)
    mapping (address => uint256) public   totalTokens;
    
    // A map of client addresses to the amout of locked tokens.
    mapping (address => uint256) public   lockedTokens;
    
    // A map of client addresses to times (unix time) when the client locked funds.
    mapping (address => uint256[]) public   lockingTimes;
    
    // A map of client addresses to the amount of tokens locked.
    // These amounts correspond to the times stored in lockingTimes.
    mapping (address => uint256[]) public lockingAmounts;
    
    // Interest multiplier, where locking 1 token produces M new tokens.
    // We expect that M will be significantly lower than 1.
    uint256 public M;
    
    // The duration that tokens will be locked, in milliseconds.
    uint256 public LT;

    /*struct client {
        address   clientAddress;
        uint256[] clientslockedTokens; 
        uint256[] lockedToken_times;
    }
    
    client[] Client;  // A list of clients.*/

    function Token(uint256 _lockTime,  uint256 _m) public {
        LT = _lockTime; // Number of milliseconds. 
        M = _m;
    }
    
    /**
     * @dev Lock the tokens (A_lock) for a specified time period from the recipient's address by an owner,
     * and apply a prepaid interest ('M')
     */
    function lock(address _from, address _to, uint256 A_lock, uint256 A_spend) public {
        // Calculating the lock time for the tokens.
        uint256 lockUntil = now.add(LT); 
        
        while(lockUntil <= now){
            // Substracting the A_spend from client's (from) balance.
            totalTokens[_from] = totalTokens[_from].sub(A_spend); 
        
            // Add the tokens to the "lockedTokens" array.
            lockedTokens[_from] = lockedTokens[_from].add(A_lock); 
        
            // Calculating the prepaid interest
            uint256 reward = (M.mul(A_lock)).add(A_spend); 
        
            // Adding the interest/reward to the recipient's address.
            totalTokens[_to] = totalTokens[_to].add(reward); 
        }
    }
    
    /**
     * @dev Regains the tokens previously locked from the recipient,
     * after the elapse of time period -- 'lockingTime'.
     */
    function unlock(address _client, uint256 A_lock, uint256 A_spend) public {
        // Calculating the lock time for the tokens.
        uint256 lockUntil = now.add(LT);
        
        for(uint256 i = 0; i < lockingAmounts[_client].length; i++){
            if(now > lockUntil){
                totalTokens[_client] = totalTokens[_client].add(A_spend); // Adding the locked tokens back to the client's address.
                lockedTokens[_client] = lockedTokens[_client].sub(A_lock); // Substracting the tokens from the "lockedTokens" array.
            }
        }
    }
    
    /**
     * @dev Get the total amount of tokens (locked + availableTokens).
     */
    function getTotalTokens(address _client) public view returns (uint256) {
        return totalTokens[_client]; // The total client balance initialized before deploying the contract.
    }
    
    /**
     * @dev Get the available tokens to spend after the locked tokens are deducted.
     */
    function getAvailableTokens(address _client) public view returns (uint256) {
        uint256 availableTokens = totalTokens[_client].sub(lockedTokens[_client]);
        return availableTokens;
    }
    
    /**
     * @dev Get the specified amount of locked tokens.
     */
    function getLockedTokens(address _client) public view returns (uint256) {
        return lockedTokens[_client];
    }
}