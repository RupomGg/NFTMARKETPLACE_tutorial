const hre = require("hardhat");

async function main() {
    const nftmarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
    const nftmarketplace = await nftmarketplace.deploy();
    
    await nftmarketplace.deployed();
    console.log("NFTMarketplace deployed to:, ${nftmarketplace.address}");

    main().catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });