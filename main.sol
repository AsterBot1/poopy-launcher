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
