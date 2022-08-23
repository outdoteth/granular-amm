const { defaultAbiCoder } = require("@ethersproject/abi");
const { generateMerkleRoots } = require("./generate-merkle-roots");

const main = async () => {
  const rankingFile = process.argv[2];

  const merkleRoots = generateMerkleRoots(rankingFile);

  process.stdout.write(defaultAbiCoder.encode(["bytes32[]"], [merkleRoots]));
  process.exit();
};

main();
