// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Utils} from './libraries/Utils.sol';

contract PiggyChecklist {

	address public owner;
    address public pendingOwner;
    address public PiggyVerse; // management contract

    uint private cnt;
    mapping (uint => string) private checklist;
    uint[] private todo;
    uint[] private done;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);

    event TodoAdded(uint id, string name);
    event TodoModified(uint id, string name);
    event TodoDeleted(uint id);
    event ToDoFinished(uint id);

    /* ------------------------ Management ------------------------ */

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    modifier onlyPendingOwner{
        require(pendingOwner == msg.sender);
        _;
    }

    modifier onlyPiggyVerse{
        require(PiggyVerse == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function setPiggyVerse(address newPiggyVerse) public onlyOwner {
        PiggyVerse = newPiggyVerse;
        emit PiggyVerseChanged(newPiggyVerse);
    }

    /* ------------------------ Read ------------------------ */

    function getTodoIds() public view returns(uint[] memory){
        return todo;
    }

    function getDoneIds() public view returns(uint[] memory){
    	return done;
    }

    function getById(uint id) public view returns(string memory){
        return checklist[id];
    }

    /* ------------------------ Write ------------------------ */

    function addTodo(string memory name) public onlyPiggyVerse {
        uint id = cnt++;
        checklist[id] = name;
        todo.push(id);
        emit TodoAdded(id, name);
    }

    function modifyTodo(uint id, string memory name) public onlyPiggyVerse {
        require(Utils.inlist(id, todo));
        checklist[id] = name;
        emit TodoModified(id, name);
    }

    function deleteTodo(uint id) public onlyPiggyVerse {
        require(Utils.inlist(id, todo));
        Utils.deleteIdFromList(id, todo);
        delete checklist[id];
        emit TodoDeleted(id);
    }

    function finishTodo(uint id) public onlyPiggyVerse {
    	require(Utils.inlist(id, todo));
        Utils.deleteIdFromList(id, todo);
        done.push(id);
        emit ToDoFinished(id);
    }
}