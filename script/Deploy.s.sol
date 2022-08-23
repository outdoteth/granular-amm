// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        Factory factory = new Factory();
        console.log("factory");
        console.log(address(factory));
    }
}
