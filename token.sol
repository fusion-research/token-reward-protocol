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
        //require(lockUntil <= now);
        
        // Substracting the A_spend from client's (_from) balance.
        totalTokens[_from] = totalTokens[_from].sub(A_spend); 
        
        // Add the tokens to the "lockedTokens" array.
        lockedTokens[_from] = lockedTokens[_from].add(A_lock); 
        
        // Calculating the prepaid interest
        uint256 reward = (M.mul(A_lock)).add(A_spend); 
        
        // Adding the interest/reward to the recipient's address.
        totalTokens[_to] = totalTokens[_to].add(reward); 
            
        // Storing the time when the locked tokens may be used by _from again.
        lockingTimes[_from].push(lockUntil);
        lockingAmounts[_from].push(A_lock);
    }
    
    /**
     * @dev Regains the tokens previously locked from the recipient,
     * after the elapse of time period -- 'lockingTime'.
     */
    function unlock(address _client) public {
        // Unlock all tokens that have passed their locking period.
        uint256 i;
        for(i = 0; i < lockingTimes[_client].length; i++){
            if(now > lockingTimes[_client][i]){
                uint256 amt = lockingAmounts[_client][i];
                lockedTokens[_client] = lockedTokens[_client].sub(amt); 
            }
        }
        // Manually deducting locking times and shifting elements. 
        uint256 lastIndex = lockingTimes[_client][i];
        
        for(uint256 x = lastIndex; lastIndex >= 0; x--){
            delete lockingTimes[_client][x];
            
            // shifting the elements in the array
            lockingTimes[_client][x] = lockingTimes[_client][x-1];
        }
    }
    
    /**
     * @dev Get the total amount of tokens (locked + availableTokens).
     */
    function getTotalTokens(address _client) public view returns (uint256) {
        // The total client balance initialized before deploying the contract.
        return totalTokens[_client]; 
    }
    
    /**
     * @dev Get the available tokens to spend after the locked tokens are deducted.
     */
    function getAvailableTokens(address _client) public view returns (uint256) {
        // Calculating the availableTokens owned by a client after deducting the locked tokens.
        uint256 availableTokens = totalTokens[_client].sub(lockedTokens[_client]);
        return availableTokens;
    }
    
    /**
     * @dev Get the specified amount of locked tokens.
     */
    function getLockedTokens(address _client) public view returns (uint256) {
        // Returns the number of locked tokens owned by a client.
        return lockedTokens[_client];
    }
}