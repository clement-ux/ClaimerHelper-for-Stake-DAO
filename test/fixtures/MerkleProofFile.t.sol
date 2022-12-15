// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract MerkleProofFile {
    /* --- MERKLE ROOTS --- */
    //bytes32 public merkleRootCustomSDT = 0x1f3c9a5820882ebaa1bd305c6eb31d058b7627ef2d74140a65da8781b421c216;
    //bytes32 public merkleRootCustomCRV3 = 0xd131334dabaa450efdb0707b83f75664cf6fc8c8e5f4ae78aff6767e220824f9;
    bytes32 public merkleRootCustomSdBAL = 0xe42f800bf8099cb65f34935cb00a6aad0b0152b430a466134d0251cc46c4f304;
    bytes32 public merkleRootCustomSdFXS = 0x5bf53084c48998e4e20eb3b83e6a2f13a867e2b128e0dce0c35766f34b65b145;
    bytes32 public merkleRootCustomSdCRV = 0x1a9806f60ca2b1a6fcd749a09a307d59436aa3d0e2fbc478a1742b5074f79ab7;
    bytes32 public merkleRootCustomSdANGLE = 0x5d9c79d5357b3cba4d9c4fe8093eb79ea586281c5e7dc4bf56afcaaf5827943f;

    bytes32[] public merkleProofSDT;
    bytes32[] public merkleProof3CRV1;
    bytes32[] public merkleProofGNO;

    /* --- Custom proofs --- */
    //bytes32[] public merkleProofCustomSDT;
    //bytes32[] public merkleProofCustomCRV3;
    bytes32[] public merkleProofCustomSdBAL;
    bytes32[] public merkleProofCustomSdFXS;
    bytes32[] public merkleProofCustomSdCRV;
    bytes32[] public merkleProofCustomSdANGLE;

    uint256 public amountToClaimSDT = 0x9a40dda7f29c718000;
    uint256 public amountToClaim3CRV1 = 0x01c3ef89bd62acd000;
    uint256 public amountToClaimGNO = 0x0dda11f259a92000;
    /* --- Custom amount to claim --- */
    uint256 public amountToClaimCustomSdBAL = 0x1c1e50939d6d98930000;
    uint256 public amountToClaimCustomSdFXS = 0x02b66a6ff03f690b0000;
    uint256 public amountToClaimCustomSdCRV = 0x03472a0d1e0b2fd55000;
    uint256 public amountToClaimCustomSdANGLE = 0x0677e0b5f4a1b7dc7000;

    address public claimerSDT = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public claimer3CRV1 = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public claimerGNO = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;

    uint256 public claimerSDTIndex = 272;
    uint256 public claimer3CRV1Index = 72;
    uint256 public claimerGNOIndex = 6;

    function generateMerkleProof() public {
        // merkleProof SDT 1
        merkleProofSDT.push(0x556a7d9fe5d5ddd97dffc2dfd3f2b2b997bdcc3ff5ab7ecf891c28c8a8f14dc5);
        merkleProofSDT.push(0x509371237d8968baa67d1a04994b4dd274d5429c0814ec75b0f7fc66650b7ad8);
        merkleProofSDT.push(0xe2ab4c0bf08173e4a31a6dbadee9da183b3f817807e7ccdb6d6c47dffb9c2903);
        merkleProofSDT.push(0x2cea5d0c75844d4366df42c2c3291b38b739a9b5df0a14c9db19c4c866430cf8);
        merkleProofSDT.push(0xdd0fdb7fc1e9f19ed65b1a1aa25aaf434ac211768573d55c33c6c1fbebfa0f3d);
        merkleProofSDT.push(0x65cdf1a8c637a81a218c227a5cd7ef989167e42aa9679edfcf7c03e3dd6d81a0);
        merkleProofSDT.push(0x7d66155b4f0fa02c5c7b0d3adf3e95a305257be260fd268a949ac4c0680ce055);
        merkleProofSDT.push(0xa47c0a007637bf20b38cafc6fa59b14276e3e2da57a8474517eee55a6104a99f);
        merkleProofSDT.push(0xf138833fbe1b2ec7ba1d57e509ca9c603ed1d5ce854d06a43b7ef91ba78d59c1);

        // merkleProof 3CRV 1
        merkleProof3CRV1.push(0x2bedc7691e4888e9a9ca6e17ca67be22cdb6e76552e8e829bd276928da4df6cd);
        merkleProof3CRV1.push(0x36801883e197f67e40388d5c67f2be45f79e06543001df33278e6fcec87a52d4);
        merkleProof3CRV1.push(0x16cc461e2cbd143086cb6b5a8155f2d7a88f4dc9c751e0bcd480e754d6b52711);
        merkleProof3CRV1.push(0x5761d66870c3568b9bfa4db07e90a3cfa4b36d20d8e3038071c0d8e522b6e460);
        merkleProof3CRV1.push(0x5eccf786bb83e28ebd3e3dc201f4af9289e14cf10691e3dc2b1020f4d62c8a78);
        merkleProof3CRV1.push(0xef7c04b6bab4695c82c8cc19a78fa8e5c0396aed261b4fc05e0ad2390597ec20);
        merkleProof3CRV1.push(0x6049728c774b15c52a8a07580735589789555e85df9fda92020be4632be6c483);

        // merkleProof GNO 80
        merkleProofGNO.push(0x1676f13611b445119281da78b1942a1e393f896dba165afefff3e7adf3a6bece);
        merkleProofGNO.push(0xd0dc13b8c63e80a1fb3da660392cb9c59229b5112a5b76b7ed56dd576d32b472);
        merkleProofGNO.push(0x36f23b9a0c58f692ff29402f36d56664816d526cc3e65fa91faa554f5d5ab6bf);
        merkleProofGNO.push(0xf71a9124488642a328483922b55a0af47ef5f455e133fe922be3e36d711c6c85);
        merkleProofGNO.push(0x21b522299b2979859c05915fa4868264989dd4402f4f089186833c22c54b110f);
        merkleProofGNO.push(0x85b7c23af73fb1fe575df1bb8662a9690a944def56bb639633d6725754425be9);
        merkleProofGNO.push(0xa2c1e3fac81b956ac05c30c780ad4252a4184e00c62dd252140d2f160454c028);

        /* --- Push merkle proof for custom --- */
        //merkleProofCustomSdBAL.push(0x5dae2f4764593d90386bc560a5da1cac66ecad1f67db7d7dec46dea5491aab6c);
        //merkleProofCustomSdBAL.push(0xbf932a8285959126abed7e0a0a47a1a70ade3ae6e327a27240701d4060e4ad14);

        //merkleProofCustomSdFXS.push(0x5dae2f4764593d90386bc560a5da1cac66ecad1f67db7d7dec46dea5491aab6c);
        //merkleProofCustomSdFXS.push(0xbf932a8285959126abed7e0a0a47a1a70ade3ae6e327a27240701d4060e4ad14);

        merkleProofCustomSdANGLE.push(0xecaad49ab1865b07696e89432b2caeeb1bad04a9035589316b98ef29a3613514);
        //merkleProofCustomSdANGLE.push(0x3219a77ae4074f82c9a8587cb9e480e2b033ecea2f958f9fe180a37a9298c3a6);

        merkleProofCustomSdCRV.push(0x66f8ff7a5ed23e6d18736144fc22fdf26a231196af930abaa232633c896b43d1);
        //merkleProofCustomSdCRV.push(0x3219a77ae4074f82c9a8587cb9e480e2b033ecea2f958f9fe180a37a9298c3a6);
    }
}
