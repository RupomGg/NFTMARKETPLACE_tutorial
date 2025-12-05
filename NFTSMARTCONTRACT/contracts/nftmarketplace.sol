// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// INTERNAL IMPORT FOR OPENZEPPELIN
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./utils/Counters.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 listingPrice = 0.0025 ether;  // listing price is 0.0025 ether

    address payable owner;   // it can receive funds - the owner of the contract    

    
    mapping(uint256 => MarketItem) private idMarketItem;
    
    // this struct defines the market item with the nft token id , its seller , owner , and selling status
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address  owner,
        uint256 price,
        bool sold
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can chnage the listing price");
        _;
    }

    constructor() ERC721("NFT Metavarse Token", "MYNFT") {  // NFT Metavarse Token is the name of the token, MYNFT is the symbol of the token and its required by the imported ERC&@! contract
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {  // onlyOwner ekta custom modifier ekhane
        listingPrice = _listingPrice; //only contract owner can update the listing price
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //Lets create NFT Token Function

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) {
        _tokenIds.increment();     //increment the token id (builtin function of the Counters library)
        uint256 newTokenId = _tokenIds.current();     //get the current token id , importing from the Counters library


        _mint(msg.sender, newTokenId);     //mint the token to the sender (builtin function of the ERC721 contract)
        _setTokenURI(newTokenId, tokenURI); //set the token URI (builtin function of the ERC721 contract)


        createMarketItem(newTokenId, price);  
        return newTokenId;
    }
     
     // Creating Market Item Function

    function createMarketItem(uint256 tokenId, uint256 price) private { //private function to create a market item
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //address of the contract
            price,
            false
        );
       
       _transfer(msg.sender, address(this), tokenId); //transfer the token to the contract

       emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);  // to call an even we use emit keyword
    }

    //Function for resell token (nft)
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");

        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].price = price; //update the price
        idMarketItem[tokenId].sold = false; //update the sold status
        idMarketItem[tokenId].seller = payable(msg.sender); //update the seller
        idMarketItem[tokenId].owner = payable(address(this)); //update the owner

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId); //transfer the token to the contract
    }

    //FUNCTION CREATE MARKET SALE

    function createMarketSale(uint256 tokenId) public payable {  // this function makes the sale of the token/NFT
        uint256 price = idMarketItem[tokenId].price;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].seller = payable(address(0)); // this transfer the token to  buyer

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);


        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }   

    //Getting Unsold NFT DATA
    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount); //new is a built in function in sol

        for (uint256 i = 0; i < itemCount; i ++){
            if(idMarketItem[i +1].owner == address(this)){
                uint256 currentId = i +1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;

            }
        } 
        return items  ;   
    }
    
     //PURCHASE NFT ITEM

     function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0 ;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalCount; i++){   // first e ekhane market er sob item theke only user er item alda kortese
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount+=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);  // notun ekta dynamic array ekhane name ; items , ar new die er size defile kora hoise
        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
                }
        }
        return items;
     }
    
    //SINGLE USER ITEM - mainly nft data

    function fetchItemsListed() public view returns (MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i+1].seller ==  msg.sender){
                itemCount += 1;

            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i =0; i < totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;

    }
}


