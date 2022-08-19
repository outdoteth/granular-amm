// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import {ERC20MintBurn} from "./ERC20MintBurn.sol";

contract Pool {
    struct Subpool {
        bytes32 merkleRoot;
        uint256 nftReserves;
        uint256 ethReserves;
        address lpToken;
        bool init;
    }

    struct SubpoolToken {
        uint256 tokenId;
        bytes32[] proof;
    }

    struct LpAdd {
        SubpoolToken[] tokens;
        uint256 subpoolId;
        uint256 ethAmount; // only used on init
    }

    address public token;
    mapping(uint256 => Subpool) public _subpools;

    constructor(address _token, bytes32[] memory _merkleRoots) {
        token = _token;

        for (uint256 i = 0; i < _merkleRoots.length; i++) {
            address lpToken = address(new ERC20MintBurn("lp token", "LPT"));
            _subpools[i] =
                Subpool({merkleRoot: _merkleRoots[i], ethReserves: 0, nftReserves: 0, lpToken: lpToken, init: false});
        }
    }

    function subpools(uint256 id) public view returns (Subpool memory) {
        return _subpools[id];
    }

    function add(LpAdd[] memory _lpAdds) public payable {
        uint256 totalRequiredEthInput = 0;

        for (uint256 i = 0; i < _lpAdds.length; i++) {
            LpAdd memory lpAdd = _lpAdds[i];
            Subpool memory subpool = _subpools[lpAdd.subpoolId];

            // calculate and sum the total required eth input
            uint256 requiredEthInput =
                subpool.init ? subpool.ethReserves * lpAdd.tokens.length / subpool.nftReserves : lpAdd.ethAmount;
            totalRequiredEthInput += requiredEthInput;

            // update the subpool's reserves
            subpool.ethReserves += requiredEthInput;
            subpool.nftReserves += lpAdd.tokens.length;

            // mint lp tokens to the msg.sender
            uint256 shares =
                subpool.init
                ? ERC20MintBurn(subpool.lpToken).totalSupply() * lpAdd.tokens.length / subpool.nftReserves
                : lpAdd.ethAmount * lpAdd.tokens.length;
            ERC20MintBurn(subpool.lpToken).mint(msg.sender, shares);

            subpool.init = true;

            for (uint256 j = 0; j < lpAdd.tokens.length; j++) {
                // validate that the token exists in the subpool's merkle root
                require(validateSubpoolToken(lpAdd.tokens[j], subpool.merkleRoot), "Invalid tokenId");

                // transfer the token in
                ERC721(token).transferFrom(msg.sender, address(this), lpAdd.tokens[i].tokenId);
            }
        }

        // validate enough eth was sent in
        require(msg.value == totalRequiredEthInput, "Not enough eth");
    }

    function remove() public {}

    function swap() public {}

    function price(uint256 subpoolId) public view returns (uint256) {
        Subpool memory subpool = _subpools[subpoolId];

        return subpool.ethReserves / subpool.nftReserves;
    }

    function validateSubpoolToken(SubpoolToken memory _token, bytes32 _merkleRoot) public pure returns (bool) {
        return MerkleProof.verify(_token.proof, _merkleRoot, bytes32(_token.tokenId));
    }
}
