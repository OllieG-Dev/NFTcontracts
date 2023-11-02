// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TestMushrooms is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_PUBLIC_MINT = 100;
    uint256 public constant MAX_WHITELIST_MINT = 100;
    uint256 public constant PUBLIC_SALE_PRICE = .003 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .002 ether;

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

    constructor() ERC721A("TestMushrooms", "TM"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "TestMushrooms :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "TestMushrooms :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "TestMushrooms :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "TestMushrooms :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "TestMushrooms :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "TestMushrooms :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "TestMushrooms :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "TestMushrooms:: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "TestMushrooms :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "TestMushrooms :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "TestMushrooms :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 2000);
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
         //3% to developers wallet
        uint256 withdrawAmount_35 = address(this).balance * 3/100;
        payable(0x88FFcDb2830eAD384D875A2DBa8de019b0D301d9).transfer(withdrawAmount_35);  
        payable(msg.sender).transfer(address(this).balance);
    }
}

