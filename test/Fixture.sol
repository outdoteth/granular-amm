// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "./MockERC721.sol";

contract Fixture is Test {
    Factory public f;
    MockERC721 public bayc;

    constructor() {
        f = new Factory();
        bayc = new MockERC721("fake bayc", "fbayc");
    }
}
