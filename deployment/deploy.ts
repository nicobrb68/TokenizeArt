import fs from "node:fs";
import path from "node:path";
import { network } from "hardhat";

async function main() {
  const contractAddress = "0x5c7a3B28D9b11f4166092CA484aB1Cb1b43EBf0b";
  const { ethers } = await network.connect();
  const [deployer] = await ethers.getSigners();

  console.log("Using existing TokenizeArt42 at:", contractAddress);
  const contract = await ethers.getContractAt("TokenizeArt42", contractAddress, deployer);

  // 1. Read and minify the SVG
  const svgPath = path.resolve(process.cwd(), "assets/nbarbosa42.svg");
  const minifiedSvg = fs
    .readFileSync(svgPath, "utf-8")
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/>\s+</g, "><")
    .replace(/\s+/g, " ")
    .trim();

  const fullSvgBytes = ethers.toUtf8Bytes(minifiedSvg);
  const chunkSize = 10500;
  const totalChunks = Math.ceil(fullSvgBytes.length / chunkSize);

  for (let i = 0; i < totalChunks; i++) {
    const slice = fullSvgBytes.slice(i * chunkSize, (i + 1) * chunkSize);
    const runtimeHex = "00" + ethers.hexlify(slice).slice(2);
    const runtimeLen = runtimeHex.length / 2;
    const lenHex = runtimeLen.toString(16).padStart(4, "0");

    // Exact 11-byte header (offset 0x0b = 11 bytes):
    // 61 XXXX (3B) | 80 (1B) | 60 0b (2B) | 60 00 (2B) | 39 (1B) | 60 00 (2B) | f3 (1B) -> Wait: 3+1+2+2+1+2+1 = 12 bytes (0x0c)!
    // Why did pointer.code.length fail? RPC node lag right after wait(1)!
    // Wait for 2 confirmations and verify getCode(pointerAddress) before calling addSvgPointer.
    const initCode = `0x61${lenHex}80600c6000396000f3${runtimeHex}`;

    console.log(`Deploying chunk ${i + 1}/${totalChunks} (${runtimeLen} bytes)...`);
    const sstoreTx = await deployer.sendTransaction({ data: initCode });
    const sstoreReceipt = await sstoreTx.wait(2);
    const pointerAddress = sstoreReceipt?.contractAddress;
    if (!pointerAddress) {
      throw new Error(`No contractAddress for chunk ${i + 1}`);
    }

    // Wait until the RPC node actually indexes the deployed bytecode
    let deployedCode = await ethers.provider.getCode(pointerAddress);
    while (deployedCode === "0x" || deployedCode.length <= 4) {
      console.log("  Waiting 2s for RPC node to index bytecode...");
      await new Promise((r) => setTimeout(r, 2000));
      deployedCode = await ethers.provider.getCode(pointerAddress);
    }
    console.log(`  Verified bytecode on RPC (${(deployedCode.length - 2) / 2} bytes) at ${pointerAddress}`);

    const linkTx = await contract.addSvgPointer(pointerAddress);
    await linkTx.wait(1);
    console.log(`  Chunk ${i + 1}/${totalChunks} linked! (tx: ${linkTx.hash})`);
  }

  // Save CONTRACT_ADDRESS cleanly in .env
  const envPath = path.resolve(process.cwd(), ".env");
  const existingEnv = fs.existsSync(envPath) ? fs.readFileSync(envPath, "utf-8") : "";
  const filteredLines = existingEnv
    .split("\n")
    .filter((line) => line.trim() !== "" && !line.startsWith("CONTRACT_ADDRESS="));
  filteredLines.push(`CONTRACT_ADDRESS="${contractAddress}"`);
  fs.writeFileSync(envPath, filteredLines.join("\n") + "\n", "utf-8");

  console.log("\nDeployment & SVG linking complete!");
  console.log("Contract Address:", contractAddress);
  console.log(`Etherscan URL: https://sepolia.etherscan.io/address/${contractAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
