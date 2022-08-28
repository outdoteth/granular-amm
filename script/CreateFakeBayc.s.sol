// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "ERC721A/ERC721A.sol";

import "../src/Factory.sol";

contract FakeBayc is ERC721A {
    constructor() ERC721A("Fake Bored Ape Yacht Club", "FBAYC") {}

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", _toString(tokenId)));
    }
}

contract CreateFakeBaycScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        FakeBayc fakeBayc = new FakeBayc();
        console.log("fake bayc:");
        console.log(address(fakeBayc));

        fakeBayc.mint(msg.sender, 250);
        fakeBayc.mint(msg.sender, 250);
        fakeBayc.mint(msg.sender, 250);
        fakeBayc.mint(msg.sender, 250);
        fakeBayc.mint(msg.sender, 250);
        fakeBayc.mint(msg.sender, 250);
    }
}
