// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Timestamp} from './libraries/Timestamp.sol';
import {Utils} from './libraries/Utils.sol';

interface P_V { // 用于判断sender
    function effie() external view returns (address);
    function kyrin() external view returns (address);
}

interface P_ERC20 {
    function transferFrom(address from, address to, uint value) external returns(bool success);
    function mint(address to, uint value) external returns(bool success);
}
 
contract PiggyDiaries {

    address public owner;
    address public pendingOwner;
    address public PiggyVerse; // management contract
    address public PiggyERC20; // PP Token

    struct Diary {
        uint timestamp;
        string text; // 加密日记需要通过secret在encode函数加密
        string author;
        bool tip; // 解密日记自动为true
        uint[] commentIds;
    }

    struct Comment {
        uint timestamp;
        string text;
        string author;
    }

    uint private diaryCnt;
    mapping (uint => Diary) private diaries;
    uint[] private byEffie;
    uint[] private byKyrin;
    uint[] private byEffieLocked; // 作者查看时通过id和secret解密text并显示，对方解锁时通过secret将text解密后覆盖并将id移出locked
    uint[] private byKyrinLocked;

    uint private commentCnt;
    mapping (uint => Comment) private comments;

    event OwnershipTransferred(address owner, address pendingOwner);
    event PiggyVerseChanged(address newPiggyVerse);

    event DiaryAdded(uint diaryId, uint timestamp, string author);
    event DiaryDateModified(uint diaryId, uint timestamp);
    event DiaryTextModified(uint diaryId);
    event DiaryDeleted(uint diaryId);
    event DiaryCommented(uint diaryId, uint timestamp, string author);
    event CommentDeleted(uint diaryId, uint commentId);
    event DiaryTipped(uint diaryId);
    event LockedDiaryAdded(uint diaryId, uint timestamp, string author);
    event DiaryUnlocked(uint diaryId);

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

    function getByEffieIds() public view returns(uint[] memory){
        return byEffie;
    }

    function getByKyrinIds() public view returns(uint[] memory){
        return byKyrin;
    }

    function getByEffieLockedIds() public view returns(uint[] memory){
        return byEffieLocked;
    }

    function getByKyrinLockedIds() public view returns(uint[] memory){
        return byKyrinLocked;
    }

    function getDiaryById(uint diaryId) public view returns(string memory){
        uint year;
        uint month;
        uint day;
        uint weekday;
        (year, month, day, , , , weekday) = Timestamp.parseTimestamp(Timestamp.UTCplus8(diaries[diaryId].timestamp));
        string memory date = string(abi.encodePacked(Timestamp.printDate(year, month, day, weekday), " "));
        string memory author = string(abi.encodePacked(diaries[diaryId].author, ": "));
        string memory text = diaries[diaryId].text;
        string memory tip = "";
        if(diaries[diaryId].tip == true) tip = "[Tipped] ";

        string memory diary = string(abi.encodePacked(tip, date, author, text));
        // comments
        for(uint i = 0; i < diaries[diaryId].commentIds.length; i++){
            uint commentId = diaries[diaryId].commentIds[i];
            string memory comment = string(abi.encodePacked(" ->[Comment ", Utils.toString(commentId), " ", getCommentById(commentId), "]"));
            diary = string(abi.encodePacked(diary, comment));
        }
        return diary;
    }

    function getCommentById(uint commentId) public view returns(string memory){
        uint year;
        uint month;
        uint day;
        uint hour;
        uint minute;
        uint second;
        uint weekday;
        (year, month, day, hour, minute, second, weekday) = Timestamp.parseTimestamp(Timestamp.UTCplus8(comments[commentId].timestamp));
        string memory author = string(abi.encodePacked(comments[commentId].author, ": "));
        string memory text = comments[commentId].text;
        string memory time = string(abi.encodePacked(" ", Timestamp.printTime(year, month, day, hour, minute, second, weekday)));
        string memory comment = string(abi.encodePacked(author, text, time));
        return comment;
    }

    function encodeDiary(string memory text, string memory secret) public pure returns (bytes memory){
        bytes memory t = bytes(text);
        bytes memory left = new bytes(32 - t.length % 32);
        bytes memory t2 = bytes.concat(left, t);

        bytes32 secretHash = keccak256(abi.encodePacked(secret));
        bytes memory s = new bytes(32);
        assembly { mstore(add(s, 32), secretHash) }

        bytes memory e;
        for(uint i = left.length; i < t2.length; i++){
            bytes1 x = t2[i] ^ s[i%32];
            e = bytes.concat(e, x);
        }
        return e;
    }

    function viewLockedDiary(uint diaryId, string memory secret) public view returns (string memory){
        require(Utils.inlist(diaryId, byEffieLocked) || Utils.inlist(diaryId, byKyrinLocked));
        uint year;
        uint month;
        uint day;
        uint weekday;
        (year, month, day, , , , weekday) = Timestamp.parseTimestamp(Timestamp.UTCplus8(diaries[diaryId].timestamp));
        string memory date = string(abi.encodePacked(Timestamp.printDate(year, month, day, weekday), " "));
        string memory author = string(abi.encodePacked(diaries[diaryId].author, ": "));
        string memory text = _decode(diaries[diaryId].text, secret);
        string memory lockedDiary = string(abi.encodePacked(date, author, text));
        return lockedDiary;
    }

    function _decode(string memory encodedText, string memory secret) internal pure returns (string memory){
        bytes memory e = bytes(encodedText);
        bytes memory left = new bytes(32 - e.length % 32);
        bytes memory e2 = bytes.concat(left, e);

        bytes32 secretHash = keccak256(abi.encodePacked(secret));
        bytes memory s = new bytes(32);
        assembly { mstore(add(s, 32), secretHash) }
        
        bytes memory d;
        for(uint i = left.length; i < e2.length; i++){
            bytes1 x = e2[i] ^ s[i%32];
            d = bytes.concat(d, x);
        }
        string memory text = string(d);
        return text;
    }

    /* ------------------------ Write ------------------------ */

    function addDiary(string memory text, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        uint diaryId = diaryCnt++;
        Diary memory diary;
        diary.timestamp = block.timestamp;
        diary.text = text;
        if(sender == P_V(PiggyVerse).effie()){
            diary.author = "Effie";
            byEffie.push(diaryId);
        }
        else {
            diary.author = "Kyrin";
            byKyrin.push(diaryId);
        }
        diaries[diaryId] = diary;
        emit DiaryAdded(diaryId, diary.timestamp, diary.author);
    }

    function modifyDiaryDate(uint diaryId, uint year, uint month, uint day, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && (Utils.inlist(diaryId, byEffie) || Utils.inlist(diaryId, byEffieLocked)) || sender == P_V(PiggyVerse).kyrin() && (Utils.inlist(diaryId, byKyrin) || Utils.inlist(diaryId, byKyrinLocked)));
        diaries[diaryId].timestamp = Timestamp.UTCplus8(Timestamp.toTimestamp(year, month, day));
        emit DiaryDateModified(diaryId, diaries[diaryId].timestamp);
    }

    function modifyDiaryText(uint diaryId, string memory text, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(diaryId, byEffie) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(diaryId, byKyrin));
        diaries[diaryId].text = text;
        emit DiaryTextModified(diaryId);
    }

    function deleteDiary(uint diaryId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && (Utils.inlist(diaryId, byEffie) || Utils.inlist(diaryId, byEffieLocked)) || sender == P_V(PiggyVerse).kyrin() && (Utils.inlist(diaryId, byKyrin) || Utils.inlist(diaryId, byKyrinLocked)));
        for(uint i = 0; i < diaries[diaryId].commentIds.length; i++){
            uint commentId = diaries[diaryId].commentIds[i];
            delete comments[commentId];
            emit CommentDeleted(diaryId, commentId);
        }
        if(sender == P_V(PiggyVerse).effie()){
            if(Utils.inlist(diaryId, byEffie)) Utils.deleteIdFromList(diaryId, byEffie);
            else Utils.deleteIdFromList(diaryId, byEffieLocked);
        }
        else {
            if(Utils.inlist(diaryId, byKyrin)) Utils.deleteIdFromList(diaryId, byKyrin);
            else Utils.deleteIdFromList(diaryId, byKyrinLocked);
        }
        delete diaries[diaryId];
        emit DiaryDeleted(diaryId);
    }

    function commentDiary(uint diaryId, string memory text, address sender) public onlyPiggyVerse {
        require(Utils.inlist(diaryId, byEffie) || Utils.inlist(diaryId, byKyrin));
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        uint commentId = commentCnt++;
        Comment memory comment;
        comment.timestamp = block.timestamp;
        comment.text = text;
        if(sender == P_V(PiggyVerse).effie()) comment.author = "Effie";
        else comment.author = "Kyrin";
        comments[commentId] = comment;
        diaries[diaryId].commentIds.push(commentId);
        emit DiaryCommented(diaryId, comment.timestamp, comment.author);
    }

    function deleteComment(uint diaryId, uint commentId, address sender) public onlyPiggyVerse {
        require(Utils.inlist(diaryId, byEffie) || Utils.inlist(diaryId, byKyrin));
        require(Utils.inlist(commentId, diaries[diaryId].commentIds));
        require(sender == P_V(PiggyVerse).effie() && Utils.equal(comments[commentId].author, "Effie") || sender == P_V(PiggyVerse).kyrin() && Utils.equal(comments[commentId].author, "Kyrin"));
        Utils.deleteIdFromList(commentId, diaries[diaryId].commentIds);
        delete comments[commentId];
        emit CommentDeleted(diaryId, commentId);
    }

    function tipDiary(uint diaryId, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(diaryId, byKyrin) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(diaryId, byEffie));
        require(diaries[diaryId].tip == false);
        if(sender == P_V(PiggyVerse).effie()) P_ERC20(PiggyERC20).mint(P_V(PiggyVerse).kyrin(), 3);
        P_ERC20(PiggyERC20).mint(P_V(PiggyVerse).effie(), 3);
        diaries[diaryId].tip = true;
        emit DiaryTipped(diaryId);
    }

    function addLockedDiary(bytes memory e, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() || sender == P_V(PiggyVerse).kyrin());
        uint diaryId = diaryCnt++;
        Diary memory diary;
        diary.timestamp = block.timestamp;
        diary.text = string(e);
        if(sender == P_V(PiggyVerse).effie()){
            diary.author = "Effie";
            byEffieLocked.push(diaryId);
        }
        else {
            diary.author = "Kyrin";
            byKyrinLocked.push(diaryId);
        }
        diaries[diaryId] = diary;
        emit LockedDiaryAdded(diaryId, diary.timestamp, diary.author);
    }

    function unlockDiary(uint diaryId, string memory secret, address sender) public onlyPiggyVerse {
        require(sender == P_V(PiggyVerse).effie() && Utils.inlist(diaryId, byKyrinLocked) || sender == P_V(PiggyVerse).kyrin() && Utils.inlist(diaryId, byEffieLocked));
        if(sender == P_V(PiggyVerse).effie()) P_ERC20(PiggyERC20).transferFrom(sender, P_V(PiggyVerse).kyrin(), 1);
        else P_ERC20(PiggyERC20).transferFrom(sender, P_V(PiggyVerse).effie(), 1);
        P_ERC20(PiggyERC20).transferFrom(sender, address(this), 2);
        diaries[diaryId].text =  _decode(diaries[diaryId].text, secret);
        diaries[diaryId].tip = true;
        if(sender == P_V(PiggyVerse).effie()){
            Utils.deleteIdFromList(diaryId, byKyrinLocked);
            byKyrin.push(diaryId);
        }
        else {
            Utils.deleteIdFromList(diaryId, byEffieLocked);
            byEffie.push(diaryId);
        }
        emit DiaryUnlocked(diaryId);
    }
}