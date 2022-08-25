// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";

import {Pool} from "./Pool.sol";

contract Factory is Owned {
    mapping(address => address) public tokenToPool;

    constructor() Owned(msg.sender) {}

    function create(address token, bytes32[] memory merkleRoots) public onlyOwner returns (Pool) {
        require(tokenToPool[token] == address(0), "Pool already created");

        Pool pool = new Pool(token, merkleRoots);
        tokenToPool[token] = address(pool);

        return pool;
    }
}
