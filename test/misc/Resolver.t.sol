// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StdCheats} from "forge-std/src/StdCheats.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IResolver, Resolver} from "../../src/misc/Resolver.sol";

contract ResolverTest is PRBTest, StdCheats {
    IResolver internal resolver;
    address internal stranger;
    address internal operator;
    address internal resource;

    function setUp() public virtual {
        resolver = IResolver(address(new Resolver(address(this))));
        stranger = address(0x1);
        operator = address(0x2);
        IAccessControl(address(resolver)).grantRole(resolver.OPERATOR_ROLE(), operator);
    }

    function testFuzz_unknownKeyResolvesToZeroAddress(bytes32 key) public virtual {
        vm.assume(key != bytes32(0));
        assertEq(resolver.resolve(key), address(0));
    }

    function test_createLinkSuccess() public virtual {
        string memory handle = "abacaba";
        bytes32 key = resolver.castHandleToKey(handle);
        assertEq(resolver.resolve(key), address(0));
        resolver.createLink(resource, key, handle);
        assertEq(resolver.resolve(key), resource);
    }

    function testFail_createLinkKeyHandleMissmatch() public virtual {
        string memory handle = "some handle";
        string memory anotherHandle = "another handle";
        bytes32 key = resolver.castHandleToKey(handle);
        resolver.createLink(resource, key, anotherHandle);
    }

    function testFail_createLinkByStranger() public virtual {
        string memory handle = "some handle";
        bytes32 key = resolver.castHandleToKey(handle);
        vm.prank(stranger);
        resolver.createLink(resource, key, handle);
    }
}
