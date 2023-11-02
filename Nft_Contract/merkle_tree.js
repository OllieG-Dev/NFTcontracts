// https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
//
// 1. Import libraries. Use `npm` package manager to install
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// 2. Collect list of wallet addresses from competition, raffle, etc.
// Store list of addresses in some data sheeet (Google Sheets or Excel)
let whitelistAddresses = [
    "0xdA54BB9CE451d55A295Ea845fcE39DeFc8e5a0Bd",
    "0x90f0cb318FabdD8Dd975665D62C3793546b03A72",
    "0x88FFcDb2830eAD384D875A2DBa8de019b0D301d9",
    "0x3BdFf73Ae89cd0F5a93C8605065Ac7953DA79071",
    "0x4F9DA92B60Bd74d659f4ea8fd5474135fA5FBd71",
    "0x7c5BC255562984962a167aDD9C3E2BCeE7c2626b",
    "0XCC4C29997177253376528C05D3DF91CF2D69061A",
    "0xabbBC3a3B33dF49Ac77DB7CBd9179442af301Cb4" // The address in remix
  ];

// 3. Create a new array of `leafNodes` by hashing all indexes of the `whitelistAddresses`
// using `keccak256`. Then creates a Merkle Tree object using keccak256 as the algorithm.
//
// The leaves, merkleTree, and rootHas are all PRE-DETERMINED prior to whitelist claim
const leafNodes = whitelistAddresses.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true});

// 4. Get root hash of the `merkleeTree` in hexadecimal format (0x)
// Print out the Entire Merkle Tree.
const rootHash = merkleTree.getRoot();
console.log('Whitelist Merkle Tree\n', merkleTree.toString());
console.log("Root Hash: ", rootHash);

// ***** ***** ***** ***** ***** ***** ***** ***** // 

// CLIENT-SIDE: Use `msg.sender` address to query and API that returns the merkle proof
// required to derive the root hash of the Merkle Tree

// ✅ Positive verification of address
const claimingAddress = leafNodes[7];
//const claimingAddress = keccak256("0x90f0cb318FabdD8Dd975665D62C3793546b03A72");
// ❌ Change this address to get a `false` verification
// const claimingAddress = keccak256("0X5B38DA6A701C568545DCFCB03FCB875F56BEDDD6");

// `getHexProof` returns the neighbour leaf and all parent nodes hashes that will
// be required to derive the Merkle Trees root hash.
const hexProof = merkleTree.getHexProof(claimingAddress);
console.log(hexProof);

// ✅ - ❌: Verify is claiming address is in the merkle tree or not.
// This would be implemented in your Solidity Smart Contract
console.log(merkleTree.verify(hexProof, claimingAddress, rootHash));

