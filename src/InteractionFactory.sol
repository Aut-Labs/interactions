// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {
    ERC721URIStorage,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract InteractionFactory is ERC721URIStorage, AccessControl, _Base(address(0)) {
    struct TTokenData {
        uint64 mintedAt;
        bytes32 interactionType;
        string metadataUri;
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public tokenId;
    mapping(uint256 tokenId => TTokenData $) internal _tokenDataFor;

    constructor(address initialMinterManager) ERC721("{symbol}", "{name}") {
        require(initialMinterManager != address(0), "should set initial owner");

        _setRoleAdmin(MINTER_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialMinterManager);
        _grantRole(MINTER_ROLE, initialMinterManager);
    }

    function mintInteractionType(
        IInteractionRegistry.TInteractionData memory data,
        string memory metadataUri_
    ) external {
        IInteractionRegistry interactionRegistry = IInteractionRegistry(
            _discover(INTERACTION_REGISTRY)
        );
        interactionRegistry.createInteractionType(
            data.chainId,
            data.recipient,
            data.functionSelector
        );
        bytes32 interactionType_ = interactionRegistry.interactionType(
            data.chainId,
            data.recipient,
            data.functionSelector
        );

        uint256 tokenId_ = ++tokenId;
        _mint(msg.sender, tokenId_);
        tokenDataFor[tokenId_] = TokenData({
            mintedAt: block.timestamp,
            interactionType: interactionType_,
            metadataUri: metadataUri_
        });

        emit InteractionTypeNftMinted(msg.sender, tokenId_, interactionType_, metadataUri_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return (ERC721URIStorage.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId));
    }
}
