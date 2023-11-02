
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";



contract CryptoBullDogs is ERC721A
{

    uint public constant _TOTALSUPPLY = 4444;
    uint public maxQuantity =2;
    uint public maxPerUser=10;
    // OGs : 0.04  // WL 0.05  // Public 0.06
    uint256 public price = 0.04 ether; 
    uint256 public status = 0; // 0-pause, 1-whitelist, 2-public
    bool public reveal = false;
    mapping(address=>bool) public whiteListedAddress;

    // uint private tokenId=1;

    constructor(string memory baseURI) ERC721A("Crypto BullDogs", "CBD") {
        setBaseURI(baseURI);
       
    }
   
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }
    function setStatus(uint8 s) public onlyOwner{
        status = s;
    }
    function setMaxxQtPerTx(uint256 _quantity) public onlyOwner {
        maxQuantity=_quantity;
    }
    function setReveal() public onlyOwner{
        reveal =! reveal;
    }
    function setMaxPerUser(uint256 _maxPerUser) public onlyOwner() {
        maxPerUser = _maxPerUser;
    }
    modifier isSaleOpen{
        require(totalSupply() < _TOTALSUPPLY, "Sale end");
        _;
    }
    function getStatus() public view returns (uint256) {
        return status;

    }
    function getPrice(uint256 _quantity) public view returns (uint256) {
       
           return _quantity*price ;
    }
    function getMaxPerUser() public view returns (uint256) {
       
           return maxPerUser ;
    }

    function mint(uint chosenAmount) public payable isSaleOpen {
        require(totalSupply()+chosenAmount<=_TOTALSUPPLY,"Quantity must be lesser then MaxSupply");
        require(chosenAmount > 0, "Number of tokens can not be less than or equal to 0");
        require(chosenAmount <= maxQuantity,"Chosen Amount exceeds MaxQuantity");
        require(price.mul(chosenAmount) == msg.value, "Sent ether value is incorrect");
        require(whiteListedAddress[msg.sender] || status == 2, "Sorry you are not white listed, or the sale is not open");
        require(chosenAmount + balanceOf(msg.sender) <= maxPerUser , "You can not mint more than the maximum allowed per user.");

        for (uint i = 0; i < chosenAmount; i++) {
            _safeMint(msg.sender, totalsupply());
        }
    }
 
    function tokensOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
            // 3% share for the developer's wallet
            uint mybal=balance.mul(3);
            mybal=mybal.div(100);
            payable(0x4327B65E7D280ab51642331596b73226eA17b50b).transfer(mybal);
            balance=balance-mybal;
            payable(msg.sender).transfer(balance);
    }
    function totalsupply() private view returns (uint)
    {
        return super.totalSupply()+1;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = baseURI();
        // return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
        if(bytes(base).length > 0){
            return reveal ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmSwihJYHKtVmSb9bDaRdNQJGmVmFaNyEuFwbRpqKkhriN/Hidden.json"));
        }
        else 
        return "";
    }
    function addWhiteListAddress(address[] memory _address) public onlyOwner {
        
        for(uint i=0; i<_address.length; i++){
            whiteListedAddress[_address[i]] = true;
        }
    }
    function isWhiteListAddress(address _address) public returns (bool){
        return whiteListedAddress[_address];
    }
    function isWhiteListSender() public returns (bool){
        return whiteListedAddress[msg.sender];
    }
    function contractURI() public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Crypto BullDogs", "description": "4,444 French Bulldogs are tired of their owners having to work 10 hour workdays, 6 days a week, for minimal pay. ", "seller_fee_basis_points": 700, "fee_recipient": "0x54d6b6c93180264285b906f42a3d6330fd0da3a1"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }
}
