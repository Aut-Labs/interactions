//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {
    ERC721Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    ERC721URIStorageUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract InteractionFactoryErrorHelper {
    error InitialManagerEmptyError();
    error TransferUnallowedError();
    error MetadataURIEmptyError();
}

contract InteractionFactory is
    InteractionFactoryErrorHelper,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable
{
    event InteractionURIUpdated(
        address indexed sender,
        uint256 indexed interactionId,
        string uri
    );
    event InteractionMinted(address indexed sender, uint256 interactionId);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public isNonTransferable = false;
    mapping(uint256 interactionId => uint64 timestamp) public mintedAt;

    function initialize(address initialManager) public initializer {
        if (address(initialManager) == address(0)) {
            revert InitialManagerEmptyError();
        }
        __ERC721_init("InteractionFactory", "IF");
        _setRoleAdmin(MINTER_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialManager);
        _grantRole(MINTER_ROLE, initialManager);
    }

    function mintInteraction(
        address to,
        uint256 interactionId,
        string memory uri
    ) external {
        _checkRole(MINTER_ROLE);
        _mint(to, interactionId);
        _setInteractionURI(interactionId, uri);
        mintedAt[interactionId] = uint64(block.timestamp);
        emit InteractionMinted(to, interactionId);
    }

    function updateInteractionURI(uint256 interactionId, string memory uri) external {
        if (bytes(uri).length == 0) {
            revert MetadataURIEmptyError();
        }
        address owner = _ownerOf(interactionId);
        _checkAuthorized(owner, msg.sender, interactionId);
        _setInteractionURI(interactionId, uri);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, IERC721) {
        if (isNonTransferable) {
            revert TransferUnallowedError();
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return (ERC721URIStorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId));
    }

    function _setInteractionURI(uint256 interactionId, string memory uri) internal {
        _setTokenURI(interactionId, uri);
        emit InteractionURIUpdated(msg.sender, interactionId, uri);
    }
}
