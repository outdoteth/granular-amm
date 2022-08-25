const { generateMerkleProof } = require("./generate-merkle-proof");

const main = () => {
  const rankingFile = "bayc.json";
  const tokenId = 4;
  const merkleProof = generateMerkleProof(tokenId, rankingFile);

  console.log("Merkle proof: ", merkleProof);
};

main();
