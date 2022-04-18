// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Timestamp} from './libraries/Timestamp.sol';
import {Utils} from './libraries/Utils.sol';
 
contract PiggyMemories {
 
    address public owner;
    address public pendingOwner;
    address public PiggyVerse; // management contract

    struct Memory {
        uint timestamp;
        string name;
    }

    uint private memCnt;
    mapping (uint => Memory) private memories;
    uint[] private memIds;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);
    
    event MemoryAdded(uint memId, uint timestamp, string name);
    event MemoryDateModified(uint memId, uint timestamp);
    event MemoryNameModified(uint memId, string name);
    event MemoryDeleted(uint memId);

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

    function getCurrentTime() public view returns(string memory){
        return Timestamp.getCurrentTime();
    }

    function getMemIds() public view returns(uint[] memory){
        return memIds;
    }

    function getMemoryById(uint memId) public view returns(string memory){
        uint year;
        uint month;
        uint day;
        uint weekday;
        (year, month, day , , , , weekday) = Timestamp.parseTimestamp(Timestamp.UTCplus8(memories[memId].timestamp));
        string memory date = string(abi.encodePacked(Timestamp.printDate(year, month, day, weekday), " "));
        string memory name = memories[memId].name;
        string memory mem = string(abi.encodePacked(date, name));
        return mem;
    }

    function getSumDaysByMemId(uint memId) public view returns(uint){
        uint gap = block.timestamp - memories[memId].timestamp;
        uint sumDays = gap / Timestamp.DAY_IN_SECONDS + 1;
        return sumDays;
    }

    function getWaitDaysByMemId(uint memId) public view returns(uint){
        uint year;
        uint month;
        uint day;
        uint anniversary = memories[memId].timestamp;
        (year, month, day , , , , ) = Timestamp.parseTimestamp(Timestamp.UTCplus8(anniversary));
        while (anniversary + Timestamp.DAY_IN_SECONDS < block.timestamp) {
            year += 1;
            anniversary = Timestamp.UTCminus8(Timestamp.toTimestamp(year, month, day));
        }
        uint waitDays = (anniversary + Timestamp.DAY_IN_SECONDS - block.timestamp) / Timestamp.DAY_IN_SECONDS;
        return (waitDays);
    }

    function getDateByMemIdAndSumDays(uint memId, uint sumDays) public view returns(string memory){
        uint year;
        uint month;
        uint day;
        uint weekday;
        (year, month, day, , , , weekday) = Timestamp.parseTimestamp(Timestamp.UTCplus8(memories[memId].timestamp + (sumDays-1) * Timestamp.DAY_IN_SECONDS));
        return Timestamp.printDate(year, month, day, weekday);
    }

    /* ------------------------ Write ------------------------ */

    function addMemory(uint year, uint month, uint day, string memory name) public onlyPiggyVerse {
        uint memId = memCnt++;
        Memory memory mem;
        mem.timestamp = Timestamp.UTCminus8(Timestamp.toTimestamp(year, month, day));
        mem.name = name;
        memories[memId] = mem;
        memIds.push(memId);
        emit MemoryAdded(memId, mem.timestamp, name);
    }

    function modifyMemoryDate(uint memId, uint year, uint month, uint day) public onlyPiggyVerse {
        require(Utils.inlist(memId, memIds));
        Memory storage mem = memories[memId];
        mem.timestamp = Timestamp.UTCminus8(Timestamp.toTimestamp(year, month, day));
        emit MemoryDateModified(memId, mem.timestamp);
    }

    function modifyMemoryName(uint memId, string memory name) public onlyPiggyVerse {
        require(Utils.inlist(memId, memIds));
        Memory storage mem = memories[memId];
        mem.name = name;
        emit MemoryNameModified(memId, name);
    }

    function deleteMemory(uint memId) public onlyPiggyVerse {
        require(Utils.inlist(memId, memIds));
        Utils.deleteIdFromList(memId, memIds);
        delete memories[memId];
        emit MemoryDeleted(memId);
    }
}