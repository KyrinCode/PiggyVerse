// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Utils} from './libraries/Utils.sol';

interface P_V { // 用于判断sender与直接burnFrom
    function effie() external view returns (address);
    function kyrin() external view returns (address);
}

interface P_ERC20 {
    function transferFrom(address from, address to, uint value) external returns(bool success);
}

contract PiggyAwards {

    address public owner;
    address public pendingOwner;
    address public PiggyVerse; // management contract
    address public PiggyERC20; // PP Token

    struct Sale {
        string name;
        uint cnt;
        uint value;
        bool longTerm; // 标注是否长期待售，若为false，在下一次售出时下架
    }

    struct Award {
        string name;
        uint cnt;
        uint left;
    }

    uint private saleCnt;
    mapping (uint => Sale) private sales;
    uint[] private toEffieOnSale; // 待售的奖励 Sale
    uint[] private toKyrinOnSale;
    uint[] private toEffieSaled; // 已售的奖励 Sale
    uint[] private toKyrinSaled;
    uint[] private toEffieCanceled; // 下架的奖励 Sale
    uint[] private toKyrinCanceled;

    uint private awardCnt;
    mapping (uint => Award) private awards;
    uint[] private toEffie; // 已拿到的奖励 Award
    uint[] private toKyrin;
    uint[] private toEffieDone; // 已用的奖励 Award
    uint[] private toKyrinDone;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);

    event OnSaleAdded(uint saleId, string name, uint cnt, uint value, bool longTerm);
    event OnSaleDeleted(uint saleId);
    event OnSaleCanceled(uint saleId);
    event OnSaleLongTermChanged(uint saleId, bool longTerm);
    event OnSaleBought(uint saleId);
    event AwardAdded(uint awardId, string name, uint cnt);
    event AwardFinished(uint awardId);
    event AwardCntChanged(uint awardId, uint cnt);

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

    function getToEffieOnSaleIds() public view returns(uint[] memory){
        return toEffieOnSale;
    }

    function getToKyrinOnSaleIds() public view returns(uint[] memory){
        return toKyrinOnSale;
    }

    function getToEffieSaledIds() public view returns(uint[] memory){
        return toEffieSaled;
    }

    function getToKyrinSaledIds() public view returns(uint[] memory){
        return toKyrinSaled;
    }

    function getToEffieCanceledIds() public view returns(uint[] memory){
        return toEffieCanceled;
    }

    function getToKyrinCanceledIds() public view returns(uint[] memory){
        return toKyrinCanceled;
    }

    function getSaleById(uint saleId) public view returns(string memory){
        string memory name = string(abi.encodePacked("[Name] ", sales[saleId].name));
        string memory cnt = string(abi.encodePacked(" [Cnt] ", Utils.toString(sales[saleId].cnt)));
        string memory value = string(abi.encodePacked(" [Value] ", Utils.toString(sales[saleId].value), "PP"));
        string memory longTerm = "";
        if(sales[saleId].longTerm == true) longTerm = "[Long-term] ";
        string memory sale = string(abi.encodePacked(longTerm, name, cnt, value));
        return sale;
    }

    function getToEffieIds() public view returns(uint[] memory){
        return toEffie;
    }

    function getToKyrinIds() public view returns(uint[] memory){
        return toKyrin;
    }

    function getToEffieDoneIds() public view returns(uint[] memory){
        return toEffieDone;
    }

    function getToKyrinDoneIds() public view returns(uint[] memory){
        return toKyrinDone;
    }

    function getAwardById(uint awardId) public view returns(string memory){
        string memory name = string(abi.encodePacked("[Name] ", awards[awardId].name));
        string memory cnt = string(abi.encodePacked(" [Cnt] ", Utils.toString(awards[awardId].cnt)));
        string memory award = string(abi.encodePacked(name, cnt));
        return award;
    }

    /* ------------------------ Write ------------------------ */

    function addOnSale(string memory name, uint cnt, uint value, bool longTerm, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        require(cnt > 0 && value > 0);
        uint saleId = saleCnt++;
        Sale memory sale;
        sale.name = name;
        sale.cnt = cnt;
        sale.value = value;
        sale.longTerm = longTerm;
        if(sender == P_V(PiggyVerse).effie()){
            toKyrinOnSale.push(saleId);
        }
        else {
            toEffieOnSale.push(saleId);
        }
        sales[saleId] = sale;
        emit OnSaleAdded(saleId, name, cnt, value, longTerm);
    }

    function deleteOnSale(uint saleId, address sender) public onlyPiggyVerse { // 用于笔误删除
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(saleId, toKyrinOnSale) && !Utils.inlist(saleId, toKyrinSaled) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(saleId, toEffieOnSale) && !Utils.inlist(saleId, toEffieSaled));
        if(sender == P_V(PiggyVerse).effie()) Utils.deleteIdFromList(saleId, toKyrinOnSale);
        else Utils.deleteIdFromList(saleId, toEffieOnSale);
        delete sales[saleId];
        emit OnSaleDeleted(saleId);
    }

    function cancelOnSale(uint saleId, address sender) public onlyPiggyVerse { // 用于下架，不影响已售的Long-term
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(saleId, toKyrinOnSale) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(saleId, toEffieOnSale));
        if(sender == P_V(PiggyVerse).effie()){
            Utils.deleteIdFromList(saleId, toKyrinOnSale);
            toKyrinCanceled.push(saleId);
        }
        else {
            Utils.deleteIdFromList(saleId, toEffieOnSale);
            toEffieCanceled.push(saleId);
        }
        emit OnSaleCanceled(saleId);
    }

    function changeOnSaleLongTerm(uint saleId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(saleId, toKyrinOnSale) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(saleId, toEffieOnSale));
        sales[saleId].longTerm = !sales[saleId].longTerm;
        emit OnSaleLongTermChanged(saleId, sales[saleId].longTerm);
    }

    function buyOnSale(uint saleId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(saleId, toEffieOnSale) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(saleId, toKyrinOnSale));
        P_ERC20(PiggyERC20).transferFrom(sender, address(this), sales[saleId].value);
        if(sender == P_V(PiggyVerse).kyrin()){  // sender: Kyrin
            if(sales[saleId].longTerm == false){
                Utils.deleteIdFromList(saleId, toKyrinOnSale);
            }
            toKyrinSaled.push(saleId);
        }
        else { // sender: Effie
            if(sales[saleId].longTerm == false){
                Utils.deleteIdFromList(saleId, toEffieOnSale);
            }
            toEffieSaled.push(saleId);
        }

        uint awardId = awardCnt++;
        Award memory award;
        award.name = sales[saleId].name;
        award.cnt = sales[saleId].cnt;
        awards[awardId] = award;
        if(sender == P_V(PiggyVerse).kyrin()){  // sender: Kyrin
            toKyrin.push(awardId);
        }
        else {  // sender: Effie
            toEffie.push(awardId);
        }
        emit OnSaleBought(saleId);
    }

    function addAward(string memory name, uint cnt, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        require(cnt > 0);
        uint awardId = awardCnt++;
        Award memory award;
        award.name = name;
        award.cnt = cnt;
        awards[awardId] = award;
        if(sender == P_V(PiggyVerse).effie()){
            toKyrin.push(awardId);
        }
        else {
            toEffie.push(awardId);
        }
        emit AwardAdded(awardId, name, cnt);
    }

    function finishAward(uint awardId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        if(sender == P_V(PiggyVerse).effie()){
            require(Utils.inlist(awardId, toKyrin));
            Utils.deleteIdFromList(awardId, toKyrin);
            toKyrinDone.push(awardId);
        }
        else {
            require(Utils.inlist(awardId, toEffie));
            Utils.deleteIdFromList(awardId, toEffie);
            toEffieDone.push(awardId);
        }
        emit AwardFinished(awardId);
    }

    function changeAwardCnt(uint awardId, uint cnt, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        if(sender == P_V(PiggyVerse).effie()){
            require(Utils.inlist(awardId, toKyrin));
        }
        else {
            require(Utils.inlist(awardId, toEffie));
        }
        require(cnt != awards[awardId].cnt);
        Award storage award = awards[awardId];
        award.cnt = cnt;
        emit AwardCntChanged(awardId, cnt);
    }
}