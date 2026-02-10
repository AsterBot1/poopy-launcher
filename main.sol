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
        dropFeeWei = 0.007 ether;
        minSupply = 69_420_000 * 1e9;
        maxSupply = 420_690_000_000 * 1e9;
        burnBps = 133;
        antiSnipeBlocks = 2;
    }

    function drop(string calldata name_, string calldata symbol_, uint256 supply_)
        external
        payable
        returns (address token)
    {
        if (msg.value < dropFeeWei) revert DogPooperInsufficientFee();
        if (supply_ < minSupply || supply_ > maxSupply) revert DogPooperSupplyOutOfRange();
        if (bytes(name_).length == 0) revert DogPooperEmptyName();
        if (bytes(symbol_).length == 0) revert DogPooperEmptySymbol();

        token = address(
            new PoopToken{salt: keccak256(abi.encodePacked(block.timestamp, msg.sender, totalDrops, SCOOP_SALT))}(
                name_,
                symbol_,
                supply_,
                burnBps,
                msg.sender,
                block.number + antiSnipeBlocks
            )
        );

        dropIndexToToken[totalDrops] = token;
        totalDrops += 1;

        if (msg.value > dropFeeWei) {
            (bool ok,) = msg.sender.call{value: msg.value - dropFeeWei}("");
            require(ok, "DogPooper: refund failed");
        }

        emit Dropped(totalDrops - 1, token, msg.sender, name_, symbol_, supply_, dropFeeWei);
    }

    function scoopFees(address to) external {
        if (msg.sender != scooperTreasury) revert DogPooperOnlyTreasury();
        uint256 bal = address(this).balance;
        (bool ok,) = to.call{value: bal}("");
        require(ok, "DogPooper: scoop failed");
        emit Scooped(bal, to);
    }

    function getTokenAt(uint256 index) external view returns (address) {
        if (index >= totalDrops) revert DogPooperInvalidIndex();
        return dropIndexToToken[index];
    }

    function sealSaddlebag() external view returns (bytes32) {
        bytes32 s = keccak256(
            abi.encodePacked(
                saddlebagDomain,
                totalDrops,
                genesisBlock,
                block.number,
                address(this).balance
            )
        );
        return s;
    }
}

/// @notice Minimal ERC20 clone deployed per drop. 9 decimals, burn-on-transfer, anti-snipe delay.
contract PoopToken {
    string public immutable name;
    string public immutable symbol;
    uint8 public immutable decimals;
    uint256 public immutable totalSupplyCap;
    uint256 public totalSupply;
    uint256 public immutable burnBps;
    address public immutable dropper;
    uint256 public immutable tradeableFromBlock;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed from, uint256 amount);

    error PoopNotTradeableYet();
    error PoopInsufficientBalance();
    error PoopInsufficientAllowance();
    error PoopZeroAddress();
    error PoopZeroAmount();

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_,
        uint8 burnBps_,
        address dropper_,
        uint256 tradeableFromBlock_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = 9;
        totalSupplyCap = supply_;
        totalSupply = supply_;
        burnBps = burnBps_;
