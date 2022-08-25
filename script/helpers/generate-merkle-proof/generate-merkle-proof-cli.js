const { defaultAbiCoder } = require("@ethersproject/abi");
const { generateMerkleProof } = require("./generate-merkle-proof");

const main = async () => {
  const rankingFile = process.argv[2];
  const tokenId = process.argv[3];

  const merkleProof = generateMerkleProof(tokenId, rankingFile);

  process.stdout.write(defaultAbiCoder.encode(["bytes32[]"], [merkleProof]));
  process.exit();
};

main();
