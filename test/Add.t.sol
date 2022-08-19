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

    function testItCannotAddLiquidityIfNotEnoughEthIsSent() public {
        // arrange
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](1);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});

        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: 1 ether});
        bayc.mint(address(this), 1);

        // act
        vm.expectRevert("Incorrect eth amount");
        p.add{value: 0.9 ether}(lpAdds);
    }

    function testItTransfersERC721IntoContract() public {
        // arrange
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](1);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});

        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: 1 ether});
        bayc.mint(address(this), 1);

        // act
        p.add{value: 1 ether}(lpAdds);

        // assert
        assertEq(bayc.ownerOf(1), address(p), "Should have sent token to contract");
    }

    function testItCannotUseTokenInSubpoolIfProofIsInvalid() public {
        // arrange
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](1);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 1)});

        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: 1 ether});
        bayc.mint(address(this), 1);

        // act
        vm.expectRevert("Invalid tokenId");
        p.add{value: 1 ether}(lpAdds);
    }

    function testItMarksSubpoolAsInited() public {
        // arrange
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](1);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});

        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: 1 ether});
        bayc.mint(address(this), 1);
        bayc.mint(address(this), 2);

        // act
        p.add{value: 1 ether}(lpAdds);

        // assert
        assertTrue(p.subpools(0).init, "Should have marked subpool as inited");
    }

    function testItMintsLpTokensToLper() public {
        // arrange
        uint256 ethAmount = 1.11 ether;
        uint256 expectedLpTokenAmount = ethAmount * 2;

        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](2);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});
        subpoolTokens[1] = Pool.SubpoolToken({tokenId: 2, proof: m.getProof(tokenIdData, 1)});
        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: ethAmount});
        bayc.mint(address(this), 1);
        bayc.mint(address(this), 2);

        // act
        p.add{value: ethAmount}(lpAdds);

        // assert
        assertEq(
            p.subpools(0).lpToken.balanceOf(address(this)),
            expectedLpTokenAmount,
            "Should have transferred correct amount of lp tokens"
        );
        assertEq(p.subpools(0).lpToken.totalSupply(), expectedLpTokenAmount, "Should have incremented total lp supply");
    }

    function testItIncrementsReserves() public {
        // arrange
        uint256 ethAmount = 1.11 ether;

        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](2);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});

        subpoolTokens[1] = Pool.SubpoolToken({tokenId: 2, proof: m.getProof(tokenIdData, 1)});

        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: ethAmount});
        bayc.mint(address(this), 1);
        bayc.mint(address(this), 2);

        // act
        p.add{value: ethAmount}(lpAdds);

        // assert
        assertEq(p.subpools(0).nftReserves, 2, "Should have incremented nft reserves");
        assertEq(p.subpools(0).ethReserves, ethAmount, "Should have incremented eth reserves");
    }

    function testItAddsAfterInit() public {
        // arrange
        uint256 ethAmount = 1.11 ether;

        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](2);

        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 1, proof: m.getProof(tokenIdData, 0)});
        subpoolTokens[1] = Pool.SubpoolToken({tokenId: 2, proof: m.getProof(tokenIdData, 1)});
        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: ethAmount});

        bayc.mint(address(this), 1);
        bayc.mint(address(this), 2);

        p.add{value: ethAmount}(lpAdds);

        delete subpoolTokens;
        ethAmount = 1.11 ether / 2;
        subpoolTokens = new Pool.SubpoolToken[](1);
        subpoolTokens[0] = Pool.SubpoolToken({tokenId: 3, proof: m.getProof(tokenIdData, 2)});
        lpAdds[0] = Pool.LpAdd({tokens: subpoolTokens, subpoolId: 0, ethAmount: ethAmount});

        // act
        vm.startPrank(babe);

        deal(babe, ethAmount);

        bayc.mint(babe, 3);
        bayc.setApprovalForAll(address(p), true);

        p.add{value: ethAmount}(lpAdds);

        vm.stopPrank();

        // assert
        assertEq(
            p.subpools(0).lpToken.balanceOf(babe),
            p.subpools(0).lpToken.totalSupply() / 3,
            "Should have given babe 1/3rd of the liquidity shares"
        );
    }
}
