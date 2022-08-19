// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/Pool.sol";
import "./Fixture.sol";

contract FactoryTest is Fixture {
    function setUp() public {}

    function testItCreatesPool() public {
        // arrange
        uint256 merkleRootCount = 5;
        bytes32[] memory merkleRoots = new bytes32[](merkleRootCount);
        for (uint256 i = 0; i < merkleRootCount; i++) {
            merkleRoots[i] = keccak256(abi.encode(i));
        }

        // act
        Pool p = f.create(address(bayc), merkleRoots);

        // assert
        for (uint256 i = 0; i < merkleRootCount; i++) {
            Pool.Subpool memory subpool = p.subpools(i);
            assertEq(subpool.merkleRoot, merkleRoots[i], "Should have set merkle root");
        }
    }
}
