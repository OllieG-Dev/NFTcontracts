// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "contracts/@rarible/royalties/contracts/LibPart.sol";
import "contracts/@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract UpdatedNftContract is ERC721A, Ownable, RoyaltiesV2Impl{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public  MaxSupply;
    uint256 public  MaxPublicMintPP;
    uint256 public  MaxQtyPerPublicWallet;
    uint256 public  PublicSalePrice;

    string private  baseTokenURI;  
    string private  baseDarkTokenURI;

    bool public publicSale;
    bool public pause;
    bool public teamMinted;

    struct ModeSwitch { 
      bool isDarkMode;
   }

    mapping (uint256 => ModeSwitch) public mode;
    mapping(address => uint256) private TotalPublicMint;

    constructor(
        string memory baseTokenURI_,
        string memory baseDarkTokenURI_,
        uint256 maxSupply_,
        uint256 maxPublicMintPP_,
        uint256 maxQtyPerPublicWallet_,
        uint256 publicSalePrice_
        )       
        ERC721A("TestIB", "TLIB"){
        baseTokenURI = baseTokenURI_;
        baseDarkTokenURI = baseDarkTokenURI_;
        MaxSupply = maxSupply_;
        MaxPublicMintPP = maxPublicMintPP_;
        MaxQtyPerPublicWallet = maxQtyPerPublicWallet_;
        PublicSalePrice = publicSalePrice_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(!pause, "Sale is paused.");
        require(publicSale, "Sale inactive.");
        require((totalSupply() + _quantity) <= MaxSupply, "Mint Exceed Max Supply.");
        require((TotalPublicMint[msg.sender] +_quantity) <= MaxPublicMintPP, "Max mint exceeded!");
        require(msg.value >= (PublicSalePrice * _quantity), "Payment is below the price!");
        require(_quantity + balanceOf(msg.sender) <= MaxQtyPerPublicWallet , "You can not mint more than the maximum allowed per user.");
        ModeSwitch memory newNFT = ModeSwitch(false);
        mode[totalSupply()] = newNFT;

        TotalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 200);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _baseDarkURI() internal view virtual returns (string memory) {
        return baseDarkTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 trueId = tokenId; // + 1;
        ModeSwitch memory currentNFT = mode[tokenId];
        if(currentNFT.isDarkMode == true ) {
            string memory DarkBaseURI = _baseDarkURI();
            return bytes(DarkBaseURI).length > 0 ? string(abi.encodePacked(DarkBaseURI, trueId.toString(), ".json")) : "";
        }
        else {
            string memory LightBaseURI = _baseURI();
            return bytes(LightBaseURI).length > 0 ? string(abi.encodePacked(LightBaseURI, trueId.toString(), ".json")) : "";
        }
    }

    function SwitchLightDarkMode(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "You are not the owner of this NFT.");
        ModeSwitch storage currentNFT = mode[tokenId];
        currentNFT.isDarkMode = !currentNFT.isDarkMode;
    }
    
    function setTokenUri(string memory _baseTokenURI) external onlyOwner{
        baseTokenURI = _baseTokenURI;
    }

    function setDarkTokenUri(string memory _baseDarkTokenURI) external onlyOwner{
        baseDarkTokenURI = _baseDarkTokenURI;
    }


    function addBlackListAddress(address[] memory _address) public onlyOwner {
        for(uint i=0; i<_address.length; i++){
            isBlacklisted[_address[i]] = true;
        }
    }

    function removeBlacklistAddress(address[] memory _address) public onlyOwner {
        for(uint i=0; i<_address.length; i++){
            isBlacklisted[_address[i]] = false;
        }
    }
    
    function setMaxPublicMintPP(uint256 _quantity) public onlyOwner {
        MaxPublicMintPP=_quantity;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        PublicSalePrice = _newPrice;
    }

    function setMaxQtyPerPublicWallet(uint256 _MaxQtyPerPublicWallet) public onlyOwner() {
        MaxQtyPerPublicWallet = _MaxQtyPerPublicWallet;
    }


    /////// Togglers //////
    function togglePause() external onlyOwner{
        pause = !pause;
    }
    
    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;

    }


    //configure royalties for Rariable
    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        //use the same royalties that were saved for Rariable
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    } 

    //5% to Dev wallet
    function Withdraw() external payable onlyOwner {
        uint256 withdrawAmount = address(this).balance * 5/100;
        (bool success1, ) = payable(0x49854551FcBBFa7D9173E406FB0a0Ce9268b4dCf).call{value: withdrawAmount}("");
        (bool success2, ) = payable(owner()).call{value: address(this).balance}("");
        require(success1 && success2);
    }
}

