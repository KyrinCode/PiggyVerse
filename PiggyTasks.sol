// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Timestamp} from './libraries/Timestamp.sol';
import {Utils} from './libraries/Utils.sol';

interface P_V { // 用于直接mint
    function effie() external view returns (address);
    function kyrin() external view returns (address);
}

interface P_ERC20 {
    function mint(address to, uint value) external returns(bool success);
}

contract PiggyTasks {
    
    address public owner;
    address public pendingOwner;
    address public PiggyVerse; // management contract
    address public PiggyERC20; // PP Token

    struct Task {
        string name; // 次数、有效期等信息均在此字段
        uint value;
        bool longTerm; // 是否是长期任务，true则在完成与审核后依然在有效任务列表保留，false则从有效任务列表剔除
    }

    uint private taskCnt;
    mapping (uint => Task) private tasks;
    uint[] private toEffie; // 给...的有效任务列表
    uint[] private toKyrin;
    uint[] private toEffieFinished; // 完成待审核的任务列表
    uint[] private toKyrinFinished;
    uint[] private toEffieVerified; // 审核通过的任务列表
    uint[] private toKyrinVerified;
    uint[] private toEffieCanceled; // 下架的任务列表
    uint[] private toKyrinCanceled;

    uint private lastCheckin;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);

    event TaskAdded(uint taskId, string name, uint value, bool longTerm);
    event TaskDeleted(uint taskId);
    event TaskCanceled(uint taskId);
    event TaskLongTermChanged(uint taskId, bool longTerm);
    event TaskFinished(uint taskId);
    event TaskVerified(uint taskId);

    event Checkin();

    /* ------------------------ Management ------------------------ */

    constructor(address token) {
        owner = msg.sender;
        PiggyERC20 = token;
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

    function getToEffieIds() public view returns(uint[] memory){
        return toEffie;
    }

    function getToKyrinIds() public view returns(uint[] memory){
        return toKyrin;
    }

    function getToEffieFinishedIds() public view returns(uint[] memory){
        return toEffieFinished;
    }

    function getToKyrinFinishedIds() public view returns(uint[] memory){
        return toKyrinFinished;
    }

    function getToEffieVerifiedIds() public view returns(uint[] memory){
        return toEffieVerified;
    }

    function getToKyrinVerifiedIds() public view returns(uint[] memory){
        return toKyrinVerified;
    }

    function getToEffieCanceledIds() public view returns(uint[] memory){
        return toEffieCanceled;
    }

    function getToKyrinCanceledIds() public view returns(uint[] memory){
        return toKyrinCanceled;
    }

    function getTaskById(uint taskId) public view returns(string memory){
        string memory name = string(abi.encodePacked("[Name] ", tasks[taskId].name));
        string memory value = string(abi.encodePacked(" [Value] ", Utils.toString(tasks[taskId].value), "PP"));
        string memory longTerm = "";
        if(tasks[taskId].longTerm == true) longTerm = "[Long-term] ";
        string memory task = string(abi.encodePacked(longTerm, name, value));
        return task;
    }

    /* ------------------------ Write ------------------------ */

    function addTask(string memory name, uint value, bool longTerm, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        require(value > 0);
        uint taskId = taskCnt++;
        Task memory task;
        task.name = name;
        task.value = value;
        task.longTerm = longTerm;
        if(sender == P_V(PiggyVerse).effie()){
            toKyrin.push(taskId);
        }
        else {
            toEffie.push(taskId);
        }
        tasks[taskId] = task;
        emit TaskAdded(taskId, name, value, longTerm);
    }

    function deleteTask(uint taskId, address sender) public onlyPiggyVerse { // 用于笔误删除
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(taskId, toKyrin) && !Utils.inlist(taskId, toKyrinFinished) && !Utils.inlist(taskId, toKyrinVerified) && !Utils.inlist(taskId, toKyrinCanceled) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(taskId, toEffie) && !Utils.inlist(taskId, toEffieFinished) && !Utils.inlist(taskId, toEffieVerified) && !Utils.inlist(taskId, toEffieCanceled));
        if(sender == P_V(PiggyVerse).effie()) Utils.deleteIdFromList(taskId, toKyrin);
        else Utils.deleteIdFromList(taskId, toEffie);
        delete tasks[taskId];
        emit TaskDeleted(taskId);
    }

    function cancelTask(uint taskId, address sender) public onlyPiggyVerse { // 用于下架，不影响已完成的Long-term
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(taskId, toKyrin) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(taskId, toEffie));
        if(sender == P_V(PiggyVerse).effie()){
            Utils.deleteIdFromList(taskId, toKyrin);
            toKyrinCanceled.push(taskId);
        }
        else {
            Utils.deleteIdFromList(taskId, toEffie);
            toEffieCanceled.push(taskId);
        }
        emit TaskCanceled(taskId);
    }

    function changeTaskLongTerm(uint taskId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(taskId, toKyrin) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(taskId, toEffie));
        tasks[taskId].longTerm = !tasks[taskId].longTerm;
        emit TaskLongTermChanged(taskId, tasks[taskId].longTerm);
    }

    function finishTask(uint taskId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(taskId, toEffie) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(taskId, toKyrin));
        if(sender == P_V(PiggyVerse).kyrin()){ // sender: Kyrin
            if(tasks[taskId].longTerm == false){
                Utils.deleteIdFromList(taskId, toKyrin);
            }
            toKyrinFinished.push(taskId);
        }
        else {  // sender: Effie
            if(tasks[taskId].longTerm == false){
                Utils.deleteIdFromList(taskId, toEffie);
            }
            toEffieFinished.push(taskId);
        }
        emit TaskFinished(taskId);
    }

    function verifyTask(uint taskId, bool fail, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(taskId, toKyrinFinished) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(taskId, toEffieFinished));
        if(sender == P_V(PiggyVerse).effie()){ // sender: Effie
            Utils.deleteIdFromList(taskId, toKyrinFinished);
            if(fail == true){ // 未通过
                if(tasks[taskId].longTerm == false){
                    toKyrin.push(taskId);
                }
            }
            else { // 通过
                P_ERC20(PiggyERC20).mint(P_V(PiggyVerse).kyrin(), tasks[taskId].value);
                toKyrinVerified.push(taskId);
            }
        }
        else { // sender: Kyrin
            Utils.deleteIdFromList(taskId, toEffieFinished);
            if(fail == true){ // 未通过
                if(tasks[taskId].longTerm == false){
                    toEffie.push(taskId);
                }
            }
            else { // 通过
                P_ERC20(PiggyERC20).mint(P_V(PiggyVerse).effie(), tasks[taskId].value);
                toEffieVerified.push(taskId);
            }
        }
        emit TaskVerified(taskId);
    }

    function checkin(address sender) public onlyPiggyVerse { // 早8点刷新
        require(block.timestamp / Timestamp.DAY_IN_SECONDS > lastCheckin / Timestamp.DAY_IN_SECONDS);
        lastCheckin = block.timestamp;
        P_ERC20(PiggyERC20).mint(sender, 2);
        emit Checkin();
    }
}