// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Utils} from './libraries/Utils.sol';

interface P_V { // 用于判断sender与直接burnFrom
    function effie() external view returns (address);
    function kyrin() external view returns (address);
    function owner() external view returns (address);
    function PiggyERC20() external view returns (address);
}

interface P_ERC20 {
    function transferFrom(address from, address to, uint value) external returns(bool success);
}

contract PiggyAwards {

    address public PiggyVerse; // management contract

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

    // uint private saleCnt;
    mapping (bytes4 => Sale) private sales;
    bytes4[] public toEffieOnSale; // 待售的奖励 Sale
    bytes4[] public toKyrinOnSale;
    bytes4[] public toEffieSaled; // 已售的奖励 Sale
    bytes4[] public toKyrinSaled;
    bytes4[] public toEffieCanceled; // 下架的奖励 Sale
    bytes4[] public toKyrinCanceled;

    // uint private awardCnt;
    mapping (bytes4 => Award) private awards;
    bytes4[] public toEffie; // 已拿到的奖励 Award
    bytes4[] public toKyrin;
    bytes4[] public toEffieDone; // 已用的奖励 Award
    bytes4[] public toKyrinDone;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);

    event OnSaleAdded(bytes4 saleId, string name, uint cnt, uint value, bool longTerm);
    event OnSaleDeleted(bytes4 saleId);
    event OnSaleCanceled(bytes4 saleId);
    event OnSaleLongTermChanged(bytes4 saleId, bool longTerm);
    event OnSaleBought(bytes4 saleId);
    event AwardAdded(bytes4 awardId, string name, uint cnt);
    event AwardCntAdded(bytes4 awardId, uint cnt);
    event AwardFinished(bytes4 awardId, uint cnt);

    /* ------------------------ Management ------------------------ */

    constructor(address p_v) {
        PiggyVerse = p_v;
    }

    modifier onlyKyrinEffie{
        require(P_V(PiggyVerse).kyrin() == msg.sender || P_V(PiggyVerse).effie() == msg.sender);
        _;
    }

    modifier onlyPiggyVerse{
        require(PiggyVerse == msg.sender);
        _;
    }

    function setPiggyVerse(address p_v) public onlyPiggyVerse { // 只能通过旧PiggyVerse改成新PiggyVerse
        PiggyVerse = p_v;
        emit PiggyVerseChanged(p_v);
    }

    /* ------------------------ Read ------------------------ */

    function getToEffieOnSaleLen() public view returns(uint){
        return toEffieOnSale.length;
    }

    function getToKyrinOnSaleLen() public view returns(uint){
        return toKyrinOnSale.length;
    }

    function getToEffieSaledLen() public view returns(uint){
        return toEffieSaled.length;
    }

    function getToKyrinSaledLen() public view returns(uint){
        return toKyrinSaled.length;
    }

    function getToEffieCanceledLen() public view returns(uint){
        return toEffieCanceled.length;
    }

    function getToKyrinCanceledLen() public view returns(uint){
        return toKyrinCanceled.length;
    }

    function getSaleById(bytes4 saleId) public view returns(string memory){
        string memory name = string(abi.encodePacked("[Name] ", sales[saleId].name));
        string memory cnt = string(abi.encodePacked(" [Cnt] ", Utils.toString(sales[saleId].cnt)));
        string memory value = string(abi.encodePacked(" [Value] ", Utils.toString(sales[saleId].value), "PP"));
        string memory longTerm = "";
        if(sales[saleId].longTerm == true) longTerm = "[Long-term] ";
        string memory sale = string(abi.encodePacked(longTerm, name, cnt, value));
        return sale;
    }

    function getToEffieLen() public view returns(uint){
        return toEffie.length;
    }

    function getToKyrinLen() public view returns(uint){
        return toKyrin.length;
    }

    function getToEffieDoneLen() public view returns(uint){
        return toEffieDone.length;
    }

    function getToKyrinDoneLen() public view returns(uint){
        return toKyrinDone.length;
    }

    function getAwardById(bytes4 awardId) public view returns(string memory){
        string memory name = string(abi.encodePacked("[Name] ", awards[awardId].name));
        string memory cnt = string(abi.encodePacked(" [Cnt] ", Utils.toString(awards[awardId].cnt)));
        string memory left = string(abi.encodePacked(" [Left] ", Utils.toString(awards[awardId].left)));
        string memory award = string(abi.encodePacked(name, cnt, left));
        return award;
    }

    /* ------------------------ Write ------------------------ */

    function addOnSale(string memory name, uint cnt, uint value, bool longTerm) public onlyKyrinEffie {
        require(cnt > 0 && value > 0);
        Sale memory sale;
        sale.name = name;
        sale.cnt = cnt;
        sale.value = value;
        sale.longTerm = longTerm;
        bytes4 saleId;
        if(msg.sender == P_V(PiggyVerse).effie()){
            saleId = Utils.bytes32to4(keccak256(abi.encodePacked(name, "Effie")));
            toKyrinOnSale.push(saleId);
        }
        else {
            saleId = Utils.bytes32to4(keccak256(abi.encodePacked(name, "Kyrin")));
            toEffieOnSale.push(saleId);
        }
        sales[saleId] = sale;
        emit OnSaleAdded(saleId, name, cnt, value, longTerm);
    }

    function deleteOnSale(bytes4 saleId) public onlyKyrinEffie { // 用于笔误删除
        if(msg.sender == P_V(PiggyVerse).effie()){
            require(Utils.bytes4InList(saleId, toKyrinOnSale) && !Utils.bytes4InList(saleId, toKyrinSaled));
            Utils.bytes4DeleteFromList(saleId, toKyrinOnSale);
        }
        else {
            require(Utils.bytes4InList(saleId, toEffieOnSale) && !Utils.bytes4InList(saleId, toEffieSaled));
            Utils.bytes4DeleteFromList(saleId, toEffieOnSale);
        }
        delete sales[saleId];
        emit OnSaleDeleted(saleId);
    }

    function cancelOnSale(bytes4 saleId) public onlyKyrinEffie { // 用于下架，不影响已售的Long-term
        if(msg.sender == P_V(PiggyVerse).effie()){
            require(Utils.bytes4InList(saleId, toKyrinOnSale));
            Utils.bytes4DeleteFromList(saleId, toKyrinOnSale);
            toKyrinCanceled.push(saleId);
        }
        else {
            require(Utils.bytes4InList(saleId, toEffieOnSale));
            Utils.bytes4DeleteFromList(saleId, toEffieOnSale);
            toEffieCanceled.push(saleId);
        }
        emit OnSaleCanceled(saleId);
    }

    function changeOnSaleLongTerm(bytes4 saleId) public onlyKyrinEffie {
        require(msg.sender == P_V(PiggyVerse).effie() && Utils.bytes4InList(saleId, toKyrinOnSale) || msg.sender == P_V(PiggyVerse).kyrin() && Utils.bytes4InList(saleId, toEffieOnSale));
        sales[saleId].longTerm = !sales[saleId].longTerm;
        emit OnSaleLongTermChanged(saleId, sales[saleId].longTerm);
    }

    function buyOnSale(bytes4 saleId, uint cnt) public onlyKyrinEffie {
        cnt = sales[saleId].longTerm == true ? cnt : 1;
        P_ERC20(P_V(PiggyVerse).PiggyERC20()).transferFrom(msg.sender, address(this), sales[saleId].value * cnt);
        if(msg.sender == P_V(PiggyVerse).kyrin()){  // sender: Kyrin
            require(Utils.bytes4InList(saleId, toKyrinOnSale));
            if(sales[saleId].longTerm == false){
                Utils.bytes4DeleteFromList(saleId, toKyrinOnSale);
            }
            toKyrinSaled.push(saleId);
            if(Utils.bytes4InList(saleId, toKyrin)){
                addAwardCnt(saleId, sales[saleId].cnt * cnt);
            }
            else {
                addAward(sales[saleId].name, sales[saleId].cnt * cnt);
            }
        }
        else { // sender: Effie
            require(Utils.bytes4InList(saleId, toEffieOnSale));
            if(sales[saleId].longTerm == false){
                Utils.bytes4DeleteFromList(saleId, toEffieOnSale);
            }
            toEffieSaled.push(saleId);
            if(Utils.bytes4InList(saleId, toEffie)){
                addAwardCnt(saleId, sales[saleId].cnt * cnt);
            }
            else {
                addAward(sales[saleId].name, sales[saleId].cnt * cnt);
            }
        }
        emit OnSaleBought(saleId);
    }

    function addAward(string memory name, uint cnt) public onlyKyrinEffie {
        require(cnt > 0);
        bool newAwardId = false;
        bytes4 awardId;
        if(msg.sender == P_V(PiggyVerse).effie()){
            awardId = Utils.bytes32to4(keccak256(abi.encodePacked(name, "Effie")));
            if(Utils.bytes4InList(awardId, toKyrin) || Utils.bytes4InList(awardId, toKyrinDone)){
                addAwardCnt(awardId, cnt);
            }
            else {
                newAwardId = true;
                toKyrin.push(awardId);
            }
        }
        else {
            awardId = Utils.bytes32to4(keccak256(abi.encodePacked(name, "Kyrin")));
            if(Utils.bytes4InList(awardId, toEffie) || Utils.bytes4InList(awardId, toEffieDone)){
                addAwardCnt(awardId, cnt);
            }
            else{
                newAwardId = true;
                toEffie.push(awardId);
            }
        }
        if(newAwardId){
            Award memory award;
            award.name = name;
            award.cnt = cnt;
            award.left = cnt;
            awards[awardId] = award;
            emit AwardAdded(awardId, name, cnt);
        }
    }

    function addAwardCnt(bytes4 awardId, uint cnt) public onlyKyrinEffie {
        require(cnt > 0);
        if(msg.sender == P_V(PiggyVerse).effie()){
            require(Utils.bytes4InList(awardId, toKyrin) || Utils.bytes4InList(awardId, toKyrinDone));
            if(Utils.bytes4InList(awardId, toKyrinDone)){
                Utils.bytes4DeleteFromList(awardId, toKyrinDone);
                toKyrin.push(awardId);
            }
        }
        else {
            require(Utils.bytes4InList(awardId, toEffie) || Utils.bytes4InList(awardId, toEffieDone));
            if(Utils.bytes4InList(awardId, toEffieDone)){
                Utils.bytes4DeleteFromList(awardId, toEffieDone);
                toEffie.push(awardId);
            }
        }
        awards[awardId].cnt += cnt;
        awards[awardId].left += cnt;
        emit AwardCntAdded(awardId, cnt);
    }

    function finishAward(bytes4 awardId, uint cnt) public onlyKyrinEffie {
        require(awards[awardId].left >= cnt);
        if(msg.sender == P_V(PiggyVerse).effie()){
            require(Utils.bytes4InList(awardId, toEffie));
            if(awards[awardId].left == cnt){
                Utils.bytes4DeleteFromList(awardId, toEffie);
                toEffieDone.push(awardId);
            }
            awards[awardId].left -= cnt;
        }
        else {
            require(Utils.bytes4InList(awardId, toKyrin));
            if(awards[awardId].left == cnt){
                Utils.bytes4DeleteFromList(awardId, toKyrin);
                toKyrinDone.push(awardId);
            }
            awards[awardId].left -= cnt;
        }
        emit AwardFinished(awardId, cnt);
    }
}