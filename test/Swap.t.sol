// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";
import "../src/Pool.sol";
import "./Fixture.sol";

contract SwapTest is Fixture {
    Pool public p;
    Pool.SubpoolToken[] public lpTokens;

    receive() external payable {}

    function setUp() public {
        // create the pool
        bytes32 root = m.getRoot(tokenIdData);
        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = root;
        p = f.create(address(bayc), merkleRoots);

        // add the liquidity
        bayc.setApprovalForAll(address(p), true);
        uint256 ethAmount = 3.0 ether;
        uint256 nftAmount = 3;
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        for (uint256 i = 0; i < nftAmount; i++) {
            lpTokens.push(Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)}));
            bayc.mint(address(this), i + 1);
        }
        lpAdds[0] = Pool.LpAdd({tokens: lpTokens, subpoolId: 0, ethAmount: ethAmount});
        p.add{value: ethAmount}(lpAdds);
    }

    function testItSendsEthOutputIfSelling() public {
        // arrange
        uint256 nftAmount = 3;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] =
                Pool.SubpoolToken({tokenId: lpTokens.length + i + 1, proof: m.getProof(tokenIdData, lpTokens.length + i)});
            bayc.mint(address(this), lpTokens.length + i + 1);
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: false});
        uint256 balanceBefore = address(this).balance;
        uint256 expectedChange = p.getSellOutput(0, nftAmount);

        // act
        p.swap(swaps);

        // assert
        assertEq(
            address(this).balance - balanceBefore, expectedChange, "Should have sent correct amount of eth to seller"
        );
    }

    function testItTransfersNftsToPoolIfSelling() public {
        // arrange
        uint256 nftAmount = 3;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] =
                Pool.SubpoolToken({tokenId: lpTokens.length + i + 1, proof: m.getProof(tokenIdData, lpTokens.length + i)});
            bayc.mint(address(this), lpTokens.length + i + 1);
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: false});

        // act
        p.swap(swaps);

        // assert
        for (uint256 i = 0; i < nftAmount; i++) {
            assertEq(bayc.ownerOf(lpTokens.length + i + 1), address(p), "Should have sent nfts to pool");
        }
    }

    function testItUpdatesReservesIfSelling() public {
        // arrange
        uint256 nftAmount = 3;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] =
                Pool.SubpoolToken({tokenId: lpTokens.length + i + 1, proof: m.getProof(tokenIdData, lpTokens.length + i)});
            bayc.mint(address(this), lpTokens.length + i + 1);
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: false});
        uint256 ethOutput = p.getSellOutput(0, nftAmount);
        uint256 ethReservesBefore = p.subpools(0).ethReserves;

        // act
        p.swap(swaps);

        // assert
        assertEq(p.subpools(0).nftReserves, lpTokens.length + subpoolTokens.length, "Should have updated nft reserves");
        assertEq(ethReservesBefore - p.subpools(0).ethReserves, ethOutput, "Should have updated eth reserves");
    }

    function testItRequiresEthInputIfBuying() public {
        // arrange
        uint256 nftAmount = 2;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: true});

        // act
        vm.expectRevert("Incorrect eth amount");
        p.swap{value: 0.1 ether}(swaps);
    }

    function testItTransfersNftsOutOfPoolIfBuying() public {
        // arrange
        uint256 nftAmount = 2;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: true});
        uint256 inputAmount = p.getBuyInput(0, nftAmount);

        // act
        p.swap{value: inputAmount}(swaps);

        // assert
        for (uint256 i = 0; i < nftAmount; i++) {
            assertEq(bayc.ownerOf(i + 1), address(this), "Should have sent nfts to buyer");
        }
    }

    function testItUpdatesReservesIfBuying() public {
        // arrange
        uint256 nftAmount = 2;
        Pool.Swap[] memory swaps = new Pool.Swap[](nftAmount);
        Pool.SubpoolToken[] memory subpoolTokens = new Pool.SubpoolToken[](nftAmount);
        for (uint256 i = 0; i < nftAmount; i++) {
            subpoolTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        swaps[0] = Pool.Swap({tokens: subpoolTokens, subpoolId: 0, isBuy: true});
        uint256 inputAmount = p.getBuyInput(0, nftAmount);
        uint256 ethReservesBefore = p.subpools(0).ethReserves;

        // act
        p.swap{value: inputAmount}(swaps);

        // assert
        assertEq(p.subpools(0).nftReserves, lpTokens.length - subpoolTokens.length, "Should have updated nft reserves");
        assertEq(p.subpools(0).ethReserves - ethReservesBefore, inputAmount, "Should have updated eth reserves");
    }
}
