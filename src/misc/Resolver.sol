// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IResolver {
    event RouteSaved(
        address indexed operator,
        address indexed service,
        bytes32 indexed key,
        string handle
    );

    function castHandleToKey(string memory handle) external view returns (bytes32);

    function resolve(bytes32 key) external view returns (address);

    function createLink(address resource, bytes32 key, string calldata handle) external;
}

abstract contract ResolverErrorHelper {
    error InitialManagerEmptyError();
    error KeyHandleMissmatchError();
}

contract Resolver is IResolver, ResolverErrorHelper, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 internal immutable _KEY_PREFIX;
    mapping(bytes32 key => address resource) internal _routes;

    constructor(address initialOperatorManager) {
        if (initialOperatorManager == address(0)) {
            revert InitialManagerEmptyError();
        }

        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialOperatorManager);
        _grantRole(OPERATOR_ROLE, initialOperatorManager);

        _KEY_PREFIX = keccak256(
            abi.encodePacked(
                string.concat(
                    string.concat(_NAMESPACE_ROOT, ":resolver_v1"),
                    string(abi.encodePacked(block.chainid, block.number, msg.sender))
                )
            )
        );
    }

    function resolve(bytes32 key) external view returns (address) {
        return _routes[key];
    }

    function createLink(address resource, bytes32 key, string calldata handle) external {
        if (key != castHandleToKey(handle)) {
            revert KeyHandleMissmatchError();
        }
        _checkRole(OPERATOR_ROLE);
        _routes[key] = resource;
        emit RouteSaved(msg.sender, resource, key, handle);
    }

    function castHandleToKey(string memory handle) public view returns (bytes32) {
        return keccak256(abi.encode(_KEY_PREFIX, handle));
    }

    string private constant _NAMESPACE_ROOT = "urn:autlabs:contracts:interactions";
}
