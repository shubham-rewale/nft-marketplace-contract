const ERC20_Token_Contract = artifacts.require("ERC20_Token_Contract");
const ERC20_Token_Sale_Contract = artifacts.require("ERC20_Token_Sale_Contract");
const ERC721_NFT_Contract = artifacts.require("ERC721_NFT_Contract");
const NFT_Marketplace = artifacts.require("NFT_Marketplace");
require('dotenv').config({path: '../config.env'});

module.exports = async function(deployer) {
    await deployer.deploy(ERC20_Token_Contract, process.env.INITIAL_SUPPLY);
    await deployer.deploy(ERC20_Token_Sale_Contract, ERC20_Token_Contract.address);
    const tokenContractInstance = await ERC20_Token_Contract.deployed();
    await tokenContractInstance.transfer(ERC20_Token_Sale_Contract.address, process.env.INITIAL_SUPPLY);
    await deployer.deploy(ERC721_NFT_Contract);
    await deployer.deploy(NFT_Marketplace, ERC20_Token_Contract.address, ERC721_NFT_Contract.address);
};