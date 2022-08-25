// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "../src/Factory.sol";

contract CreatePoolScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Factory factory = Factory(vm.envAddress("FACTORY_ADDRESS"));
        bytes32[] memory merkleRoots = generateMerkleRoots(vm.envString("RANKING_FILE"));

        Pool pool = factory.create(vm.envAddress("NFT_ADDRESS"), merkleRoots);
        console.log("pool:");
        console.log(address(pool));

        // sanity check the proof verification
        uint256 tokenId = 4;
        bytes32[] memory merkleProof = generateMerkleProof(vm.envString("RANKING_FILE"), tokenId);
        Pool.SubpoolToken memory token = Pool.SubpoolToken({tokenId: tokenId, proof: merkleProof});

        bool validatesAgainstOneSubpool = false;
        for (uint256 i = 0; i < pool.subpoolCount(); i++) {
            validatesAgainstOneSubpool = pool.validateSubpoolToken(token, pool.subpools(i).merkleRoot);
            if (validatesAgainstOneSubpool) {
                break;
            }
        }

        require(validatesAgainstOneSubpool, "Did not validate");
    }

    function generateMerkleRoots(string memory rankingFile) public returns (bytes32[] memory) {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "./script/helpers/generate-merkle-root/generate-merkle-roots-cli.js";
        inputs[2] = rankingFile;

        bytes memory res = vm.ffi(inputs);
        bytes32[] memory output = abi.decode(res, (bytes32[]));

        return output;
    }

    function generateMerkleProof(string memory rankingFile, uint256 tokenId) public returns (bytes32[] memory) {
        string[] memory inputs = new string[](4);

        inputs[0] = "node";
        inputs[1] = "./script/helpers/generate-merkle-proof/generate-merkle-proof-cli.js";
        inputs[2] = rankingFile;
        inputs[3] = Strings.toString(tokenId);

        bytes memory res = vm.ffi(inputs);
        bytes32[] memory output = abi.decode(res, (bytes32[]));

        return output;
    }
}
