//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIds;
    address payable contractOwner;
    uint256 listingPrice = 0.01 ether;

    struct NFT {
        uint256 id;
        address payable contractAddress;
        address payable owner;
        uint256 price;
        bool isListed;
    }

    event NFTListingSuccess(
        uint256 indexed id,
        address contractAddress,
        address owner,
        uint256 price,
        bool isListed
    );

    mapping(uint256 => NFT) private _idToNFT;

    constructor() ERC721("EducativeNFT", "EDUNFT") {
        contractOwner = payable(msg.sender);
    }

    function mintNFT(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();

        _safeMint(msg.sender, newNftId);
        _setTokenURI(newNftId, tokenURI);

        listNFT(newNftId, price);

        return newNftId;
    }

    function listNFT(uint256 id, uint256 price) private {
        require(
            msg.value == listingPrice,
            "Hopefully sending the correct price"
        );
        require(price > 0, "Make sure the price isn't negative");

        _idToNFT[id] = NFT(
            id,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), id);
        
        emit NFTListingSuccess(id, address(this), msg.sender, price, true);
    }

    function getAllNFTs() public view returns (NFT[] memory) {
        uint256 totalItemCount = _nftIds.current();
        NFT[] memory items = new NFT[](totalItemCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            NFT storage currentItem = _idToNFT[i + 1];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function getMyNFTs() public view returns (NFT[] memory) {
        uint256 totalItemCount = _nftIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                _idToNFT[i + 1].contractAddress == msg.sender ||
                _idToNFT[i + 1].owner == msg.sender
            ) {
                itemCount += 1;
            }
        }

        NFT[] memory items = new NFT[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (
                _idToNFT[i + 1].contractAddress == msg.sender ||
                _idToNFT[i + 1].owner == msg.sender
            ) {
                NFT storage currentItem = _idToNFT[i + 1];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function sellNFT(uint256 id) public payable {
        uint256 price = _idToNFT[id].price;
        address seller = _idToNFT[id].owner;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        _idToNFT[id].isListed = true;
        _idToNFT[id].owner = payable(msg.sender);

        _transfer(address(this), msg.sender, id);
        approve(address(this), id);

        (bool ownerTransferSuccess, ) = payable(contractOwner).call{value: listingPrice}("");
        (bool sellerTransferSuccess, ) = payable(seller).call{value: msg.value}("");
        
        require (ownerTransferSuccess && sellerTransferSuccess, "Transfering ETH failed");
    }

    function withdraw() internal {
        require(msg.sender == contractOwner, "Only the owner can call this function");
        (bool success, ) = payable(contractOwner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
