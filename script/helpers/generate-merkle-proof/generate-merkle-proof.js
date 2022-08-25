const fs = require("fs");
const path = require("path");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { defaultAbiCoder } = require("ethers/lib/utils");

const generateMerkleProof = (tokenId, rankingFile) => {
  const rankings = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../rankings", rankingFile), {
      encoding: "utf8",
    })
  );

  const sortedRankings = Object.entries(rankings).reduce((arr, [k, v]) => {
    const bin = v - 1;
    if (arr[bin]) arr[bin].push(k);
    else arr[bin] = [k];
    return arr;
  }, []);

  let proof;
  let subpoolId = 0;
  for (const tokenIds of sortedRankings) {
    const leaves = tokenIds.map((v) =>
      keccak256(defaultAbiCoder.encode(["uint256"], [v]))
    );
    const tree = new MerkleTree(leaves, keccak256, { sort: true });

    if (tokenIds.some((v) => v == tokenId)) {
      proof = tree.getHexProof(
        keccak256(defaultAbiCoder.encode(["uint256"], [tokenId]))
      );

      break;
    }

    subpoolId += 1;
  }

  return proof;
};

module.exports = { generateMerkleProof };
