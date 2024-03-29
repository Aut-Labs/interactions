// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IInteractionRegistry {
    event InteractionTypeCreated(
        bytes32 interactionId,
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    );

    struct TInteractionData {
        uint16 chainId;
        address recipient;
        bytes4 functionSelector;
    }

    function interactionDataFor(bytes32) external view returns (uint16, address, bytes4);
}

contract InteractionRegistry is IInteractionRegistry, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(bytes32 interactionId => TInteractionData data) internal _interactionDataFor;
    bytes32 internal constant INTERACTION_DATA_TYPEHASH =
        keccak256("TInteractionData(uint16 chainId,address recipient, bytes4 functionSelector)");

    constructor(address initialOperatorManager) {
        require(initialOperatorManager != address(0), "should set initial manager");

        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialOperatorManager);
        _grantRole(OPERATOR_ROLE, initialOperatorManager);
    }

    function interactionDataFor(bytes32 key) external view returns (uint16, address, bytes4) {
        require(key != bytes32(0));
        TInteractionData memory interactionData = _interactionDataFor[key];
        return (
            interactionData.chainId,
            interactionData.recipient,
            interactionData.functionSelector
        );
    }

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

    function registerInteractionId(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) external {
        _checkRole(OPERATOR_ROLE);
        require(chainId != 0, "invalid chain id");
        require(recipient != address(0), "invalid recipient");

        TInteractionData memory data = TInteractionData({
            chainId: chainId,
            recipient: recipient,
            functionSelector: functionSelector
        });
        bytes32 interactionId = _calcInteractionIdFor(data);
        require(_interactionDataFor[interactionId].chainId != 0, "already exists");

        _interactionDataFor[interactionId] = data;

        emit InteractionTypeCreated(
            interactionId,
            chainId,
            data.recipient,
            data.functionSelector
        );
    }

    /// @dev A helper utility for calculating interaction data hash
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
}
