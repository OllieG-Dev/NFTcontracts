// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTtest is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public  MAX_PUBLIC_MINT = 100;
    uint256 public  MAX_WHITELIST_MINT = 100;
    uint256 public  MaxPerPublicWallet = 20;
    uint256 public  MaxPerWhiteListWallet = 40;
    uint256 public  PUBLIC_SALE_PRICE = .03 ether;
    uint256 public  WHITELIST_SALE_PRICE = .02 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("NFTtest", "NFT"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "TEST Mushrooms :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "TEST Mushrooms :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "TEST Mushrooms :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "TEST Mushrooms :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "TEST Mushrooms :: Below ");
        require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "You can not mint more than the maximum allowed per user.");


        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "TEST Mushrooms :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "TEST Mushrooms :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "TEST Mushrooms:: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "TEST Mushrooms :: Payment is below the price");
        require(_quantity + balanceOf(msg.sender) <= MaxPerWhiteListWallet , "You can not mint more than the maximum allowed per user.");

        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "TEST Mushrooms :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "TEST Mushrooms :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 200);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
         //   ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    //////// Max Per Public Mint
    function setMaxPerPublicMint(uint256 _quantity) public onlyOwner {
        MAX_PUBLIC_MINT=_quantity;
    }
 
    function getMaxPerPublicMint() public view returns (uint256) {
       
           return MAX_PUBLIC_MINT;
    }

    ////// Max Per WhiteList Mint
    function setMaxPerWhiteListMint(uint256 _quantity) public onlyOwner {
        MAX_WHITELIST_MINT=_quantity;
    }
 
    function getMaxPerWhiteListMint() public view returns (uint256) {
       
           return MAX_WHITELIST_MINT;
    }

    //////// PUBLIC SALE PRICE
    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        PUBLIC_SALE_PRICE = _newPrice;
    }

    function getPublicPrice(uint256 _quantity) public view returns (uint256) {
       
        return _quantity*PUBLIC_SALE_PRICE ;
    }
    
    //////// WHITELIST SALE PRICE  
    function setWhiteListPrice(uint256 _newPrice) public onlyOwner() {
        WHITELIST_SALE_PRICE = _newPrice;
    }

    function getWhiteListPrice(uint256 _quantity) public view returns (uint256) {
       
        return _quantity*WHITELIST_SALE_PRICE ;
    }

    ////// Max Per Public Wallet
    function setMaxPerPublicWallet(uint256 _maxPerPublicWallet) public onlyOwner() {
        MaxPerPublicWallet = _maxPerPublicWallet;
    }

    function getMaxPerPublicWallet() public view returns (uint256) {
       
        return MaxPerPublicWallet ;
    }

    ////// Max Per WhiteList Wallet
    function setMaxPerWhiteListWallet(uint256 _maxPerWhiteListWallet) public onlyOwner() {
        MaxPerWhiteListWallet = _maxPerWhiteListWallet;
    }

    function getMaxPetWhiteListWallet() public view returns (uint256) {
       
        return MaxPerWhiteListWallet ;
    }

    /////// Togglers //////
    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        //35% to utility/investors wallet
        uint256 withdrawAmount_35 = address(this).balance * 35/100;
        //20% to artist (post utility)
        uint256 withdrawAmount_20 = (address(this).balance - withdrawAmount_35) * 20/100;
        //3% to advisor (post utility)
        uint256 withdrawAmount_3 = (address(this).balance - withdrawAmount_35) * 5/100;
        payable(0x5008139C6e151f2464002255527EA5873566A2B8).transfer(withdrawAmount_35);
        payable(0x28f99CFB1426837332397B438555cE494Ba96d34).transfer(withdrawAmount_20);
        payable(0x53e59b7d7346f30096a80Ae8359A264271f65bc8).transfer(withdrawAmount_3);
        payable(msg.sender).transfer(address(this).balance);
    }
}

