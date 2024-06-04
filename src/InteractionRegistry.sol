// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title a registry for interactions
interface IInteractionRegistry {
    event InteractionTypeCreated(
        bytes32 indexed interactionId,
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    );

    /// @dev interaction definition data struct
    struct TInteractionData {
        uint16 chainId;
        address recipient;
        bytes4 functionSelector;
    }

    /// @dev calculates interaction id by the given interaction data
    /// @param chainId chain id of the interaction
    /// @param recipient call address (tx to) of the interaction
    /// @param functionSelector 4 bytes of the function selector of the interaction
    /// @return interactionId identifier of the interaction with the given params
    function predictInteractionId(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) external pure returns (bytes32 interactionId);

    /// @dev returns interaction data for the given interaction id
    /// @param interactionId identifier of the interaction
    /// @return chainId chain id of the interaction
    /// @return recipient call address (tx to) of the interaction
    /// @return functionSelector 4 bytes of the function selector of the interaction
    function interactionDataFor(
        bytes32 interactionId
    ) external view returns (uint16 chainId, address recipient, bytes4 functionSelector);

    /// @dev registeres interaction type by the given interaction data
    /// @param chainId chain id of the interaction
    /// @param recipient call address (tx to) of the interaction
    /// @param functionSelector 4 bytes of the function selector of the interaction
    function registerInteractionId(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) external;
}

contract InteractionRegistryErrorHelper {
    error InitialManagerEmptyError();
    error KeyEmptyError();
    error InvalidRecipientError();
    error InvalidChainIdError();
    error InteractionAlreadyExistError();
}

contract InteractionRegistry is
    IInteractionRegistry,
    InteractionRegistryErrorHelper,
    AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(bytes32 interactionId => TInteractionData data) internal _interactionDataFor;
    bytes32 internal constant INTERACTION_DATA_TYPEHASH =
        keccak256(
            "TInteractionData(uint16 chainId,address recipient,bytes4 functionSelector)"
        );

    constructor(address initialOperatorManager) {
        if (initialOperatorManager == address(0)) {
            revert InitialManagerEmptyError();
        }

        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialOperatorManager);
        _grantRole(OPERATOR_ROLE, initialOperatorManager);
    }

    /// @inheritdoc IInteractionRegistry
    function interactionDataFor(
        bytes32 key
    ) external view returns (uint16, address, bytes4) {
        if (key == bytes32(0)) {
            revert KeyEmptyError();
        }
        TInteractionData memory interactionData = _interactionDataFor[key];
        return (
            interactionData.chainId,
            interactionData.recipient,
            interactionData.functionSelector
        );
    }

    /// @inheritdoc IInteractionRegistry
    function predictInteractionId(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) external pure returns (bytes32) {
        TInteractionData memory data = TInteractionData({
            chainId: chainId,
            recipient: recipient,
            functionSelector: functionSelector
        });
        return _calcInteractionIdFor(data);
    }

    /// @inheritdoc IInteractionRegistry
    function registerInteractionId(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) external {
        _checkRole(OPERATOR_ROLE);
        if (chainId == 0) {
            revert InvalidChainIdError();
        }
        if (recipient == address(0)) {
            revert InvalidRecipientError();
        }

        TInteractionData memory data = TInteractionData({
            chainId: chainId,
            recipient: recipient,
            functionSelector: functionSelector
        });
        bytes32 interactionId = _calcInteractionIdFor(data);
        if (
            // check for non-empty
            _interactionDataFor[interactionId].chainId != 0
        ) {
            revert InteractionAlreadyExistError();
        }

        _interactionDataFor[interactionId] = data;

        emit InteractionTypeCreated(
            interactionId,
            chainId,
            data.recipient,
            data.functionSelector
        );
    }

    /// @dev a helper utility for calculating interaction data hash
    function _calcInteractionIdFor(
        TInteractionData memory data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    INTERACTION_DATA_TYPEHASH,
                    data.chainId,
                    data.recipient,
                    data.functionSelector
                )
            );
    }

    uint256[50] private __gap;
}
