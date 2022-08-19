// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Factory.sol";
import "../src/Pool.sol";
import "./Fixture.sol";

contract RemoveTest is Fixture {
    Pool public p;
    Pool.SubpoolToken[] public lpTokens;
    uint256 ethAmount;
    uint256 nftAmount;

    receive() external payable {}

    function setUp() public {
        // create the pool
        bytes32 root = m.getRoot(tokenIdData);
        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = root;
        p = f.create(address(bayc), merkleRoots);

        // add the liquidity
        bayc.setApprovalForAll(address(p), true);
        ethAmount = 3.0 ether;
        nftAmount = 3;
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        for (uint256 i = 0; i < nftAmount; i++) {
            lpTokens.push(Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)}));
            bayc.mint(address(this), i + 1);
        }
        lpAdds[0] = Pool.LpAdd({tokens: lpTokens, subpoolId: 0, ethAmount: ethAmount});
        p.add{value: ethAmount}(lpAdds);
    }

    function testItSendsEthAmountAndNftsToLp() public {
        // arrange
        uint256 removeAmount = 2;
        Pool.LpRemove[] memory lpRemoves = new Pool.LpRemove[](1);
        Pool.SubpoolToken[] memory removeTokens = new Pool.SubpoolToken[](removeAmount);
        for (uint256 i = 0; i < removeAmount; i++) {
            removeTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        lpRemoves[0] = Pool.LpRemove({tokens: removeTokens, subpoolId: 0});
        uint256 balanceBefore = address(this).balance;
        uint256 expectedEthBalance = (ethAmount * removeAmount) / lpTokens.length;

        // act
        p.remove(lpRemoves);

        // assert
        assertEq(address(this).balance - balanceBefore, expectedEthBalance, "Should have withdrawn correct eth amount");
        for (uint256 i = 0; i < removeTokens.length; i++) {
            assertEq(bayc.ownerOf(i + 1), address(this), "Should have withdrawn nft");
        }
    }

    function testItDecrementsReserves() public {
        // arrange
        uint256 removeAmount = 2;
        Pool.LpRemove[] memory lpRemoves = new Pool.LpRemove[](1);
        Pool.SubpoolToken[] memory removeTokens = new Pool.SubpoolToken[](removeAmount);
        for (uint256 i = 0; i < removeAmount; i++) {
            removeTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        lpRemoves[0] = Pool.LpRemove({tokens: removeTokens, subpoolId: 0});
        uint256 ethReservesBefore = p.subpools(0).ethReserves;
        uint256 expectedEthDecrement = (ethAmount * removeAmount) / lpTokens.length;

        // act
        p.remove(lpRemoves);

        // assert
        assertEq(p.subpools(0).nftReserves, lpTokens.length - removeAmount, "Should have decremented nft reserves");
        assertEq(
            ethReservesBefore - p.subpools(0).ethReserves, expectedEthDecrement, "Should have decremented eth reserves"
        );
    }

    function testItBurnsLpTokens() public {
        // arrange
        uint256 removeAmount = 2;
        Pool.LpRemove[] memory lpRemoves = new Pool.LpRemove[](1);
        Pool.SubpoolToken[] memory removeTokens = new Pool.SubpoolToken[](removeAmount);
        for (uint256 i = 0; i < removeAmount; i++) {
            removeTokens[i] = Pool.SubpoolToken({tokenId: i + 1, proof: m.getProof(tokenIdData, i)});
        }
        lpRemoves[0] = Pool.LpRemove({tokens: removeTokens, subpoolId: 0});
        uint256 balanceBefore = p.subpools(0).lpToken.balanceOf(address(this));
        uint256 expectedBurnAmount = (p.subpools(0).lpToken.totalSupply() * removeAmount) / lpTokens.length;

        // act
        p.remove(lpRemoves);

        // assert
        assertEq(
            balanceBefore - p.subpools(0).lpToken.balanceOf(address(this)),
            expectedBurnAmount,
            "Should have burned lp tokens"
        );
    }
}
