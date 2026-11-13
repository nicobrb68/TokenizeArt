import { network } from "hardhat";

async function main() {
  const contractAddress =
    process.env.CONTRACT_ADDRESS || "0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b";
  const metadataURI =
    process.env.METADATA_URI ||
    "ipfs://bafkreidhzty33rqegajaqo75ilyvtoz4ri5ezzb66yn7mga5p2hwkxhveu";

  const { ethers } = await network.connect();
  const [owner] = await ethers.getSigners();

  console.log("Connecting to TokenizeArt42 at:", contractAddress);
  console.log("Minting with account:", owner.address);

  const contract = await ethers.getContractAt("TokenizeArt42", contractAddress, owner);

  // 1. Mandatory part: Mint NFT #1 pointing to IPFS metadata
  console.log("\n[1/2] Minting IPFS NFT (Token #1)...");
  const txIpfs = await contract.mintIPFS(owner.address, metadataURI);
  const receiptIpfs = await txIpfs.wait(2);
  console.log("  IPFS NFT minted! Tx hash:", receiptIpfs?.hash);

  // 2. Bonus part: Mint NFT #2 with 100% On-Chain Base64 SVG & JSON
  console.log("\n[2/2] Minting 100% On-Chain NFT (Token #2)...");
  const txOnChain = await contract.mintOnChain();
  const receiptOnChain = await txOnChain.wait(2);
  console.log("  On-Chain NFT minted! Tx hash:", receiptOnChain?.hash);

  // 3. Verify on-chain state and decode Token #2 metadata
  const total = await contract.totalMinted();
  const uri1 = await contract.tokenURI(1);
  const uri2 = await contract.tokenURI(2);

  console.log("\n--- On-Chain Verification ---");
  console.log("Total Minted:", total.toString());
  console.log("Token #1 Owner:", await contract.ownerOf(1));
  console.log("Token #1 URI:", uri1);

  // Decode Base64 JSON and embedded Base64 SVG from Token #2
  const jsonBase64 = uri2.replace("data:application/json;base64,", "");
  const decodedJson = JSON.parse(Buffer.from(jsonBase64, "base64").toString("utf-8"));
  const svgBase64 = decodedJson.image.replace("data:image/svg+xml;base64,", "");
  const decodedSvg = Buffer.from(svgBase64, "base64").toString("utf-8");

  console.log("Token #2 Owner:", await contract.ownerOf(2));
  console.log("Token #2 Name:", decodedJson.name);
  console.log("Token #2 Decoded SVG length:", decodedSvg.length, "bytes");
  console.log(
    "Token #2 SVG integrity:",
    decodedSvg.startsWith("<svg") && decodedSvg.endsWith("</svg>") ? "VALID" : "INVALID"
  );
  console.log(`\nView on Etherscan: https://sepolia.etherscan.io/token/${contractAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
