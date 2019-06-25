pragma solidity ^0.4.21;

contract queue
{
    struct Queue {
        uint[] data;
        uint front;
        uint back;
    }
    /// @dev the number of elements stored in the queue.
    function length(Queue storage q) constant internal returns (uint) {
        return q.back - q.front;
    }
    /// @dev the number of elements this queue can hold
    function capacity(Queue storage q) constant internal returns (uint) {
        return q.data.length - 1;
    }
    /// @dev push a new element to the back of the queue
    function push(Queue storage q, uint data) internal
    {
        if ((q.back + 1) % q.data.length == q.front)
            return; // throw;
        q.data[q.back] = data;
        q.back = (q.back + 1) % q.data.length;
    }
    /// @dev remove and return the element at the front of the queue
    function pop(Queue storage q) internal returns (uint r)
    {
        if (q.back == q.front)
            return; // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }
}


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
 * @dev A minimal lockable token.
 */
contract Token is queue {
    using SafeMath for uint256;
    
    mapping (address => uint256) public   totalTokens; // The sum of locked + available tokens owned by the client.
    mapping (address => uint256) public   lockedTokens; // Keeping track of the client's locked tokens. 
    mapping (address => uint256) public   lockingTimes; 
    uint256 public M; // The reward paid out to the recipient based on a interest multiplier 'M'.

    struct client {
        address clientAddress;
        uint256 clientslockedTokens; 
        uint256 lockingTime;  // Time period in which the tokens are unspendable.
    }


    function Token(address _client, uint256 _clientBalance, uint256 _lockTime,  uint256 _m) public {
        client c = client(_client, lockedTokens[_client], (_lockTime * now));
        M = _m;
    }
    
    /**
     * @dev Lock the tokens (A_lock) for a specified time period from the recipient's address by an owner,
     * and apply a prepaid interest ('M')
     */
    function lock(address _from, address _to, uint256 A_lock, uint256 A_spend) public {
        uint256 lockUntil = now.add(client.lockingTime); // Calculating the lock time for the tokens.
        
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
        uint256 lockUntil = now.add(client.lockingTime);
        Queue qlt = lockingTimes[_from];
        
        for(uint8 i = 0; i < client.lockedTokens.length; i++){
            if(now > lockUntil){
                totalTokens[_from] = totalTokens[_from].add(A_spend); // Adding the locked tokens back to the client's address.
                lockedTokens[_from] = lockedTokens[_from].sub(A_lock); // Substracting the tokens from the "lockedTokens" array.
            }
        }
    }
    
    /**
     * @dev Get the total amount of tokens (locked + availableTokens).
     */
    function getTotalTokens(address client) public view returns (uint256) {
        return totalTokens[client]; // The total client balance initialized before deploying the contract.
    }
    
    /**
     * @dev Get the available tokens to spend after the locked tokens are deducted.
     */
    function getAvailableTokens(address client) public view returns (uint256) {
        uint256 availableTokens = totalTokens[client].sub(lockedTokens[client]);
        return availableTokens;
    }
    
    /**
     * @dev Get the specified amount of locked tokens.
     */
    function getLockedTokens(address client) public view returns (uint256) {
        return lockedTokens[client];
    }
}