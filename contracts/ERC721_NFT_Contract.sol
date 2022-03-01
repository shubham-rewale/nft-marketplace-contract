// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721_NFT_Contract is ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Indian Premier League", "IPL") {

    }

    function mintNFT(address _receipient, string memory _tokenUri) public onlyOwner returns(uint256) {
        _tokenIds.increment();
        uint256 newNftId = _tokenIds.current();
        _safeMint(_receipient, newNftId);
        _setTokenURI(newNftId, _tokenUri);
        return newNftId;
    }
}