// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StdCheats} from "forge-std/src/StdCheats.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IInteractionDataset, InteractionDataset} from "../src/InteractionDataset.sol";

contract InteractionDatasetTest is PRBTest, StdCheats {
    IInteractionDataset internal sub;
    address internal stranger;
    address internal relayer;
    address internal resource;

    function setUp() public virtual {
        sub = IInteractionDataset(address(new InteractionDataset(address(this))));
        stranger = address(0x1);
        relayer = address(0x2);
        IAccessControl(address(sub)).grantRole(sub.RELAYER_ROLE(), relayer);
    }

    function testFails_StrangerUpdateRoot() public virtual {
        vm.prank(stranger);
        sub.updateRoot(keccak256("a"), keccak256("b"));
    }

    function test_relayerCanUpdateRoot() public virtual {
        vm.prank(relayer);
        sub.updateRoot(keccak256("relayer"), keccak256("..."));
    }

    function test_hasEntryFalseOnEmptyDataset() public virtual {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = keccak256("proof0");
        proof[1] = keccak256("proof1");
        bool result = sub.hasEntry(keccak256("a"), keccak256("b"), proof);
        assertEq(result, false);
    }

    // todo: positive test
}
