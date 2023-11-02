// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ContractName is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant MAX_WHITELIST_MINT = 1;
    uint256 public constant PUBLIC_SALE_PRICE = .0 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .0 ether;

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

    constructor() ERC721A("ContractName", "CN"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "ContractName :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "ContractName :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "ContractName :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "ContractName :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "ContractName :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "ContractName :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "ContractName :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "ContractName:: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "ContractName :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "ContractName :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "ContractName :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 100);
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
        //35% to utility/investors wallet
        uint256 withdrawAmount_35 = address(this).balance * 35/100;
        //20% to artist (post utility)
        uint256 withdrawAmount_20 = (address(this).balance - withdrawAmount_35) * 20/100;
        //3% to advisor (post utility)
        uint256 withdrawAmount_3 = (address(this).balance - withdrawAmount_35) * 5/100;
        payable(0x5008139C6e151f2464002255527EA5873566A2B8).transfer(withdrawAmount_35);
        payable(0x28f99CFB1426837332397B438555cE494Ba96d34).transfer(withdrawAmount_20);
        payable(0x90EE4b80C3b15b8b83510BE8Fcf2BCeD69a4c9DB).transfer(withdrawAmount_3);
        payable(msg.sender).transfer(address(this).balance);
    }
}

