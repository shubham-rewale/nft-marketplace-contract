// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20_Token_Contract.sol";
import "./ERC721_NFT_Contract.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./DSMath.sol";

contract NFT_Marketplace is DSMath, ERC721Holder {
    
    ERC20_Token_Contract private tokenContract;
    ERC721_NFT_Contract private nftContract;

    struct listedNFT {
        address owner;
        uint price;
        uint royaltyPercentage;
        address[] royaltyOwners;
        bool listed;
    }
    
    mapping(uint => listedNFT) private listedNFTs;

    event NFTHasBeenListed(uint _listedTokenId);
    event NFTHasBeenBought(uint _listedTokenId, address _previousOwner, address _newOwner, uint _platformFeeGiven, uint _royaltyGiven, uint _soldAtPrice);
    event updatedNFTPrice(uint _listedTokenId, uint _oldPrice, uint _newPrice);
    event NFTHasBeenSold(uint _listedTokenId, address _previousOwner, address _newOwner, uint _platformFeeGiven, uint _royaltyGiven, uint _soldAtPrice);

    constructor(ERC20_Token_Contract _tokenAddress, ERC721_NFT_Contract _nftAddress) {
        tokenContract = _tokenAddress;
        nftContract = _nftAddress;
    }

    function listNFT(uint _tokenId, address[] memory _royaltyOwners, uint _royaltyPercentage, uint _nftPrice) public {
        require(listedNFTs[_tokenId].listed == false, "Token is already listed");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Only owner can list the token on marketplace");
        require(nftContract.getApproved(_tokenId) == address(this), "Marketplace is not approved to list this token");
        listedNFTs[_tokenId].price = _nftPrice;
        listedNFTs[_tokenId].owner = nftContract.ownerOf(_tokenId);
        listedNFTs[_tokenId].royaltyPercentage = _royaltyPercentage;
        listedNFTs[_tokenId].royaltyOwners = _royaltyOwners;
        listedNFTs[_tokenId].listed = true;
        emit NFTHasBeenListed(_tokenId);
    }

    function viewListedNFT(uint _tokenId) public view returns(listedNFT memory _listedNFT) {
        require(listedNFTs[_tokenId].listed == true, "Token is not listed");
        _listedNFT = listedNFTs[_tokenId];
    }

    function getPlatformFeeOnSale() public pure returns(string memory _platformFee) {
        _platformFee = "2.5";
    }

    function buyNFTFromMarket(uint _tokenId) public {
        require(listedNFTs[_tokenId].listed == true, "Token is not listed");
        require(tokenContract.allowance(msg.sender, address(this)) >= listedNFTs[_tokenId].price, "Not enough funds, funds need to be assigned in the allownce for the market contract");
        uint platformFeeOnTheSale = (rdiv((listedNFTs[_tokenId].price * 25), 1000)) / 10**27;
        uint royaltyOnTheSale = (rdiv((listedNFTs[_tokenId].price * listedNFTs[_tokenId].royaltyPercentage), 100)) / 10**27;
        uint noOfRoyaltyOwners = listedNFTs[_tokenId].royaltyOwners.length;
        uint royaltyToEachOwner = (rdiv(royaltyOnTheSale, noOfRoyaltyOwners)) / 10**27;
        for (uint i = 0; i < noOfRoyaltyOwners; i++) {
            tokenContract.transferFrom(msg.sender, listedNFTs[_tokenId].royaltyOwners[i], royaltyToEachOwner);
        }
        address previousOwner = listedNFTs[_tokenId].owner;
        uint amountToTransferToPreviousOwner = listedNFTs[_tokenId].price - royaltyOnTheSale;
        tokenContract.transferFrom(msg.sender, previousOwner, amountToTransferToPreviousOwner);
        nftContract.safeTransferFrom(previousOwner, msg.sender, _tokenId);
        listedNFTs[_tokenId].owner = msg.sender;
        emit NFTHasBeenBought(_tokenId, previousOwner, listedNFTs[_tokenId].owner, platformFeeOnTheSale, royaltyOnTheSale, listedNFTs[_tokenId].price);
    }

    function buyNFT(uint _tokenId) public {
        require(listedNFTs[_tokenId].listed == true, "Token is not listed");
        require(tokenContract.allowance(msg.sender, address(this)) >= listedNFTs[_tokenId].price, "Not enough funds, funds need to be assigned in the allownce for the market contract");
        require(nftContract.getApproved(_tokenId) == address(this), "Marketplace is not approved to handle this token");
        uint platformFeeOnTheSale = (rdiv((listedNFTs[_tokenId].price * 25), 1000)) / 10**27;
        uint royaltyOnTheSale = (rdiv((listedNFTs[_tokenId].price * listedNFTs[_tokenId].royaltyPercentage), 100)) / 10**27;
        uint noOfRoyaltyOwners = listedNFTs[_tokenId].royaltyOwners.length;
        uint royaltyToEachOwner = (rdiv(royaltyOnTheSale, noOfRoyaltyOwners)) / 10**27;
        tokenContract.transferFrom(msg.sender, address(this), platformFeeOnTheSale);
        for (uint i = 0; i < noOfRoyaltyOwners; i++) {
            tokenContract.transferFrom(msg.sender, listedNFTs[_tokenId].royaltyOwners[i], royaltyToEachOwner);
        }
        address previousOwner = listedNFTs[_tokenId].owner;
        uint amountToTransferToPreviousOwner = ((listedNFTs[_tokenId].price - platformFeeOnTheSale) - royaltyOnTheSale);
        tokenContract.transferFrom(msg.sender, previousOwner, amountToTransferToPreviousOwner);
        nftContract.safeTransferFrom(previousOwner, msg.sender, _tokenId);
        listedNFTs[_tokenId].owner = msg.sender;
        emit NFTHasBeenBought(_tokenId, previousOwner, listedNFTs[_tokenId].owner, platformFeeOnTheSale, royaltyOnTheSale, listedNFTs[_tokenId].price);
    }

    function setNFTPrice(uint _tokenId, uint _price) public {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Only owner can change the token price on the marketplace");
        uint oldPrice = listedNFTs[_tokenId].price;
        listedNFTs[_tokenId].price = _price;
        emit updatedNFTPrice(_tokenId, oldPrice, listedNFTs[_tokenId].price);
    }

    function sellNFT(uint _tokenId) public {
        require(listedNFTs[_tokenId].listed == true, "Token is not listed");
        require(listedNFTs[_tokenId].owner == msg.sender, "Only owner can sell the nft");
        require(nftContract.getApproved(_tokenId) == address(this), "Marketplace is not approved to handle this token");
        require(tokenContract.balanceOf(address(this)) >= listedNFTs[_tokenId].price, "Market doesn't have enough funds to buy this token");
        uint platformFeeOnTheSale = (rdiv((listedNFTs[_tokenId].price * 25), 1000)) / 10**27;
        uint royaltyOnTheSale = (rdiv((listedNFTs[_tokenId].price * listedNFTs[_tokenId].royaltyPercentage), 100)) / 10**27;
        uint noOfRoyaltyOwners = listedNFTs[_tokenId].royaltyOwners.length;
        uint royaltyToEachOwner = (rdiv(royaltyOnTheSale, noOfRoyaltyOwners)) / 10**27;
        for (uint i = 0; i < noOfRoyaltyOwners; i++) {
            tokenContract.transfer(listedNFTs[_tokenId].royaltyOwners[i], royaltyToEachOwner);
        }
        address previousOwner = listedNFTs[_tokenId].owner;
        uint amountToTransferToPreviousOwner = ((listedNFTs[_tokenId].price - platformFeeOnTheSale) - royaltyOnTheSale);
        tokenContract.transfer(previousOwner, amountToTransferToPreviousOwner);
        nftContract.safeTransferFrom(previousOwner, address(this), _tokenId);
        listedNFTs[_tokenId].owner = address(this);
        emit NFTHasBeenSold(_tokenId, previousOwner, listedNFTs[_tokenId].owner, platformFeeOnTheSale, royaltyOnTheSale, listedNFTs[_tokenId].price);
    }
}