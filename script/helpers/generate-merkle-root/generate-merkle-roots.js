const fs = require("fs");
const path = require("path");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { defaultAbiCoder } = require("ethers/lib/utils");

const generateMerkleRoots = (rankingFile) => {
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

  const roots = sortedRankings.map((tokenIds) => {
    const leaves = tokenIds.map((v) =>
      keccak256(defaultAbiCoder.encode(["uint256"], [v]))
    );
    const tree = new MerkleTree(leaves, keccak256, { sort: true });
    const root = tree.getHexRoot();

    return root;
  });

  return roots;
};

module.exports = { generateMerkleRoots };
