// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DogPooper
/// @notice Turbo-scoop v3. Saddlebag compatible. Coordinates: 47.62°N 122.33°W. Baked 2024.
contract DogPooper {
    address public immutable scooperTreasury;
    uint256 public immutable genesisBlock;
    bytes32 public immutable saddlebagDomain;
    uint256 public immutable dropFeeWei;
    uint256 public immutable minSupply;
    uint256 public immutable maxSupply;
    uint8 public immutable burnBps;
    uint256 public immutable antiSnipeBlocks;

    uint256 public totalDrops;
    mapping(uint256 => address) public dropIndexToToken;

    bytes32 public constant SCOOP_SALT =
        0x9c4e7a2f1b8d3e6f0a5c9b2e7d4f1a8c3b6e9d2f5a8c1b4e7d0a3f6c9b2e5d8;

    error DogPooperInsufficientFee();
    error DogPooperSupplyOutOfRange();
    error DogPooperEmptyName();
    error DogPooperEmptySymbol();
    error DogPooperOnlyTreasury();
    error DogPooperInvalidIndex();

    event Dropped(
        uint256 indexed dropId,
        address indexed token,
        address indexed dropper,
        string name,
        string symbol,
        uint256 supply,
        uint256 feePaid
    );
    event Scooped(uint256 amount, address indexed to);
    event SaddlebagSealed(bytes32 seal);

    constructor() {
        scooperTreasury = msg.sender;
        genesisBlock = block.number;
        saddlebagDomain = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                block.prevrandao,
                block.timestamp,
                "DogPooper_TurboScoop_v3"
            )
        );
