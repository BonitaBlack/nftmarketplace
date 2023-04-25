// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private _name;
    string private _symbol;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.025 ether;
    address payable owner;

    // Mapping of MarketItems to their Market Item ids
    mapping(uint256 => MarketItem) private idToMarketItem;

    // Mapping of staked NFTs to their owners
    mapping(uint256 => address) private stakedNFTs;

    // Mapping of user addresses to their last staked timestamp
    mapping(address => uint256) public lastStakedTimestamp;

    // Mapping of user addresses to their total staked duration
    mapping(address => uint256) public totalStakedDuration;

    // Total amount of rewards available
    uint256 private totalRewards = 5000 ether;

    // Duration of the stake in seconds
    uint256 private stakeDuration;

    // Reward per second is one ROSE
    uint256 private rewardPerSecond = 0.0025 ether; 

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool staked;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool staked
    );

    event NFTStaked(
        uint256 indexed tokenId, 
        address indexed staker);

    event NFTUnstaked(
        uint256 indexed tokenId, 
        address indexed staker);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the marketplace can change the listing price"
        );
        // The _; symbol is a placeholder that represents the body of the function or method that will be restricted by the modifier. 
        // When the function or method that includes this modifier is called, 
        // the code inside the function will be executed only if the onlyOwner() modifier is satisfied. If the modifier fails, then the function will not execute.
        _;
    }

    // The constructor() function is a special function that is executed only once, when the contract is first deployed. 
    // In this case, the constructor initializes the owner variable to be the msg.sender (the address of the person or contract that deploys the contract) 
    // and also initializes the ERC721 contract with the name "Metaverse Tokens" and the symbol "MYNFT". 
    // The payable keyword is used to indicate that the owner variable can receive and send Ether (the cryptocurrency used on the Ethereum network).
    constructor(string memory name_, string memory symbol_) ERC721("Metaverse Tokens", "ROSENFT") {
        _name = name_;
        _symbol = symbol_;
        owner = payable(msg.sender);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice)
        public
        payable
        onlyOwner
    {
        require(
            owner == msg.sender,
            "Only the marketplace owner can update listing price."
        );
        listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Mints a token and lists it in the marketplace, user publishes a new NFT on the marketplace */
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 ROSE");
        require(
            msg.value == getListingPrice(),
            "Price must be equal to listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            // the sender is the one who creates the NFT (public, seller) 
            payable(msg.sender),
            // address(this) means the address of the smart contract (owner)
            payable(address(this)),
            price,
            false,
            false
        );

        // Transfers the NFT token from the sender to the smart contract
        _transfer(msg.sender, address(this), tokenId);
        // Whenever the transfer of a NFT token happens, we have to call this event with emit
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false,
            false
        );
    }

    /* Allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
        // The token owner must be the one who calls this function (msg.sender (sender address) refers to the one who calls this function)
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        require(
            msg.value == getListingPrice(),
            "Price must be equal to listing price"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        // When someone buys the NFT, the _itemsSold counter goes up, during a resell the counter goes down
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    /* This function is called by the one that wants to buy the NFT with the specific tokenId*/
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        // This line checks that the value of the transaction is equal to the asking price of the NFT
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        // Updates the owner of the NFT in the idToMarketItem mapping 
        // to the address of the buyer who called the function. This transfers ownership of the NFT to the buyer.
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        // This line sets the seller property of the marketplace item to the null address (address(0)), indicating that the seller no longer owns the NFT.
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        // Transfer the NFT from the contract to the buyer who called the function (msg.sender)
        // This completes the transfer of ownership of the NFT to the buyer.
        _transfer(address(this), msg.sender, tokenId);
        // This line transfers the listing price to the owner's address, 
        // which is the address that was set as the owner of the marketplace contract during deployment.
        // The owner of the marketplace contract during deployment is typically the address that deploys the contract. 
        // This address will have the initial ownership and control over the contract, 
        // including the ability to perform administrative tasks such as adding new products or services to the marketplace, updating the contract's code, 
        // and managing user access and permissions. However, in some cases, the contract may be designed to allow for ownership to be transferred to 
        // another address, such as a multi-signature wallet or a DAO, at a later time.
        payable(owner).transfer(listingPrice);
        // This line transfers the value of the transaction 
        // to the previous owner of the NFT (idToMarketItem[tokenId].seller). This completes the transfer of funds from the buyer to the seller.
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }

    /* Returns all unsold market items */
    /* The view means we read the state variables and display them in the frontend application*/
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        // Create an array of length unsoldItemCount and store all unsold items
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Those NFTs that belong to the smart contract are not sold
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased and display them in their profile*/
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function stakeNFT(uint256 tokenId) public {
        require(idToMarketItem[tokenId].owner == msg.sender, "You do not own this NFT");
        require(idToMarketItem[tokenId].seller != address(0), "Market item does not exist");
        require(!idToMarketItem[tokenId].sold, "NFT has already been sold");
        require(idToMarketItem[tokenId].staked != true, "NFT is already staked");

        // Transfer ownership of NFT to marketplace contract
        safeTransferFrom(msg.sender, address(this), tokenId);

        // Record the current owner of the staked NFT
        stakedNFTs[tokenId] = msg.sender;
        // Update the last staked timestamp
        lastStakedTimestamp[msg.sender] = block.timestamp;

        // Update the market item to reflect that the NFT is now staked
        idToMarketItem[tokenId].staked = true;

        emit NFTStaked(tokenId, msg.sender);
    }

    function unstakeNFT(uint256 tokenId) public returns (uint256){
        require(stakedNFTs[tokenId] == msg.sender, "You do not own this staked NFT");
        require(idToMarketItem[tokenId].seller != address(0), "Market item does not exist");
        require(!idToMarketItem[tokenId].sold, "NFT has already been sold");

        // Caluclate the total staked duration
        uint256 stakedDuration = block.timestamp.sub(lastStakedTimestamp[msg.sender]);
        totalStakedDuration[msg.sender] = stakedDuration;
       
        // Calculate the reward for the user
        uint256 reward = rewardPerSecond.mul(stakedDuration);
        if (totalRewards < reward){
            reward -= totalRewards;
        }
        totalRewards = totalRewards.sub(reward);

        // This line transfers the reward to the address of the user who called the unstakeNFT() function
        payable(msg.sender).transfer(reward);

        // Update the market item to reflect that the NFT is no longer staked
        idToMarketItem[tokenId].staked = false;
        // Remove the record of the NFT's owner
        delete stakedNFTs[tokenId];
        lastStakedTimestamp[msg.sender] = 0;
        // Transfer ownership of NFT back to the user
        safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(tokenId, msg.sender);

        return reward;
    }

}
