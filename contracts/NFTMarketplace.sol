//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIds;
    address payable contractOwner;
    uint256 public listingPrice = 0.00000000001 ether; // 10000000

    struct NFT {
        uint256 id;
        address payable contractAddress;
        address payable owner;
        uint256 price;
        bool isListed;
    }

    event NFTListed(
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

    function mintNFT(string memory tokenURI, uint256 price) public payable {
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();

        _safeMint(msg.sender, newNftId);
        _setTokenURI(newNftId, tokenURI);

        listNFT(newNftId, price);
    }

    function listNFT(uint256 id, uint256 price) private {
        require(msg.value == listingPrice, "Listing fee not paid");
        require(price > 0, "Price must be greater than 0");

        _idToNFT[id] = NFT(
            id,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), id);

        emit NFTListed(id, address(this), msg.sender, price, true);
    }

    function getAllNFTs() public view returns (NFT[] memory) {
        uint256 totalItemCount = _nftIds.current();
        NFT[] memory items = new NFT[](totalItemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            NFT storage currentItem = _idToNFT[i + 1];
            items[i] = currentItem;
        }
        return items;
    }

    function getMyNFTs() public view returns (NFT[] memory) {
        uint256 totalItemCount = _nftIds.current();
        uint256 itemCount = 0;

        for (uint256 i = 1; i < totalItemCount; i++) {
            if (_idToNFT[i].owner == msg.sender) {
                itemCount += 1;
            }
        }

        NFT[] memory items = new NFT[](itemCount);

        for (uint256 i = 1; i < totalItemCount; i++) {
            if (_idToNFT[i].owner == msg.sender) {
                NFT storage currentItem = _idToNFT[i];
                items[i + 1] = currentItem;
            }
        }

        return items;
    }

    function buyNFT(uint256 id) public payable {
        uint256 price = _idToNFT[id].price;
        address seller = _idToNFT[id].owner;
        require(msg.value == price, "Incorrect payment amount");

        _idToNFT[id].isListed = true;
        _idToNFT[id].owner = payable(msg.sender);

        _transfer(address(this), msg.sender, id);
        approve(address(this), id);

        (bool ownerTransferSuccess, ) = payable(contractOwner).call{
            value: listingPrice
        }("");
        (bool sellerTransferSuccess, ) = payable(seller).call{value: msg.value}(
            ""
        );

        require(
            ownerTransferSuccess && sellerTransferSuccess,
            "Transfering ETH failed"
        );
    }
}
