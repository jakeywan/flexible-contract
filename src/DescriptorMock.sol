// SPDX-License-Identifier: GPL-3.0

/// @title Mock Descriptor
/// @notice For testing purposes only

pragma solidity ^0.8.17;

import "./interfaces/IDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract DescriptorMock is IDescriptor {
    using Strings for uint256;

    /**
     * @dev To demo alternative rendering contract
     */
    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked("https://descriptor-example.com/", tokenId.toString()));
    }

}