// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StdCheats} from "forge-std/src/StdCheats.sol";

import {IInteractionRegistry, InteractionRegistry} from "../src/InteractionRegistry.sol";

contract InteractionRegistryTest is PRBTest, StdCheats {
    IInteractionRegistry internal subj;

    function setUp() public virtual {
        subj = IInteractionRegistry(address(new InteractionRegistry(address(this))));
    }

    function testFuzz_registerInteractionId(
        uint16 chainId,
        bytes4 functionSelector,
        address recipient
    ) public virtual {
        vm.assume(chainId != 0);
        vm.assume(recipient != address(0));
        subj.registerInteractionId(chainId, recipient, functionSelector);
    }

    function testFail_duplicateRegisterInteractionId() public virtual {
        uint16 chainId = 1;
        address recipient = address(this);
        bytes4 functionSelector = 0xffffffff;
        subj.registerInteractionId(chainId, recipient, functionSelector);
        subj.registerInteractionId(chainId, recipient, functionSelector);
    }

    function testFail_invalidChainIdRegisterInteractionId() public virtual {
        uint16 chainId = 0; // !
        address recipient = address(this);
        bytes4 functionSelector = 0xffffffff;
        subj.registerInteractionId(chainId, recipient, functionSelector);
    }

    function testFail_invalidRecipientRegisterInteractionId() public virtual {
        uint16 chainId = 1;
        address recipient = address(0); // !
        bytes4 functionSelector = 0xffffffff;
        subj.registerInteractionId(chainId, recipient, functionSelector);
    }

    function testFuzz_interactionDataFor(
        uint16 chainId,
        address recipient,
        bytes4 functionSelector
    ) public virtual {
        vm.assume(chainId != 0);
        vm.assume(recipient != address(0));
        subj.registerInteractionId(chainId, recipient, functionSelector);
        bytes32 interactionId = subj.predictInteractionId(
            chainId,
            recipient,
            functionSelector
        );
        assertNotEq(interactionId, bytes32(0));
        (uint16 dChainId, address dRecipient, bytes4 dFunctionSelector) = subj
            .interactionDataFor(interactionId);
        assertEq(dChainId, chainId);
        assertEq(dRecipient, recipient);
        assertEq(dFunctionSelector, functionSelector);
    }

    function testFuzz_AccessControlRegisterInteractionId(address sender) public virtual {
        vm.assume(sender != address(0));
        vm.assume(sender != address(this));
        vm.expectRevert();
        vm.prank(sender);
        subj.registerInteractionId(1, address(this), 0xffffffff);
    }
}
