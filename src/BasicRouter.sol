// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IBasicRouter {
    event RouteSaved(
        address indexed operator,
        address indexed service,
        bytes32 indexed key,
        string handle
    );

    function castHandleToKey(string memory handle) external view returns (bytes32);

    function resolveFor(bytes32 key) external view returns (address);

    function createLink(address resource, bytes32 key, string calldata handle) external;
}

contract BasicRouter is IBasicRouter, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 internal immutable _artefact;
    mapping(bytes32 => address) internal _routes;

    constructor(address initialOperatorManager) {
        require(initialOperatorManager != address(0));

        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialOperatorManager);
        _grantRole(OPERATOR_ROLE, initialOperatorManager);

        _artefact = keccak256(
            abi.encodePacked(
                string.concat(
                    string.concat(__NAMESPACE, __CONTRACT),
                    string(
                        abi.encodePacked(
                            block.chainid,
                            block.number,
                            msg.sender,
                            tx.gasprice
                        )
                    )
                )
            )
        );
    }

    function resolveFor(bytes32 key) external view returns (address) {
        return _routes[key];
    }

    function createLink(address resource, bytes32 key, string calldata handle) external {
        require(key == castHandleToKey(handle));
        _checkRole(OPERATOR_ROLE);
        _routes[key] = resource;
        emit RouteSaved(msg.sender, resource, key, handle);
    }

    function castHandleToKey(string memory handle) public view returns (bytes32) {
        return keccak256(abi.encode(_artefact, handle));
    }

    string private constant __NAMESPACE = "urn:autlabs:contracts";
    string private constant __CONTRACT = "::interactions:router_v1-alpha";
}
