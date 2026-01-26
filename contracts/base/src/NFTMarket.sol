// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract NFTMarket {
    struct NFT {
        address creator;
        string uri;
        address owner;
        uint256 price;
        bool forSale;
        uint256 royaltyPercent; // basis points (1000 = 10%)
    }

    mapping(uint256 => NFT) public nfts;
    uint256 public nextTokenId;

    event NFTMinted(uint256 indexed tokenId, address indexed creator);
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    function mint(string calldata uri, uint256 royaltyPercent) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        nfts[tokenId] = NFT({
            creator: msg.sender,
            uri: uri,
            owner: msg.sender,
            price: 0,
            forSale: false,
            royaltyPercent: royaltyPercent
        });
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nfts[tokenId].owner == msg.sender, "Not owner");
        nfts[tokenId].price = price;
        nfts[tokenId].forSale = true;
        emit NFTListed(tokenId, price);
    }

    function buy(uint256 tokenId) external payable {
        NFT storage nft = nfts[tokenId];
        require(nft.forSale, "Not for sale");
        require(msg.value >= nft.price, "Insufficient payment");
        
        uint256 royalty = (nft.price * nft.royaltyPercent) / 10000;
        uint256 sellerAmount = nft.price - royalty;
        
        payable(nft.creator).transfer(royalty);
        payable(nft.owner).transfer(sellerAmount);
        
        nft.owner = msg.sender;
        nft.forSale = false;
        
        emit NFTSold(tokenId, msg.sender, nft.price);
    }
}
