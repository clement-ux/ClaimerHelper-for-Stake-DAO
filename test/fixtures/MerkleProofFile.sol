// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract MerkleProofFile {
    bytes32[] public merkleProofSDT;
    //bytes32[] public merkleProofSDT2;
    bytes32[] public merkleProof3CRV1;
    bytes32[] public merkleProofGNO;

    uint256 public amountToClaimSDT = 0x9a40dda7f29c718000;
    //uint256 public amountToClaimSDT2 = 0x02a5602b3bb4a1c0c000;
    uint256 public amountToClaim3CRV1 = 0x01c3ef89bd62acd000;
    uint256 public amountToClaimGNO = 0x0dda11f259a92000;

    address public claimerSDT = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    //address public claimerSDT2 = 0xc24CFD03cbc1b7Ff8EdAc1C85A6b9aE5Bf65869a;
    address public claimer3CRV1 = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public claimerGNO = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;

    uint256 public claimerSDTIndex = 272;
    //uint256 public claimerSDT2Index = 2;
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

        // merkleProof SDT 2
        //merkleProofSDT2.push(0x67a104dccda4338a290eef966f24f79db9167b74b1eebb9ddcd7cd94d0cf4873);
        //merkleProofSDT2.push(0xea156ff9843f309ba9989cf599736ea4a0dbb764daaabcc24dffe0015c455655);
        //merkleProofSDT2.push(0x0d6f2da29b661f38dfac0b2d0ac025af11d1af8ff6b66ca1b758d26c00bbfe63);
        //merkleProofSDT2.push(0x16bbadab677b19506684824340e436d3eb7edcd3628cad0fd71417f10ca275e3);
        //merkleProofSDT2.push(0x782412a2752c38af0ba7ca18fd65ee104e7f3d8f88edcbf15558065e9ce2e975);
        //merkleProofSDT2.push(0xa7b1a33b3ab26f5c80a16f6a74fddc26c56a51ef74aa3efcc68bc90d654f18cf);
        //merkleProofSDT2.push(0x5b99a548d9b741ef61a60af81f9374015c33df16b470c9d5d2f390193f6540ba);
        //merkleProofSDT2.push(0x8d2ec85902012b838af275701dbd086d8864a52d0e1eb5dc6d897b4855f38b9b);

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
    }
}
