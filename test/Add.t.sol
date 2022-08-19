// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/Factory.sol";
import "../src/Pool.sol";
import "./Fixture.sol";

contract AddTest is Fixture {
    function setUp() public {}

    function testItInitsLiquidity() public {
        Pool.LpAdd[] memory lpAdds = new Pool.LpAdd[](1);
        Pool.SubpoolToken[] memory subpoolTokens= new Pool.SubpoolToken[](1);

        lpAdds[0] = Pool.LpAdd({

        });
    }
}
