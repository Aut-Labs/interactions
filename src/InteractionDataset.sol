// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IInteractionDataset {
    event MerkleRootUpdated(
        address indexed relayer,
        bytes32 merkleRoot,
        bytes32 proofsHash
    );

    function MANAGER_ROLE() external pure returns (bytes32);
    function RELAYER_ROLE() external pure returns (bytes32);

    function merkleRoot() external view returns (bytes32);
    function proofsHash() external view returns (bytes32);
    function updatedAt() external view returns (uint64);
    function epoch() external view returns (uint32);

    function hasEntry(
        bytes32 txId,
        bytes32 interactionId,
        bytes32[] memory hashedPairsProof
    ) external view returns (bool);

    function updateRoot(bytes32 nextMerkleRoot, bytes32 nextProofsHash) external;
}

abstract contract InteractionDatasetErrorHelper {
    error InitialManagerEmptyError();
}

contract InteractionDataset is
    IInteractionDataset,
    InteractionDatasetErrorHelper,
    AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    bytes32 public merkleRoot;
    bytes32 public proofsHash;

    uint64 public updatedAt;
    uint32 public epoch;

    constructor(address initialRelayerManager) {
        if (initialRelayerManager == address(0)) {
            revert InitialManagerEmptyError();
        }
        _setRoleAdmin(RELAYER_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialRelayerManager);
        _grantRole(RELAYER_ROLE, initialRelayerManager);
    }

    function hasEntry(
        bytes32 txId,
        bytes32 interactionId,
        bytes32[] calldata hashedPairsProof
    ) external view returns (bool) {
        return
            MerkleProof.verifyCalldata(
                hashedPairsProof,
                keccak256(abi.encodePacked(txId, ":", interactionId)),
                merkleRoot
            );
    }

    function updateRoot(bytes32 nextMerkleRoot, bytes32 nextProofsHash) external {
        _checkRole(RELAYER_ROLE);

        merkleRoot = nextMerkleRoot;
        proofsHash = nextProofsHash;
        updatedAt = uint64(block.timestamp);
        ++epoch;

        emit MerkleRootUpdated(msg.sender, nextMerkleRoot, nextProofsHash);
    }
}
