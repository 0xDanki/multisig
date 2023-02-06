// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSigWallet {
    address[] public owners;
    uint public required;
    uint public transactionCount;
    mapping(uint => mapping (address => bool)) public confirmations;

    struct Transaction {
        address recipient;
        uint value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;

    constructor(address[] memory _owners, uint _required) {
        require(_required >= 1);
        require(required <= _owners.length);
        require(_owners.length >= 1);
        owners = _owners;
        required = _required;
    }

    function addTransaction(address _recipient, uint _value, bytes memory _data) public returns(uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionCount] = Transaction(_recipient, _value, false, _data);
        transactionCount += 1;
        return transactionCount - 1;
    }

    function confirmTransaction(uint transactionId) public {
        require (isOwner(msg.sender) == true);
        confirmations[transactionId][msg.sender] = true;
        if (isConfirmed(transactionId)) {
        executeTransaction(transactionId);
        }
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint numConfirmed) {
        uint count;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function isOwner(address addr) internal view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address _recipient, uint _value, bytes memory _data) external {
        uint id = addTransaction(_recipient, _value, _data);
        confirmTransaction(id);
    }

    function isConfirmed(uint transactionId) public view returns(bool) {
        return getConfirmationsCount(transactionId) >= required;
    }

    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId));
        Transaction storage transaction = transactions[transactionId];
        (bool s, ) = transaction.recipient.call{ value: transaction.value }(transaction.data);
        require(s);
        transaction.executed = true;
    }

    receive() payable external {

    }
}
