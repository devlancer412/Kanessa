//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Kanessa is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    bool private _whitelistActive;
    bytes32 private _root;

    string private _strBaseTokenURI;

    event WhitelistModeChanged(bool isWhiteList);
    event MintNFT(address indexed _to, uint256 _number);

    constructor() ERC721("Kanessa(Plus size lady)", "PSL") {
        _root = 0xb61a434330b5956117e2e80034ecd767041666f59bb627bfd46d8c01f1a7f70b;
        _strBaseTokenURI = "https://gateway.pinata.cloud/ipfs/Qmdbpbpy7fA99UkgusTiLhMWzyd3aETeCFrz7NpYaNi6zY/";
        _whitelistActive = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return _strBaseTokenURI;
    }

    function totalCount() public pure returns (uint256) {
        return 1000;
    }

    function price(bool verified) public view returns (uint256) {
        if (verified && _whitelistActive) {
            return 2 * 10**16;
        }

        return 5 * 10**16;
    }

    function safeMint(address to, uint256 number) public onlyOwner {
        for (uint256 i = 0; i < number; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }

        emit MintNFT(to, number);
        // _setTokenURI(tokenId, tokenURI(tokenId));
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function payToMint(address recipiant, uint256 number) public payable {
        require(!_whitelistActive, "Can't mint in presale!");
        require(msg.value >= price(false) * number, "Need to pay up!");

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function payToWhiteMint(
        address recipiant,
        bytes32[] memory proof,
        uint256 number
    ) public payable {
        require(_whitelistActive, "Finished presale!");

        bool isWhitelisted = verifyWhitelist(_leaf(recipiant), proof);

        require(isWhitelisted, "Not whitelisted");

        require(msg.value >= price(true) * number, "Need to pay up!");

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function verifyWhitelist(bytes32 leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == _root;
    }

    function whitelistRoot() external view returns (bytes32) {
        return _root;
    }

    function setWhitelistRoot(bytes32 root) external {
        _root = root;
    }

    function whitelistMode() external view returns (bool) {
        return _whitelistActive;
    }

    function setWhiteListMode(bool mode) external {
        _whitelistActive = mode;

        emit WhitelistModeChanged(mode);
    }
}
