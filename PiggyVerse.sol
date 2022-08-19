// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface P {
	function setPiggyVerse(address p_v) external;
}

contract PiggyVerse{
	address public owner;
	address public pendingOwner;
	address public effie;
	address public kyrin;

	address public PiggyERC20;

	address public PiggyAwards;
	address public PiggyTasks;
	address public PiggyMemories;
	address public PiggyDiaries;
	address public PiggyChecklist;

	event OwnershipTransferred(address owner, address pendingOwner);
    event EffieChanged(address newEffie);
    event KyrinChanged(address newKyrin);

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

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function setEffie(address newEffie) public onlyOwner {
    	effie = newEffie;
    	emit EffieChanged(newEffie);
    }
    function setKyrin(address newKyrin) public onlyOwner {
    	kyrin = newKyrin;
    	emit KyrinChanged(newKyrin);
    }

    function setPiggyERC20(address token) public onlyOwner {
    	PiggyERC20 = token;
    	emit PiggyERC20Changed(token);
    }

    function setPiggyAwards(address p_a) public onlyOwner {
    	PiggyAwards = p_a;
    	emit PiggyAwardsChanged(p_a);
    }
    function setPiggyTasks(address p_t) public onlyOwner {
    	PiggyTasks = p_t;
    	emit PiggyTasksChanged(p_t);
    }
    function setPiggyMemories(address p_m) public onlyOwner {
    	PiggyMemories = p_m;
    	emit PiggyMemoriesChanged(p_m);
    }
    function setPiggyDiaries(address p_d) public onlyOwner {
    	PiggyDiaries = p_d;
    	emit PiggyDiariesChanged(p_d);
    }
    function setPiggyChecklist(address p_c) public onlyOwner {
    	PiggyChecklist = p_c;
    	emit PiggyChecklistChanged(p_c);
    }

    function updatePiggyVerse(address p_v) public onlyOwner {
    	P(PiggyAwards).setPiggyVerse(p_v);
    	P(PiggyTasks).setPiggyVerse(p_v);
    	P(PiggyMemories).setPiggyVerse(p_v);
    	P(PiggyDiaries).setPiggyVerse(p_v);
    	P(PiggyChecklist).setPiggyVerse(p_v);
    }