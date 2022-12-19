// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDescriptor.sol";
import { Base64 } from 'base64-sol/base64.sol';

contract Contract is Ownable, ERC721 {
    using Strings for uint256;

    // mint count tokenId tracker
    uint256 public nextTokenId;

    // OpenSea and others will pick this up, indicates metadata is frozen
    event PermanentURI(string _value, uint256 indexed _id);

    /**
     * @dev specifies the type of URI requested for a string
     * @param SVG will append 'data:image/svg+xml;base64,' before base64 encoding this value
     * @param HTML will append 'data:text/html;base64,' before base64 encoding this value
     * @param URL will not do any transformations. pass a plain URL string or a data URI
     * that is already properly encoded
     */
    enum UriType { SVG, HTML, URL }

    /**
     * @dev only added for a token id if it is specified as `isOnChain`
     * @param image a plain string of the on chain work, either SVG, HTML, or
     * a wildcard data type (in which case uploader must handle base64 encoding)
     * @param imageUriType specifies how the dataURI should be constructed. if wildcard,
     * the dataURI must be appended as part of the artwork
     * @param animationUrl optional value that may also be an on chain work
     * @param animationUrlUriType data type of the optional animationUrl
     * @param jsonKeyValues DO NOT INCLUDE CURLY BRACKETS, just the key-values.  the
     * brackets will be appended by the contract.
     */
    struct OnChainData {
        string image;
        UriType imageUriType;
        string animationUrl;
        UriType animationUrlUriType;
        string jsonKeyValues;
    }

    /**
     * @dev specifies metadata for each individual token
     * @param descriptor optional. contract address which stores tokenURI details
     * @param tokenURI optional. plain off-chain URL to point to
     * @param isOnChain whether the tokenURI info should be fetched from `onChainData`,
     * or whether the tokenURI param should be used.
     */
    struct TokenData {
        address descriptor;
        string tokenURI;
        bool isOnChain;
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
            string memory image = buildURI(data.image, data.imageUriType);
            image = string(abi.encodePacked('"image":"', image, '"'));
            // check if animationUrl exists for this token, and if so process it
            string memory animationUrl;
            if (bytes(data.animationUrl).length != 0) {
                animationUrl = buildURI(data.animationUrl, data.animationUrlUriType);
                image = string(abi.encodePacked(',', image, '"animation_url":', animationUrl, '"'));
            }
            string memory json;
            if (bytes(data.jsonKeyValues).length != 0) {
                // concat image and rest of json, then base64 encode it
                json = Base64.encode(
                    abi.encodePacked('{',
                    image,
                    ',',
                    data.jsonKeyValues,
                    '}')
                );
            } else {
                // concat image and rest of json, then base64 encode it
                json = Base64.encode(
                    abi.encodePacked('{', image, '}')
                );
            }
            
            // prepend the base64 prefix
            return string(abi.encodePacked('data:application/json;base64,', json));
        }

        return token.tokenURI;
    }

    function buildURI(string memory uriValue, UriType uriType) public pure returns (string memory) {
        if (uriType == UriType.SVG) {
            return string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(uriValue))
                )
            );
        } else if (uriType == UriType.HTML) {
            return string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(bytes(uriValue))
                )
            );
        }
        
        return uriValue;
    }

    // ========================== ADMIN FUNCTIONS ==============================
    function mint(
        TokenData calldata _tokenData,
        OnChainData calldata _onChainData
    ) external onlyOwner {
        // save token data
        tokens.push(_tokenData);
        // conditionally save on chain data
        if (_tokenData.isOnChain) {
            onChainData[nextTokenId] = _onChainData;
        }
        // mint token
        _mint(msg.sender, nextTokenId++);
    }

    function updateTokenData(
        uint256 tokenId,
        TokenData calldata _tokenData,
        OnChainData calldata _onChainData
    ) external onlyOwner {
        require(!isFrozen[tokenId], "Metadata frozen");

        tokens[tokenId] = _tokenData;

        if (_tokenData.isOnChain) {
            onChainData[nextTokenId] = _onChainData;
        } else {
            delete onChainData[tokenId];
        }
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        // set token as frozen
        isFrozen[tokenId] = true;
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

}