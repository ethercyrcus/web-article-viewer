pragma solidity ^0.4.24;

contract StringBytes32UtilInterface{
    function stringToBytes32Tuple(string data) public constant returns (bytes32, bytes32);
}

contract UserContentRegister {

    struct User {
        string userName;
        string profileMetaData;
        uint256 numContent;
        mapping (uint256 => string) contentIndex;
        mapping (uint256 => string) contentLinks; //update Publication or tag info
    }

    mapping (address => User) public userIndex;
    mapping (address => bool) public registered;
    mapping (string => address) _userAddressLookup;
    uint256 public numUsers;
    mapping (string => bool) _checkUserNameTaken;
    
    StringBytes32UtilInterface stringBytes32Util;

    constructor(address stringBytes32UtilAddress) public  {
        stringBytes32Util = StringBytes32UtilInterface(stringBytes32UtilAddress);
    }

    function registerNewUser(string userName, string metaData) public returns (bool) {
        if (!registered[msg.sender] && !_checkUserNameTaken[userName]) {
            userIndex[msg.sender] = User(userName, metaData, 0);
            _checkUserNameTaken[userName] = true;
            registered[msg.sender] = true;
            _userAddressLookup[userName] = msg.sender;
            numUsers++;
            return true;
        }
        return false;
    }

    function getUserAddress(string userName) public constant returns (address) {
        return _userAddressLookup[userName];
    }

    function getNumContent(address whichUser) public constant returns (uint256) {
        return userIndex[whichUser].numContent;
    }

    function publishContent(string content) public  {
        assert(registered[msg.sender]);
        userIndex[msg.sender].contentIndex[userIndex[msg.sender].numContent] = content;
        userIndex[msg.sender].numContent++;
    }

    function updateContentLinks(uint256 contentIndex, string links) public  {
        assert(!registered[msg.sender]);
        assert(contentIndex < userIndex[msg.sender].numContent);
        userIndex[msg.sender].contentLinks[contentIndex] = links;
    }

    function updateMyUserName(string newUsername) public {
        if (registered[msg.sender] && !_checkUserNameTaken[newUsername]) {
            _checkUserNameTaken[userIndex[msg.sender].userName] = false;
            userIndex[msg.sender].userName = newUsername;
            _checkUserNameTaken[newUsername] = true;
        }
    }

    function updateMetaData(string _metaData) public {
        if (registered[msg.sender]) {
            userIndex[msg.sender].profileMetaData = _metaData;
        }
    }

    function checkUserNameTaken(string username) public constant returns (bool) {
        return _checkUserNameTaken[username];
    }

    function getUserContent(address whichUser, uint256 index) public constant returns (string content) {
        return userIndex[whichUser].contentIndex[index];
    }

    function getUserContentBytes(address whichUser, uint256 index) public constant returns (bytes32, bytes32) {
        return stringBytes32Util.stringToBytes32Tuple(userIndex[whichUser].contentIndex[index]);
    }

    function getContentLinks(address whichUser, uint256 index) public constant returns (string) {
        return userIndex[whichUser].contentLinks[index];
    }
}
