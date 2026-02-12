// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ListaTrust {
    struct Utang {
        uint id;
        address customer;
        uint amount;
        string items;
        bool paid;
        uint timestamp;
    }
    
    Utang[] public utangList;
    address public owner;
    
    // Security: Track active utang to prevent ID confusion
    mapping(uint => bool) public activeUtang;
    
    event NewUtang(uint id, address customer, uint amount, string items);
    event UtangPaid(uint id);
    event UtangDeleted(uint id);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "IAS2: Only store owner authorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // 1. Record utang - Owner only
    function addUtang(address _customer, uint _amount, string memory _items) public onlyOwner {
        uint newId = utangList.length;
        utangList.push(Utang(newId, _customer, _amount, _items, false, block.timestamp));
        activeUtang[newId] = true;
        emit NewUtang(newId, _customer, _amount, _items);
    }
    
    // 2. Mark as paid - Owner only (full payment)
    function markAsPaid(uint _id) public onlyOwner {
        require(activeUtang[_id], "IAS2: Utang does not exist");
        require(!utangList[_id].paid, "IAS2: Already paid");
        utangList[_id].paid = true;
        emit UtangPaid(_id);
    }
    
    // 3. Delete utang - Owner only (soft delete, preserves history)
    function deleteUtang(uint _id) public onlyOwner {
        require(activeUtang[_id], "IAS2: Utang does not exist");
        activeUtang[_id] = false;
        emit UtangDeleted(_id);
    }
    
    // 4. Edit utang - Owner only (fix mistakes before payment)
    function editUtang(uint _id, uint _newAmount, string memory _newItems) public onlyOwner {
        require(activeUtang[_id], "IAS2: Utang does not exist");
        require(!utangList[_id].paid, "IAS2: Cannot edit paid utang");
        utangList[_id].amount = _newAmount;
        utangList[_id].items = _newItems;
    }
    
    // 5. View customer utang - Anyone can read (transparency)
    function getCustomerUtang(address _customer) public view returns (Utang[] memory) {
        uint count = 0;
        for(uint i = 0; i < utangList.length; i++) {
            if(utangList[i].customer == _customer && activeUtang[i]) count++;
        }
        
        Utang[] memory result = new Utang[](count);
        uint index = 0;
        for(uint i = 0; i < utangList.length; i++) {
            if(utangList[i].customer == _customer && activeUtang[i]) {
                result[index] = utangList[i];
                index++;
            }
        }
        return result;
    }
    
    // 6. Get total unpaid - Customer can check balance
    function getTotalUnpaid(address _customer) public view returns (uint) {
        uint total = 0;
        for(uint i = 0; i < utangList.length; i++) {
            if(utangList[i].customer == _customer && activeUtang[i] && !utangList[i].paid) {
                total += utangList[i].amount;
            }
        }
        return total;
    }
    
    // 7. Security: Verify utang exists and is active
    function verifyUtang(uint _id) public view returns (bool) {
        return _id < utangList.length && activeUtang[_id];
    }
}