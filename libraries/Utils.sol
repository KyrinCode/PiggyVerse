// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Utils {
    
    function inlist(uint id, uint[] memory list) internal pure returns(bool){
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == id) {
                return true;
            }
        }
        return false;
    }

    function equal(string memory s1, string memory s2) internal pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function toString(uint256 value) internal pure returns(string memory){
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function deleteIdFromList(uint id, uint[] storage list) internal {
        bool replace = false;
        for(uint i = 0; i < list.length; i++){
            if(replace == true){
                list[i-1] = list[i];
            }else if(id == list[i]){
                replace = true;
            }
        } 
        list.pop();
    }
}