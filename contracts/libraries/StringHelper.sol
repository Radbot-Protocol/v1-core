// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library StringHelper {
    function stringToBytes32(
        string memory source
    ) public pure returns (bytes32 result) {
        bytes memory temp = bytes(source);
        require(temp.length <= 32, "STL");
        if (temp.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(
        bytes32 source
    ) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && source[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = source[j];
        }
        return string(bytesArray);
    }

    function stringToBytes16(
        string memory source
    ) public pure returns (bytes16 result) {
        bytes memory temp = bytes(source);
        require(temp.length <= 16, "STL");
        if (temp.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 16))
        }
    }

    function bytes16ToString(
        bytes16 source
    ) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 16 && source[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = source[j];
        }
        return string(bytesArray);
    }
}
