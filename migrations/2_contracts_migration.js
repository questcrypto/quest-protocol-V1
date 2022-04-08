
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const NFTs = artifacts.require("NFTs.sol");
const NFTsFactory = artifacts.require("NFTsFactory.sol");


module.exports = async (deployer) => {
    
    const factory = await deployProxy(NftFactory, { deployer });
    const nft = await deployProxy(NFTs, [uri_, assetWallet, hoa, treasury, _contractName, propTaxId], { deployer })

    console.log("Property Contract Address", nft.address);


};