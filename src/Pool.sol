// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Pool {
    struct Subpool {
        bytes32 merkleRoot;
    }

    struct SubpoolToken {
        uint256 tokenId;
        bytes32[] merkleProofs;
    }

    struct SubpoolAdd {
        SubpoolToken[] tokens;
        uint256 subpoolId;
    }

    address public token;
    mapping(uint256 => Subpool) public _subpools;

    constructor(address _token, bytes32[] memory _merkleRoots) {
        token = _token;

        for (uint256 i = 0; i < _merkleRoots.length; i++) {
            _subpools[i] = Subpool({merkleRoot: _merkleRoots[i]});
        }
    }

    function subpools(uint256 id) public view returns (Subpool memory) {
        return _subpools[id];
    }

    function add(SubpoolAdd[] memory _subpoolAdds) public {
        for (uint256 i = 0; i < _subpoolAdds.length; i++) {
            SubpoolAdd memory subpoolAdd = _subpoolAdds[i];
            Subpool memory subpool = _subpools[subpoolAdd.subpoolId];

            for (uint256 j = 0; j < subpoolAdd.tokens.length; j++) {
                validateSubpoolToken(subpoolAdd.tokens[j], subpool.merkleRoot);
            }
        }
    }

    function validateSubpoolToken(SubpoolToken memory _token, bytes32 _merkleRoot) public {
        
    }
}
