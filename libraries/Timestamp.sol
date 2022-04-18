// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Utils} from './Utils.sol';

library Timestamp {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;
    uint constant ORIGIN_YEAR = 1970;
    
    function getMonthByIndex(uint i) internal pure returns (string memory) {
        string[12] memory months = [" Jan ", " Feb ", " Mar ", " Apr ", " May ", " Jun ", " Jul ", " Aug ", " Sep ", " Oct ", " Nov ", " Dec "];
        return months[i];
    }

    function getWeekdayByIndex(uint i) internal pure returns (string memory) {
        string[7] memory weekdays = [" Sun ", " Mon ", " Tue ", " Wed ", " Thu ", " Fri ", " Sat "];
        return weekdays[i];
    }

    function getCurrentTime() public view returns(string memory){
        uint timestamp = UTCplus8();
        uint year;
        uint month;
        uint day;
        uint hour;
        uint minute;
        uint second;
        uint weekday;
        (year, month, day, hour, minute, second, weekday) = parseTimestamp(timestamp);
        return printTime(year, month, day, hour, minute, second, weekday);
    }

    function toTimestamp(uint year, uint month, uint day) internal pure returns (uint) {
        uint i;
        uint timestamp;
 
        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }
 
        // Month
        uint[12] memory monthDayCounts = [uint(31), 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
 
        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }
 
        timestamp += DAY_IN_SECONDS * (day - 1);
 
        return timestamp;
    }

    function UTCplus8() internal view returns(uint){
        return block.timestamp + 8 * HOUR_IN_SECONDS;
    }

    function UTCplus8(uint timestamp) internal pure returns(uint){
        return timestamp + 8 * HOUR_IN_SECONDS;
    }

    function UTCminus8(uint timestamp) internal pure returns(uint){
        return timestamp - 8 * HOUR_IN_SECONDS;
    }

    function parseTimestamp(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second, uint weekday) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint i;
 
        // Year
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
 
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);
 
        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
 
        // Day
        for (i = 1; i <= getDaysInMonth(month, year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
 
        // Hour
        hour = (timestamp / 60 / 60) % 24;
 
        // Minute
        minute = (timestamp / 60) % 60;
 
        // Second
        second = timestamp % 60;
 
        // Day of week.
        weekday = (timestamp / DAY_IN_SECONDS + 4) % 7;

        return (year, month, day, hour, minute, second, weekday);
    }

    function printDate(uint year, uint month, uint day) internal pure returns(string memory){
        string memory date = string(abi.encodePacked(Utils.toString(year), getMonthByIndex(month-1), Utils.toString(day)));
        return date;
    }

    function printDate(uint year, uint month, uint day, uint weekday) internal pure returns(string memory){
        string memory date = string(abi.encodePacked(printDate(year, month, day), getWeekdayByIndex(weekday)));
        return date;
    }

    function printTime(uint year, uint month, uint day, uint hour, uint minute, uint second, uint weekday) internal pure returns(string memory){
        string memory time = printDate(year, month, day, weekday);
        if(hour < 10) time = string(abi.encodePacked(time, "0"));
        time = string(abi.encodePacked(time, Utils.toString(hour), ":"));
        if(minute < 10) time = string(abi.encodePacked(time, "0"));
        time = string(abi.encodePacked(time, Utils.toString(minute), ":"));
        if(second < 10) time = string(abi.encodePacked(time, "0"));
        time = string(abi.encodePacked(time, Utils.toString(second)));
        return time;
    }

    function isLeapYear(uint year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getYear(uint timestamp) internal pure returns (uint) {
        uint secondsAccountedFor = 0;
        uint year;
        uint numLeapYears;
 
        // Year
        year = uint(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
 
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
 
        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getDaysInMonth(uint month, uint year) internal pure returns (uint) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }
}