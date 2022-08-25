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
        ERC20MintBurn lpToken;
        bool init;
    }

    struct SubpoolToken {
        uint256 tokenId;
        bytes32[] proof;
    }

    // === FUNCTION INPUTS ===

    struct LpAdd {
        SubpoolToken[] tokens;
        uint256 subpoolId;
        uint256 ethAmount; // only used on first-lp/init. can be ignored otherwise.
    }

    struct Swap {
        SubpoolToken[] tokens;
        uint256 subpoolId;
        bool isBuy;
    }

    struct LpRemove {
        SubpoolToken[] tokens;
        uint256 subpoolId;
    }

    uint256 public subpoolCount;
    address public token;
    mapping(uint256 => Subpool) public _subpools;

    constructor(address _token, bytes32[] memory _merkleRoots) {
        token = _token;
        subpoolCount = _merkleRoots.length;

        for (uint256 i = 0; i < _merkleRoots.length; i++) {
            ERC20MintBurn lpToken = new ERC20MintBurn("lp token", "LPT");
            _subpools[i] =
                Subpool({merkleRoot: _merkleRoots[i], ethReserves: 0, nftReserves: 0, lpToken: lpToken, init: false});
        }
    }

    function subpools(uint256 id) public view returns (Subpool memory) {
        return _subpools[id];
    }

    function add(LpAdd[] memory lpAdds) public payable {
        uint256 totalRequiredEthInput = 0;

        for (uint256 i = 0; i < lpAdds.length; i++) {
            LpAdd memory lpAdd = lpAdds[i];
            Subpool storage subpool = _subpools[lpAdd.subpoolId];

            // calculate and sum the total required eth input
            uint256 requiredEthInput =
                subpool.nftReserves != 0
                ? (subpool.ethReserves * lpAdd.tokens.length) / subpool.nftReserves
                : lpAdd.ethAmount;
            totalRequiredEthInput += requiredEthInput;

            // mint lp tokens to the msg.sender
            uint256 shares =
                subpool.nftReserves != 0
                ? (subpool.lpToken.totalSupply() * lpAdd.tokens.length) / subpool.nftReserves
                : lpAdd.ethAmount * lpAdd.tokens.length;
            subpool.lpToken.mint(msg.sender, shares);

            // update the subpool's reserves
            subpool.ethReserves += requiredEthInput;
            subpool.nftReserves += lpAdd.tokens.length;

            subpool.init = true;

            for (uint256 j = 0; j < lpAdd.tokens.length; j++) {
                // validate that the token exists in the subpool's merkle root
                require(validateSubpoolToken(lpAdd.tokens[j], subpool.merkleRoot), "Invalid tokenId");

                // transfer the token in
                ERC721(token).transferFrom(msg.sender, address(this), lpAdd.tokens[j].tokenId);
            }
        }

        // validate enough eth was sent in
        require(msg.value == totalRequiredEthInput, "Incorrect eth amount");
    }

    function swap(Swap[] memory swaps) public payable {
        uint256 totalRequiredEthInput = 0;
        uint256 totalEthOutput = 0;

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory _swap = swaps[i];
            Subpool storage subpool = _subpools[_swap.subpoolId];

            if (_swap.isBuy) {
                // calculate the cost
                uint256 requiredEthInput = getBuyInput(_swap.subpoolId, _swap.tokens.length);
                totalRequiredEthInput += requiredEthInput;

                // update the subpool reserves
                subpool.nftReserves -= _swap.tokens.length;
                subpool.ethReserves += requiredEthInput;
            } else {
                // calculate the output amount
                uint256 ethOutput = getSellOutput(_swap.subpoolId, _swap.tokens.length);
                totalEthOutput += ethOutput;

                // update the subpool reserves
                subpool.nftReserves += _swap.tokens.length;
                subpool.ethReserves -= ethOutput;
            }

            for (uint256 j = 0; j < _swap.tokens.length; j++) {
                // validate that the token exists in the subpool's merkle root
                require(validateSubpoolToken(_swap.tokens[j], subpool.merkleRoot), "Invalid tokenId");

                // isBuy ? transfer tokens TO msg.sender : transfer tokens FROM msg.sender
                _swap.isBuy
                    ? ERC721(token).transferFrom(address(this), msg.sender, _swap.tokens[j].tokenId)
                    : ERC721(token).transferFrom(msg.sender, address(this), _swap.tokens[j].tokenId);
            }
        }

        // validate enough eth was sent in
        require(msg.value == totalRequiredEthInput, "Incorrect eth amount");

        // send out any eth from sells
        payable(msg.sender).transfer(totalEthOutput);
    }

    function remove(LpRemove[] memory lpRemoves) public {
        uint256 totalEthOutput = 0;

        for (uint256 i = 0; i < lpRemoves.length; i++) {
            LpRemove memory lpRemove = lpRemoves[i];
            Subpool storage subpool = _subpools[lpRemove.subpoolId];

            // calculate and sum the total eth output
            uint256 ethOutput = (subpool.ethReserves * lpRemove.tokens.length) / subpool.nftReserves;
            totalEthOutput += ethOutput;

            // burn lp tokens from the msg.sender
            uint256 shares = (subpool.lpToken.totalSupply() * lpRemove.tokens.length) / subpool.nftReserves;
            subpool.lpToken.burn(msg.sender, shares);

            // update the subpool's reserves
            subpool.ethReserves -= ethOutput;
            subpool.nftReserves -= lpRemove.tokens.length;

            for (uint256 j = 0; j < lpRemove.tokens.length; j++) {
                // validate that the token exists in the subpool's merkle root
                require(validateSubpoolToken(lpRemove.tokens[j], subpool.merkleRoot), "Invalid tokenId");

                // transfer the token out
                ERC721(token).transferFrom(address(this), msg.sender, lpRemove.tokens[j].tokenId);
            }
        }

        // send eth to msg.sender
        payable(msg.sender).transfer(totalEthOutput);
    }

    function price(uint256 subpoolId) public view returns (uint256) {
        Subpool memory subpool = _subpools[subpoolId];

        return subpool.ethReserves / subpool.nftReserves;
    }

    function getBuyInput(uint256 subpoolId, uint256 amount) public view returns (uint256) {
        Subpool storage subpool = _subpools[subpoolId];

        return (amount * subpool.ethReserves) / (subpool.nftReserves - amount);
    }

    function getSellOutput(uint256 subpoolId, uint256 amount) public view returns (uint256) {
        Subpool storage subpool = _subpools[subpoolId];

        return (amount * subpool.ethReserves) / (subpool.nftReserves + amount);
    }

    // todo: this can be in a seperate contract that an admin can change
    function validateSubpoolToken(SubpoolToken memory _token, bytes32 _merkleRoot) public pure returns (bool) {
        return MerkleProof.verify(_token.proof, _merkleRoot, keccak256(abi.encodePacked(_token.tokenId)));
    }
}
