pragma solidity ^0.4.21;

contract Deque {
    mapping(uint256 => bytes) deque;
    uint256 first = 2**255;
    uint256 last = first - 1;

    function pushLeft(bytes data) public {
        first -= 1;
        deque[first] = data;
    }

    function pushRight(bytes data) public {
        last += 1;
        deque[last] = data;
    }

    function popLeft() public returns (bytes data) {
        require(last >= first);  // non-empty deque

        data = deque[first];

        delete deque[first];
        first += 1;
    }

    function popRight() public returns (bytes data) {
        require(last >= first);  // non-empty deque

        data = deque[last];

        delete deque[last];
        last -= 1;
    }
}
