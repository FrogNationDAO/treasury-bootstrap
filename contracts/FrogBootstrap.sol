pragma solidity ^0.8.7;

import "./ERC721/CustomERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FrogBootstrap is CustomERC721Metadata, Ownable {
    using SafeMath for uint256;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId

    );

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        bool dynamic;
        string projectBaseURI;
        string projectBaseIpfsURI;
        uint256 invocations;
        uint256 maxInvocations;
        string ipfsHash;
        bool useHashString;
        bool useIpfs;
        bool active;
        bool locked;
        bool paused;
        bool whitelist;
        mapping(address => bool) isMintWhitelisted;
    }

    address public frogBootstrapAddress;
    uint256 public frogBootstrapPercentage = 20;
    uint256 public nextProjectId = 0;

    uint256 constant ONE_MILLION = 1_000_000;

    mapping(uint256 => Project) projects;

    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => string) public projectIdToCurrencySymbol;
    mapping(uint256 => address) public projectIdToCurrencyAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;
    mapping(uint256 => address) public projectIdToAdditionalPayee;
    mapping(uint256 => uint256) public projectIdToAdditionalPayeePercentage;
    mapping(uint256 => uint256) public projectIdToSecondaryMarketRoyaltyPercentage;

    mapping(uint256 => string) public staticIpfsImageLink;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256[]) internal projectIdToTokenIds;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    mapping(address => bool) public isWhitelisted;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) CustomERC721Metadata(_name, _symbol) {
        isWhitelisted[msg.sender] = true;
        frogBootstrapAddress = msg.sender;
    }

    function mint(address _to, uint256 _projectId, address _by) external returns (uint256 _tokenId) {
        require(
            projects[_projectId].whitelist && projects[_projectId].isMintWhitelisted[msg.sender],
            "Must mint from whitelisted minter contract."
        );
        require(projects[_projectId].invocations.add(1) <= projects[_projectId].maxInvocations, "Must not exceed max invocations");
        require(projects[_projectId].active || _by == projectIdToArtistAddress[_projectId], "Project must exist and be active");
        require(!projects[_projectId].paused || _by == projectIdToArtistAddress[_projectId], "Purchases are paused.");

        return _mintToken(_to, _projectId);
    }

    function _mintToken(address _to, uint256 _projectId) internal returns (uint256) {
        uint256 upcomingToken = (_projectId * ONE_MILLION) + projects[_projectId].invocations;
        projects[_projectId].invocations = projects[_projectId].invocations.add(1);

        bytes32 hash = keccak256(
            abi.encodePacked(
                projects[_projectId].invocations,
                block.number,
                blockhash(block.number - 1),
                msg.sender)
        );

        tokenIdToHash[upcomingToken] = hash;
        hashToTokenId[hash] = upcomingToken;

        super._mint(_to, upcomingToken);

        tokenIdToProjectId[upcomingToken] = _projectId;
        projectIdToTokenIds[_projectId].push(upcomingToken);

        emit Mint(_to, upcomingToken, _projectId);

        return upcomingToken;
    }

    function updateFrogBootstrap(address _frogBootstrap) public onlyOwner {
        frogBootstrapAddress = _frogBootstrap;
    }
}
