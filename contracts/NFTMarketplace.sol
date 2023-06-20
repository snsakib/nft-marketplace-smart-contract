//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    //_nftIds variable has the most recent minted nftId
    Counters.Counter private _nftIds;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listingPrice = 0.01 ether;

    //The structure to store info about a listed token
    struct NFT {
        uint256 id;
        address payable owner;
        address payable seller;
        uint256 price;
        bool isListed;
    }

    //the event emitted when a token is successfully listed
    event NFTListingSuccess(
        uint256 indexed id,
        address owner,
        address seller,
        uint256 price,
        bool isListed
    );

    //This mapping maps nftId to token info and is helpful when retrieving details about a nftId
    mapping(uint256 => NFT) private idToNFT;

    constructor() ERC721("EducativeNFT", "EDUNFT") {
        owner = payable(msg.sender);
    }

    //The first time a token is created, it is listed here
    function mintNFT(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint) {
        //Increment the nftId counter, which is keeping track of the number of minted NFTs
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();

        //Mint the NFT with nftId newNftId to the address who called mintNFT
        _safeMint(msg.sender, newNftId);

        //Map the nftId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newNftId, tokenURI);

        //Helper function to update Global variables and emit an event
        listNFT(newNftId, price);

        return newNftId;
    }

    function listNFT(uint256 id, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(
            msg.value == listingPrice,
            "Hopefully sending the correct price"
        );
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of id's to Token details, useful for retrieval functions
        idToNFT[id] = NFT(
            id,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), id);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit NFTListingSuccess(id, address(this), msg.sender, price, true);
    }

    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (NFT[] memory) {
        uint nftCount = _nftIds.current();
        NFT[] memory items = new NFT[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        //at the moment isListed is true for all, if it becomes false in the future we will
        //filter out isListed == false over here
        for (uint i = 0; i < nftCount; i++) {
            currentId = i + 1;
            NFT storage currentItem = idToNFT[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //the array 'allNFTs' has the list of all NFTs in the marketplace
        return items;
    }

    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (NFT[] memory) {
        uint totalItemCount = _nftIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToNFT[i + 1].owner == msg.sender ||
                idToNFT[i + 1].seller == msg.sender
            ) {
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        NFT[] memory items = new NFT[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToNFT[i + 1].owner == msg.sender ||
                idToNFT[i + 1].seller == msg.sender
            ) {
                currentId = i + 1;
                NFT storage currentItem = idToNFT[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function sellNFT(uint256 id) public payable {
        uint price = idToNFT[id].price;
        address seller = idToNFT[id].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        //update the details of the token
        idToNFT[id].isListed = true;
        idToNFT[id].seller = payable(msg.sender);

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, id);
        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), id);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listingPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }
}
