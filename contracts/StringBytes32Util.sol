pragma solidity ^0.4.24;
contract StringBytes32Util {
    
    function stringToBytes32Tuple(string stringData) public pure returns (bytes32, bytes32) {
        bytes memory totalMemory = bytes(stringData);
        return (bytesToBytes32(totalMemory, 0), bytesToBytes32(totalMemory, 32));
    }
    
    function bytes32TupleToString(bytes32 one, bytes32 two) public pure returns (string) {
        return strConcat(bytes32ToString(one), bytes32ToString(two));
    }
    
    function bytesToBytes32(bytes b, uint offset) private pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32 && offset + i < b.length; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
         return out;
    }
    
    function bytes32ToString(bytes32 x) private pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    function strConcat(string _a, string _b) private pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
    
}
