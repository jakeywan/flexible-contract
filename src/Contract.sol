// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDescriptor.sol";
import { Base64 } from 'base64-sol/base64.sol';

contract FlexibleContract is Ownable, ERC721 {
    using Strings for uint256;

    // mint count tokenId tracker
    uint256 public nextTokenId;

    // OpenSea and others will pick this up, indicates metadata is frozen
    event PermanentURI(string _value, uint256 indexed _id);

    struct OnChainData {
        string image; // this will be base64 encoded and inserted into json
        string jsonKeyValues; // this be base64 encoded again, do not include brackets
    }

    struct TokenData {
        address descriptor; // optional contract address which stores tokenURI details
        string tokenURI; // optional URL to point to
        bool isOnChain; // whether the tokenURI info should be fetched from `onChainData` mapping
    }

    // array of token data
    TokenData[] public tokens;

    // mapping of on chain token data (if applicable) by tokenId
    mapping(uint256 => OnChainData) public onChainData;

    // mapping of whether token metadata is frozen. putting this here instead of
    // in struct so a token isn't accidentally initialized with frozen metadata.
    mapping(uint256 => bool) public isFrozen;

    // todo: opensea royalties

    // todo: contractURI for contract/project level details

    // todo: ability for admin to delete an accidentally minted token that is still owned by admin?

    constructor() ERC721("Jan Robert Leegte", "JRL") {}

    /**
     * @dev Return tokenURI directly or via alternative `descriptor` contract
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        TokenData memory token = tokens[tokenId];

        if (token.descriptor != address(0)) {
            return IDescriptor(token.descriptor).tokenURI(tokenId);
        }

        if (token.isOnChain) {
            OnChainData memory data = onChainData[tokenId];
            // base64 encode the image
            string memory image = Base64.encode(bytes(data.image));
            // concat image and rest of json, then base64 encode it
            string memory json = Base64.encode(
                abi.encodePacked('{ "image":"data:image/svg+xml;base64,', image, '",', data.jsonKeyValues,'}')
            );
            // prepend the base64 prefix
            return string(abi.encodePacked('data:application/json;base64,', json));
        }

        return token.tokenURI;
    }

    // ========================== ADMIN FUNCTIONS ==============================
    function mint(
        address descriptor,
        string calldata _tokenURI,
        bool isOnChain,
        string calldata image,
        string calldata jsonKeyValues
    ) external onlyOwner {
        // save token data
        tokens.push(TokenData({
            descriptor: descriptor,
            tokenURI: _tokenURI,
            isOnChain: isOnChain
        }));
        // conditionally save on chain data
        if (isOnChain) {
            onChainData[nextTokenId] = OnChainData({
                image: image,
                jsonKeyValues: jsonKeyValues
            });
        }
        // mint token
        _mint(msg.sender, nextTokenId++);
    }

    function updateTokenData(
        uint256 tokenId,
        address descriptor,
        string calldata _tokenURI,
        bool isOnChain,
        string calldata image,
        string calldata jsonKeyValues
    ) external onlyOwner {
        require(!isFrozen[tokenId], "Metadata frozen");

        tokens[tokenId] = TokenData({
            descriptor: descriptor,
            tokenURI: _tokenURI,
            isOnChain: isOnChain
        });

        if (isOnChain) {
            onChainData[nextTokenId] = OnChainData({
                image: image,
                jsonKeyValues: jsonKeyValues
            });
        } else {
            delete onChainData[tokenId];
        }

    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        // todo: set as frozen
        isFrozen[tokenId] = true;

        // note: is this correct? alerts OpenSea and others
        // todo: update for on chain data
        emit PermanentURI(tokens[tokenId].tokenURI, tokenId);
    }

}