// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";

// todo: erc721a + tokenuri for bayc
contract FakeBayc {}

contract CreateFakeBaycScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        // mint 7000 to me
        // mint 1000 to x
        // mint 1000 to y
    }
}
