pragma solidity ^0.4.24;

contract UserContentRegisterInterface {
    function getUserContentBytes(address whichUser, uint256 index) public constant returns (bytes32, bytes32);
    function getNumContent(address whichUser) public constant returns (uint256);
}

contract StringBytes32UtilInterface {
    function stringToBytes32Tuple(string data) public constant returns (bytes32, bytes32);
    function bytes32TupleToString(bytes32 one, bytes32 two) public pure returns (string);
}

contract PublicationRegister {

    struct Publication {
        string name;
        string metaData; //json, image urls, description, etc
        address admin;
        bool open;

        mapping (address => bool) publishingAccessList;

        uint256 numPublished;
        mapping (uint256 => address) publishedAuthorIndex;
        mapping (uint256 => uint256) publishedPostIndex;
        mapping (uint256 => string) publishedContentIndex;

        uint256 minSupportCostWei;
        uint8 adminPaymentPercentage;
        uint256 uniqueSupporters;
        uint256 adminClaimOwedWei;

        mapping (address => uint256) authorClaimsOwedWei;
        mapping (uint256 => uint256) postRevenueWeiIndex;
        mapping (uint256 => uint32) postUniqueSupportersIndex;
        mapping (uint256 => mapping (address => bool)) trackPostSupporters;
        mapping (uint256 => mapping (uint256 => address)) postCommentAddresses;
        mapping (uint256 => mapping (uint256 => string)) postComments;
        mapping (uint256 => uint256) numCommentsIndex;
        mapping (address => bool) trackPublicationSupporters;
    }

    mapping (uint256 => Publication) public publicationIndex;
    mapping (string => bool) _checkNameTaken;
    mapping (string => uint256) indexLookup;
    uint256 public numPublications;

    UserContentRegisterInterface public userContentRegister;
    StringBytes32UtilInterface stringBytes32Util;

    event StoreData(string data, address author, uint256 whichPublication);

    constructor(address userContentRegisterAddress, address stringBytes32UtilAddress) public {
        numPublications = 0;
        userContentRegister = UserContentRegisterInterface(userContentRegisterAddress);
        stringBytes32Util = StringBytes32UtilInterface(stringBytes32UtilAddress);
    }

    function checkNameTaken(string name) public constant returns (bool) {
        return _checkNameTaken[name];
    }

    function getPublicationIndex(string name) public constant returns (uint256) {
        return indexLookup[name];
    }

    function createPublication(string name, string metaData, uint256 minUpVoteCostWei, uint8 adminPaymentPercentage) public {
        assert(!_checkNameTaken[name]);
        publicationIndex[numPublications] = Publication(name, metaData, msg.sender, numPublications == 0, 0, minUpVoteCostWei, adminPaymentPercentage, 0, 0);
        publicationIndex[numPublications].publishingAccessList[msg.sender] = true;
        _checkNameTaken[name] = true;
        indexLookup[name] = numPublications;
        numPublications++;
    }

    function publishContent(uint256 whichPublication, uint256 index) public returns (uint256) {
        assert(index < userContentRegister.getNumContent(msg.sender));
        Publication storage p = publicationIndex[whichPublication];
        if (p.open || p.publishingAccessList[msg.sender]) {
            p.publishedAuthorIndex[p.numPublished] = msg.sender;
            p.publishedPostIndex[p.numPublished] = index;
            var (contentOne, contentTwo) = getContentBytesFromUserContentRegister(msg.sender, index);
            p.publishedContentIndex[p.numPublished] = stringBytes32Util.bytes32TupleToString(contentOne, contentTwo);
            p.numPublished++;
            emit StoreData(p.publishedContentIndex[p.numPublished - 1], msg.sender, whichPublication);
            return p.numPublished;
        }
        return 0;
    }

    function permissionAuthor(uint256 whichPublication, address author, bool giveAccess) public {
        Publication storage p = publicationIndex[whichPublication];
        if (msg.sender == p.admin) {
            p.publishingAccessList[author] = giveAccess;
        }
    }

    function updateMetaData(uint256 whichPublication, string metaData) public {
        Publication storage p = publicationIndex[whichPublication];
        if (msg.sender == p.admin) {
            p.metaData = metaData;
        }
    }

    function decreaseAdminPaymentPercentage(uint256 whichPublication, uint8 newAdminPaymentPercentage) public {
        Publication storage p = publicationIndex[whichPublication];
        if (msg.sender == p.admin && newAdminPaymentPercentage < p.adminPaymentPercentage) {
            p.adminPaymentPercentage = newAdminPaymentPercentage;
        }
    }

    function supportPost(uint256 whichPublication, uint256 postIndex, string optionalComment) public payable returns (bool) {
        Publication storage p = publicationIndex[whichPublication];
        if (msg.value < p.minSupportCostWei) {
            msg.sender.transfer(msg.value);
            return false;
        } else {
            uint256 weiToAdmin = msg.value / 100 * p.adminPaymentPercentage;
            uint256 weiToAuthor = msg.value - weiToAdmin;
            p.adminClaimOwedWei += weiToAdmin;
            p.authorClaimsOwedWei[p.publishedAuthorIndex[postIndex]] += weiToAuthor;
            p.postRevenueWeiIndex[postIndex] += msg.value;
            if (!p.trackPostSupporters[postIndex][msg.sender]) {
                p.trackPostSupporters[postIndex][msg.sender] = true;
                p.postUniqueSupportersIndex[postIndex]++;
            }
            if (!p.trackPublicationSupporters[msg.sender]) {
                p.trackPublicationSupporters[msg.sender] = true;
                p.uniqueSupporters++;
            }
	    bytes memory commentBytes = bytes(optionalComment);
            if (commentBytes.length != 0) {
                p.postComments[postIndex][p.numCommentsIndex[postIndex]] = optionalComment;
                p.postCommentAddresses[postIndex][p.numCommentsIndex[postIndex]] = msg.sender;
                p.numCommentsIndex[postIndex]++;
            }
            return true;
        }

    }

    function withdrawAdminClaim(uint256 whichPublication) public {
        if (msg.sender == publicationIndex[whichPublication].admin) {
            uint256 owed = publicationIndex[whichPublication].adminClaimOwedWei;
            publicationIndex[whichPublication].adminClaimOwedWei = 0;
            msg.sender.transfer(owed);
        }
    }

    function checkAuthorClaim(uint256 whichPublication, address author) public constant returns (uint256) {
        return publicationIndex[whichPublication].authorClaimsOwedWei[author];
    }

    function withdrawAuthorClaim(uint256 whichPublication) public {
        uint256 owed = publicationIndex[whichPublication].authorClaimsOwedWei[msg.sender];
        publicationIndex[whichPublication].authorClaimsOwedWei[msg.sender] = 0;
        msg.sender.transfer(owed);
    }
    
    function getContentBytesFromUserContentRegister(address user, uint256 index) private constant returns (bytes32, bytes32) {
        return userContentRegister.getUserContentBytes(user, index);
    }
    
    function getContentBytes(uint256 whichPublication, uint256 contentIndex) public constant returns (bytes32, bytes32) {
        Publication storage p = publicationIndex[whichPublication];
        return stringBytes32Util.stringToBytes32Tuple(p.publishedContentIndex[contentIndex]);
    }

    function getContent(uint256 whichPublication, uint256 contentIndex) public constant returns (string) {
         Publication storage p = publicationIndex[whichPublication];
         return p.publishedContentIndex[contentIndex];
    }

    function getContentRevenue(uint256 whichPublication, uint256 contentIndex) public constant returns (uint256) {
        Publication storage p = publicationIndex[whichPublication];
        return p.postRevenueWeiIndex[contentIndex];
    }

    function getContentUniqueSupporters(uint256 whichPublication, uint256 contentIndex) public constant returns (uint256) {
        Publication storage p = publicationIndex[whichPublication];
        return p.postUniqueSupportersIndex[contentIndex];
    }

    function getContentNumComments(uint256 whichPublication, uint256 contentIndex) public constant returns (uint256) {
        Publication storage p = publicationIndex[whichPublication];
        return p.numCommentsIndex[contentIndex];
    }

    function getContentCommentByIndex(uint256 whichPublication, uint256 contentIndex, uint256 commentIndex) public constant returns (string) {
        Publication storage p = publicationIndex[whichPublication];
        return p.postComments[contentIndex][commentIndex];
    }

    function getContentAuthor(uint256 whichPublication, uint256 contentIndex) public constant returns (address) {
        Publication storage p = publicationIndex[whichPublication];
        return p.publishedAuthorIndex[contentIndex];
    }

    function getNumPublished(uint256 whichPublication) public constant returns (uint256) {
        return publicationIndex[whichPublication].numPublished;
    }

    function getAdmin(uint256 whichPublication) public constant returns (address) {
        return publicationIndex[whichPublication].admin;
    }
}
