// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";

import {Pool} from "./Pool.sol";

contract Factory is Owned {
    constructor() Owned(msg.sender) {}

    function create(address token, bytes32[] memory merkleRoots) public returns (Pool pool) {
        return new Pool(token, merkleRoots);
    }
}
