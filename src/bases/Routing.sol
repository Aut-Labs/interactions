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

    error NullAddressError();

    error HandleKeyMissmatchError();

    function castAsKey(string memory handle) external view returns (bytes32);

    function resolveFor(bytes32 key) external view returns (address);

    function createLink(address resource, bytes32 key, string calldata handle) external;
}

contract BasicRouter is IBasicRouter, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 internal immutable _ARTEFACT;
    mapping(bytes32 discoveryKey => address linkedResource) internal _routes;

    constructor(address initialOperatorManager) {
        if (initialOperatorManager == address(0)) {
            revert NullAddressError();
        }

        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE);
        _grantRole(MANAGER_ROLE, initialOperatorManager);
        _grantRole(OPERATOR_ROLE, initialOperatorManager);

        _ARTEFACT = keccak256(
            abi.encodePacked(
                string.concat(
                    string.concat(__NAMESPACE, __CONTRACT),
                    string(abi.encodePacked(block.chainid, block.number, msg.sender))
                )
            )
        );
    }

    function resolveFor(bytes32 key) external view returns (address) {
        return _routes[key];
    }

    function createLink(address resource, bytes32 key, string calldata handle) external {
        if (key != castAsKey(handle)) {
            revert HandleKeyMissmatchError();
        }
        _checkRole(OPERATOR_ROLE);

        _routes[key] = resource;
        emit RouteSaved(msg.sender, resource, key, handle);
    }

    function castAsKey(string memory handle) public view returns (bytes32) {
        return keccak256(abi.encode(_ARTEFACT, handle));
    }

    string private constant __NAMESPACE = "urn:autlabs:contracts:";
    string private constant __CONTRACT = "interactions:router_v1_basic";
}

contract _RouterBase {
    bytes32 private constant _SLOT =
        keccak256(
            abi.encode(
                (uint256(keccak256("urn:autlabs:contracts:system:proxy:router_slot")) - 1) &
                    ~uint256(0xff)
            )
        );

    struct TLocation {
        address val;
    }

    function _readSlot() internal pure returns (TLocation storage location) {
        bytes32 slot = _SLOT;
        assembly {
            location.slot := slot
        }
    }

    function router() external view returns (address result) {
        return _readSlot().val;
    }
}
