const ERC20_Token_Contract = artifacts.require("ERC20_Token_Contract");
const ERC20_Token_Sale_Contract = artifacts.require("ERC20_Token_Sale_Contract");
const ERC721_NFT_Contract = artifacts.require("ERC721_NFT_Contract");
const NFT_Marketplace = artifacts.require("NFT_Marketplace");
const chai = require("./setupchai.js");
const expect = chai.expect;
const dotenv = require("dotenv")
dotenv.config({path: "../config.env"});

contract("Testing Marketplace Contract", async (accounts) => {

    const [ firstAccount, secondAccount, thirdAccount, fourthAccount, fifthAccount, sixthAccount ] = accounts;
    
    beforeEach( async () => {
        this.tokenContractInstance = await ERC20_Token_Contract.new(process.env.INITIAL_SUPPLY, {from: firstAccount});
        this.tokenSaleContractInstance = await ERC20_Token_Sale_Contract.new(this.tokenContractInstance.address, {from: firstAccount});
        await this.tokenContractInstance.transfer(this.tokenSaleContractInstance.address, process.env.INITIAL_SUPPLY, {from: firstAccount});
        this.nftContractInstance = await ERC721_NFT_Contract.new({from: firstAccount});
        this.marketplaceContractInstance = await NFT_Marketplace.new(this.tokenContractInstance.address, this.nftContractInstance.address, {from: firstAccount});
        this.res = await this.nftContractInstance.mintNFT(secondAccount, "exampleUrl.ipfs", {from: firstAccount});
        await this.nftContractInstance.approve(this.marketplaceContractInstance.address, this.res.logs[0].args.tokenId, {from: secondAccount});
    });

    it("Owner can list the NFT on to the marketplace", async () => {
        expect(this.marketplaceContractInstance.listNFT(this.res.logs[0].args.tokenId, [thirdAccount, fourthAccount], 2, web3.utils.toBN('1000000000000000000'), {from: secondAccount})).to.eventually.be.fulfilled;
    });

    it("Owner can set the price for NFT on the marketplace", async () => {
        await this.marketplaceContractInstance.listNFT(this.res.logs[0].args.tokenId, [thirdAccount, fourthAccount], 2, web3.utils.toBN('1000000000000000000'), {from: secondAccount});
        const newPrice = web3.utils.toBN(1500000000000000000);
        const res2 = await this.marketplaceContractInstance.setNFTPrice(this.res.logs[0].args.tokenId, newPrice, {from: secondAccount});
        expect(res2.logs[0].args._newPrice).to.be.bignumber.equal(newPrice);
        
    });

    it("User can buy the listed NFT owned by other account", async () => {
        await this.marketplaceContractInstance.listNFT(this.res.logs[0].args.tokenId, [thirdAccount, fourthAccount], 2, web3.utils.toBN('1000000000000000000'), {from: secondAccount});
        await this.tokenSaleContractInstance.buy({from:fifthAccount, value: web3.utils.toWei('2', 'ether')});
        await this.tokenContractInstance.approve(this.marketplaceContractInstance.address, web3.utils.toWei('2', 'ether'), {from:fifthAccount});
        await expect(this.marketplaceContractInstance.buyNFT(this.res.logs[0].args.tokenId, {from: fifthAccount})).to.eventually.be.fulfilled;
        const res2 = await this.nftContractInstance.ownerOf(this.res.logs[0].args.tokenId);
        expect(res2).to.equal(fifthAccount);
    });

    it("User can sell the listed NFT to the Market", async () => {
        await this.marketplaceContractInstance.listNFT(this.res.logs[0].args.tokenId, [thirdAccount, fourthAccount], 2, web3.utils.toBN('1000000000000000000'), {from: secondAccount});
        await this.tokenSaleContractInstance.buy({from:fifthAccount, value: web3.utils.toWei('2', 'ether')});
        await this.tokenContractInstance.transfer(this.marketplaceContractInstance.address, web3.utils.toBN('2000000000000000000'), {from: fifthAccount});
        await expect(this.marketplaceContractInstance.sellNFT(this.res.logs[0].args.tokenId, {from: secondAccount})).to.eventually.be.fulfilled;
        const res2 = await this.nftContractInstance.ownerOf(this.res.logs[0].args.tokenId);
        expect(res2).to.equal(this.marketplaceContractInstance.address);
    });

    it("User can buy the listed NFT owned by Market", async () => {
        await this.marketplaceContractInstance.listNFT(this.res.logs[0].args.tokenId, [thirdAccount, fourthAccount], 2, web3.utils.toBN('1000000000000000000'), {from: secondAccount});
        await this.tokenSaleContractInstance.buy({from:fifthAccount, value: web3.utils.toWei('2', 'ether')});
        await this.tokenContractInstance.transfer(this.marketplaceContractInstance.address, web3.utils.toBN('2000000000000000000'), {from: fifthAccount});
        await this.marketplaceContractInstance.sellNFT(this.res.logs[0].args.tokenId, {from: secondAccount});
        await this.tokenSaleContractInstance.buy({from:sixthAccount, value: web3.utils.toWei('2', 'ether')});
        await this.tokenContractInstance.approve(this.marketplaceContractInstance.address, web3.utils.toWei('2', 'ether'), {from:sixthAccount})
        await expect(this.marketplaceContractInstance.buyNFTFromMarket(this.res.logs[0].args.tokenId, {from: sixthAccount})).to.eventually.be.fulfilled;
        const res2 = await this.nftContractInstance.ownerOf(this.res.logs[0].args.tokenId);
        expect(res2).to.equal(sixthAccount);
    });
});