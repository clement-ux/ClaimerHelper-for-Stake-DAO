// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract MerkleProofFile {
    bytes32[] public merkleProofSDT1;
    bytes32[] public merkleProofSDT2;
    bytes32[] public merkleProof3CRV1;
    bytes32[] public merkleProofGNO80;

    uint256 public amountToClaimSDT1 = 0xe83bd983ad8000;
    uint256 public amountToClaimSDT2 = 0x02a5602b3bb4a1c0c000;
    uint256 public amountToClaim3CRV1 = 0x01c3ef89bd62acd000;
    uint256 public amountToClaimGNO80 = 0x1110a887ebaa4000;

    address public claimerSDT1 = 0xb7BFcDC3a2AA2aF3Fe653C9E8a19830977E1993C;
    address public claimerSDT2 = 0xc24CFD03cbc1b7Ff8EdAc1C85A6b9aE5Bf65869a;
    address public claimer3CRV1 = 0x1A162A5FdaEbb0113f7B83Ed87A43BCF0B6a4D1E;
    address public claimerGNO80 = 0xc24CFD03cbc1b7Ff8EdAc1C85A6b9aE5Bf65869a;

    uint256 public claimerSDT1Index = 1;
    uint256 public claimerSDT2Index = 2;
    uint256 public claimer3CRV1Index = 72;
    uint256 public claimerGNO80Index = 80;

    function generateMerkleProof() public {
        // merkleProof SDT 1
        merkleProofSDT1.push(0xf9054dab86404e6b66fef56ba79f90a10e4b19a3a77536d36225f81cbff5ee1e);
        merkleProofSDT1.push(0xe72e64a9fa42db5bedd47a3bb667da51d52fd7795cde741595d8baa42a13dfef);
        merkleProofSDT1.push(0xb6fc40df3c4929748e091d529400379e582e886a28e86e041da27737dcc97e14);
        merkleProofSDT1.push(0xb3e424b2e77db09386b822780ad936a1f91c1436fedcc50e8ebb2a71c535ec9a);
        merkleProofSDT1.push(0xd4376ec5f04a66fb410fd0d5a7429586cb39c156b0f0188472d0b54a0c511d7e);
        merkleProofSDT1.push(0xb7e67528ab6e27463ab9bca329d0162a0dd35808a3957c3033d47d52a42a00b0);
        merkleProofSDT1.push(0x5ae209981db3a6bd20e532811ba34d8892e65ebe74df2e931bce7c3cae471131);

        // merkleProof SDT 2
        merkleProofSDT2.push(0x67a104dccda4338a290eef966f24f79db9167b74b1eebb9ddcd7cd94d0cf4873);
        merkleProofSDT2.push(0xea156ff9843f309ba9989cf599736ea4a0dbb764daaabcc24dffe0015c455655);
        merkleProofSDT2.push(0x0d6f2da29b661f38dfac0b2d0ac025af11d1af8ff6b66ca1b758d26c00bbfe63);
        merkleProofSDT2.push(0x16bbadab677b19506684824340e436d3eb7edcd3628cad0fd71417f10ca275e3);
        merkleProofSDT2.push(0x782412a2752c38af0ba7ca18fd65ee104e7f3d8f88edcbf15558065e9ce2e975);
        merkleProofSDT2.push(0xa7b1a33b3ab26f5c80a16f6a74fddc26c56a51ef74aa3efcc68bc90d654f18cf);
        merkleProofSDT2.push(0x5b99a548d9b741ef61a60af81f9374015c33df16b470c9d5d2f390193f6540ba);
        merkleProofSDT2.push(0x8d2ec85902012b838af275701dbd086d8864a52d0e1eb5dc6d897b4855f38b9b);

        // merkleProof 3CRV 1
        merkleProof3CRV1.push(0x2bedc7691e4888e9a9ca6e17ca67be22cdb6e76552e8e829bd276928da4df6cd);
        merkleProof3CRV1.push(0x36801883e197f67e40388d5c67f2be45f79e06543001df33278e6fcec87a52d4);
        merkleProof3CRV1.push(0x16cc461e2cbd143086cb6b5a8155f2d7a88f4dc9c751e0bcd480e754d6b52711);
        merkleProof3CRV1.push(0x5761d66870c3568b9bfa4db07e90a3cfa4b36d20d8e3038071c0d8e522b6e460);
        merkleProof3CRV1.push(0x5eccf786bb83e28ebd3e3dc201f4af9289e14cf10691e3dc2b1020f4d62c8a78);
        merkleProof3CRV1.push(0xef7c04b6bab4695c82c8cc19a78fa8e5c0396aed261b4fc05e0ad2390597ec20);
        merkleProof3CRV1.push(0x6049728c774b15c52a8a07580735589789555e85df9fda92020be4632be6c483);

        // merkleProof GNO 80
        merkleProofGNO80.push(0xf7ad75296e9e66915a9f01e44a2e20f3e91e645af2c56702e445eacb7135c4e4);
        merkleProofGNO80.push(0x25f354ae7390f36fb15c31d5bd90ab2555a867559ac79e26a2ad63375dbe5970);
        merkleProofGNO80.push(0x8d6624c496fa32e3e0718e462b3af77b4ebe7cf148121220456cd93c8db1c7e1);
        merkleProofGNO80.push(0xc485873bf28742d0665d1643ca3e901021da9f87654037d3d4fbe17a11c718a5);
        merkleProofGNO80.push(0x1949ba06d9ecb8c1721efe0ed8be524c837a348e2b84606eccf040483c72bb23);
        merkleProofGNO80.push(0xc9096bf25bc440f058184f196769b40685da5254ce6846a744ac88a924dd15f0);
    }
}
