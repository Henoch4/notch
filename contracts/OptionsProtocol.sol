// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract OptionsProtocol is ReentrancyGuard, Ownable {
    enum OptionType { Call, Put }
    struct Option {
        address writer;
        address buyer;
        address underlying;
        uint256 strikePrice;
        uint256 expiry;
        OptionType optType;
        uint256 premium;
        bool active;
        bool exercised;
    }
    Option[] public options;
    mapping(address => uint256[]) public writerOptions;
    mapping(address => uint256[]) public buyerOptions;
    uint256 public optionCount;

    event OptionCreated(uint256 indexed oid, address indexed writer, address indexed buyer, address underlying, uint256 strike, uint256 expiry, uint8 optType);
    event OptionExercised(uint256 indexed oid, address indexed buyer, uint256 payout);
    event OptionExpired(uint256 indexed oid, address indexed writer);

    function createOption(address underlying, uint256 strikePrice, uint256 expiry, uint8 optType, uint256 premium)
        external payable nonReentrant returns (uint256) {
        require(premium > 0, "Zero premium");
        require(optType <= 1, "Invalid type");
        require(expiry > block.timestamp, "Expiry in past");
        Option storage o = options.push();
        o.writer = msg.sender;
        o.buyer = address(0);
        o.underlying = underlying;
        o.strikePrice = strikePrice;
        o.expiry = expiry;
        o.optType = optType == 0 ? OptionType.Call : OptionType.Put;
        o.premium = premium;
        o.active = true;
        o.exercised = false;
        uint256 oid = options.length - 1;
        optionCount = oid + 1;
        writerOptions[msg.sender].push(oid);
        emit OptionCreated(oid, msg.sender, address(0), underlying, strikePrice, expiry, optType);
        return oid;
    }

    function buyOption(uint256 oid) external payable nonReentrant {
        Option storage o = options[oid];
        require(o.active, "Option inactive");
        require(o.buyer == address(0), "Already bought");
        require(msg.value == o.premium, "Incorrect premium");
        o.buyer = msg.sender;
        buyerOptions[msg.sender].push(oid);
    }

    function exerciseOption(uint256 oid, uint256 currentPrice) external nonReentrant {
        Option storage o = options[oid];
        require(o.active, "Option inactive");
        require(o.buyer != address(0), "Not bought");
        require(!o.exercised, "Already exercised");
        require(block.timestamp <= o.expiry, "Expired");
        uint256 payout = 0;
        if (o.optType == OptionType.Call && currentPrice > o.strikePrice) {
            payout = (currentPrice - o.strikePrice);
        } else if (o.optType == OptionType.Put && o.strikePrice > currentPrice) {
            payout = (o.strikePrice - currentPrice);
        }
        require(payout > 0, "Out of the money");
        o.exercised = true;
        o.active = false;
        emit OptionExercised(oid, msg.sender, payout);
    }

    function expireOption(uint256 oid) external onlyOwner {
        Option storage o = options[oid];
        require(o.active, "Option inactive");
        require(block.timestamp > o.expiry, "Not expired");
        o.active = false;
        emit OptionExpired(oid, o.writer);
    }

    function getOption(uint256 oid) external view returns (address writer, address buyer, address underlying, uint256 strike, uint256 expiry, uint8 optType, uint256 premium, bool active, bool exercised) {
        Option storage o = options[oid];
        return (o.writer, o.buyer, o.underlying, o.strikePrice, o.expiry, uint8(o.optType), o.premium, o.active, o.exercised);
    }
}
