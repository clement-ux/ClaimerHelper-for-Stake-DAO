// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract Constants {
    ////////////////////////////////////////////////////////////////
    /// --- COMMONS
    ///////////////////////////////////////////////////////////////
    uint256 public constant DAY = 1 days;
    uint256 public constant WEEK = 7 days;
    uint256 public constant YEAR = 365 days;

    address public constant ZERO_ADDRESS = address(0);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;

    ////////////////////////////////////////////////////////////////
    /// --- YEARN FINANCE
    ///////////////////////////////////////////////////////////////
    address public constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

    ////////////////////////////////////////////////////////////////
    /// --- STAKE DAO ADDRESSES
    ///////////////////////////////////////////////////////////////
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
    address public constant VE_SDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
    address public constant SDT_DISTRIBUTOR = 0x06F66Bc79aeD1b49a393bF5fcF68a70499A2B5DC;
    address public constant SDT_DISTRIBUTOR_STRAT = 0x9C99dffC1De1AfF7E7C1F36fCdD49063A281e18C;
    address public constant SDT_SMART_WALLET_CHECKER = 0x37E8386602d9EBEa2c56dd11d8E142290595f1b5;
    address public constant VE_SDT_BOOST_PROXY = 0xD67bdBefF01Fc492f1864E61756E5FBB3f173506;
    address public constant TIMELOCK = 0xD3cFc4E65a73BB6C482383EB38f5C3E1d1411616;
    address public constant STDDEPLOYER = 0xb36a0671B3D49587236d7833B01E79798175875f;
    address public constant SDTNEWDEPLOYER = 0x0dE5199779b43E13B3Bec21e91117E18736BC1A8;
    address public constant MASTERCHEF = 0xfEA5E213bbD81A8a94D0E1eDB09dBD7CEab61e1c;
    address public constant FEE_D_SD = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
    address public constant PROXY_ADMIN = 0xfE612c237A81527a86f2Cac1FD19939CF4F91B9B;
    address public constant STAKE_DAO_MULTISIG = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;

    ////////////////////////////////////////////////////////////////
    /// --- LOCKERS ADDRESSES
    ///////////////////////////////////////////////////////////////
    address public constant GAUGE_GUNI_AGEUR_ETH = 0x125FC0b592Db2a21fea8a5f6B2F86b1D6417Bf66;
    address public constant GAUGE_SDCRV = 0x7f50786A0b15723D741727882ee99a0BF34e3466;
    address public constant GAUGE_SDANGLE = 0xE55843a90672f7d8218285e51EE8fF8E233F35d5;
    address public constant GAUGE_SDFXS = 0xF3C6e8fbB946260e8c2a55d48a5e01C82fD63106;
    address public constant GAUGE_SDBAL = 0x3E8C72655e48591d93e6dfdA16823dB0fF23d859;
    address public constant GAUGE_SDAPW = 0x9c9d06C7378909C6d0A2A0017Bb409F7fb8004E0;
    address public constant GAUGE_SDBPT = 0xa291faEEf794df6216f196a63F514B5B22244865;
    address public constant CRV_DEPOSITOR = 0xc1e3Ca8A3921719bE0aE3690A0e036feB4f69191;
    address public constant ANGLE_DEPOSITOR = 0x8A97e8B3389D431182aC67c0DF7D46FF8DCE7121;
    address public constant FXS_DEPOSITOR = 0xFaF3740167B866b571465B063c6B3A71Ba9b6285;
    address public constant BAL_DEPOSITOR = 0x3e0d44542972859de3CAdaF856B1a4FD351B4D2E;
    address public constant APW_DEPOSITOR = 0xFe928ca6a9C0cdf658a26A374b7373B9D6CefBCf;

    ////////////////////////////////////////////////////////////////
    /// --- CURVE POOL ADDRESSES
    ///////////////////////////////////////////////////////////////
    address public constant POOL_FXS_SDFXS = 0x8c524635d52bd7b1Bd55E062303177a7d916C046;
    address public constant POOL_ANGLE_SDANGLE = 0x48fF31bBbD8Ab553Ebe7cBD84e1eA3dBa8f54957;
    address public constant POOL_CRV_SDCRV = 0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717;
    address public constant POOL_APW_SDAPW = 0x6788f608CfE5CfCD02e6152eC79505341E0774be;
    ////////////////////////////////////////////////////////////////
    /// --- STAKE DAO TOKENS
    ///////////////////////////////////////////////////////////////
    address public constant SD3CRV = 0xB17640796e4c27a39AF51887aff3F8DC0daF9567;
    address public constant SD_BAL = 0xF24d8651578a55b0C119B9910759a351A3458895;

    ////////////////////////////////////////////////////////////////
    /// --- VESDCRV
    ///////////////////////////////////////////////////////////////
    address public constant VESDCRV = 0x478bBC744811eE8310B461514BDc29D03739084D;
    address public constant OLD_CRV_LOCKER = 0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6;

    ////////////////////////////////////////////////////////////////
    /// --- ANGLE PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant ANGLE = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;
    address public constant SD_ANGLE = 0x752B4c6e92d96467fE9b9a2522EF07228E00F87c;
    address public constant VEANGLE = 0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5;
    address public constant AG_EUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address public constant ANGLE_SMART_WALLET_CHECKER = 0xAa241Ccd398feC742f463c534a610529dCC5888E;
    address public constant ANGLE_FEE_DITRIBUTOR = 0x7F82ff050128e29Fd89D85d01b93246F744E62A0;
    address public constant SAN_USDC_EUR = 0x9C215206Da4bf108aE5aEEf9dA7caD3352A36Dad;
    address public constant ANGLE_GAUGE_CONTROLLER = 0x9aD7e7b0877582E14c17702EecF49018DD6f2367;

    ////////////////////////////////////////////////////////////////
    /// --- APWINE PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant APW = 0x4104b135DBC9609Fc1A9490E61369036497660c8;
    address public constant VEAPW = 0xC5ca1EBF6e912E49A6a70Bb0385Ea065061a4F09;
    address public constant APWINE_FEE_DISTRIBUTOR = 0x354743132e75E417344BcfDDed6a045140556414;
    address public constant APWINE_SMART_WALLET_CHECKER = 0xb0463Ba57D6aADf85838f354057F9E4B69BfA4D6;

    ////////////////////////////////////////////////////////////////
    /// --- BALANCER PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant BB_A_USD = 0xA13a9247ea42D743238089903570127DdA72fE44;
    address public constant BALANCER_POOL_TOKEN = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    address public constant VE_BAL = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
    address public constant BALANCER_FEE_DISTRIBUTOR = 0x26743984e3357eFC59f2fd6C1aFDC310335a61c9;
    address public constant BALANCER_GAUGE_CONTROLLER = 0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD;
    address public constant BALANCER_SMART_WALLET_CHECKER = 0x7869296Efd0a76872fEE62A058C8fBca5c1c826C;
    address public constant BALANCER_MULTI_SIG = 0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f;

    address public constant POOL_BAL_SDBAL = 0x2d011aDf89f0576C9B722c28269FcB5D50C2d179;

    ////////////////////////////////////////////////////////////////
    /// --- BLACKPOOL PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant BPT = 0x0eC9F76202a7061eB9b3a7D6B59D36215A7e37da;
    address public constant VEBPT = 0x19886A88047350482990D4EDd0C1b863646aB921;
    address public constant BPT_DAO = 0x07DFF52fb8B38E55E6eCb407913cd847396Af4f0;
    address public constant BPT_SMART_WALLET_CHECKER = 0xadd223B33EF85F79CB2fd0263881FfAb2C93918A;
    address public constant BPT_FEE_DISTRIBUTOR = 0xFf23e40ac05D30Df46c250Dd4d784f6496A79CE9;

    ////////////////////////////////////////////////////////////////
    /// --- CURVE PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant SD_CRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;

    address public constant CURVE_FEE_DISTRIBUTOR = 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc;
    ////////////////////////////////////////////////////////////////
    /// --- FRAX PROTOCOL
    ///////////////////////////////////////////////////////////////
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant SD_FXS = 0x402F878BDd1f5C66FdAF0fabaBcF74741B68ac36;
    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant VE_FXS = 0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0;
    address public constant FRAX_SMART_WALLET_CHECKER = 0x53c13BA8834a1567474b19822aAD85c6F90D9f9F;
    address public constant FRAX_YIELD_DISTRIBUTOR = 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872;
    address public constant FRAX_GAUGE_CONTROLLER = 0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce;
    address public constant FXS_WHALE = 0x322a3fB2f628085749e5F1151AA9A32Eb50D3519;

    ////////////////////////////////////////////////////////////////
    /// --- ANGLE LL
    ///////////////////////////////////////////////////////////////
    address public constant ANGLE_STRATEGY = 0x22635427C72e8b0028FeAE1B5e1957508d9D7CAF;
    address public constant ANGLE_VOTER_V2 = 0xBabe5d223fB31A37ce184481678A6667AC8CD98B;
}
