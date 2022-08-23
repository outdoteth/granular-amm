const { generateMerkleRoots } = require("./generate-merkle-roots");

const main = () => {
  const rankingFile = "bayc.json";
  const merkleRoots = generateMerkleRoots(rankingFile);

  console.log("Merkle roots: ", merkleRoots);
};

main();
