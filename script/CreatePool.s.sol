// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";

contract CreatePoolScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        Factory factory = Factory(vm.envAddress("FACTORY_ADDRESS"));
        bytes32[] memory merkleRoots = generateMerkleRoots(vm.envString("RANKING_FILE"));

        Pool pool = factory.create(vm.envAddress("NFT_ADDRESS"), merkleRoots);
        console.log("pool");
        console.log(address(pool));
    }

    function generateMerkleRoots(string memory rankingFile) public returns (bytes32[] memory) {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "./script/helpers/generate-merkle-roots-cli.js";
        inputs[2] = rankingFile;

        bytes memory res = vm.ffi(inputs);
        bytes32[] memory output = abi.decode(res, (bytes32[]));

        return output;
    }
}
