// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";
import "../src/Pool.sol";
import "./Fixture.sol";


contract AddTest is Fixture {
    Pool public p;

    function setUp() public {
        bytes32 root = m.getRoot(tokenIdData);
        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = root;
        
        p = f.create(address(bayc), merkleRoots);
        bayc.setApprovalForAll(address(p), true);
    }

    function testItInitsLiquidity() public {
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens= new Pool.SubpoolToken[](1);
       
        subpoolTokens[0] = Pool.SubpoolToken({
            tokenId: 1,
            proof: m.getProof(tokenIdData, 0)
        });

        lpAdds[0] = Pool.LpAdd({
            tokens: subpoolTokens,
            subpoolId: 0,
            ethAmount: 1 ether
        });

        p.add{value: 1 ether}(lpAdds);
    }
}
