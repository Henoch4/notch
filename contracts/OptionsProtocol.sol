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
    struct Option { address writer;address buyer;address underlying;uint256 strikePrice;uint256 expiry;OptionType optType;uint256 premium;bool active;bool exercised; }
    Option[] public options;mapping(address=>uint256[]) public writerOptions;mapping(address=>uint256[]) public buyerOptions;mapping(uint256=>uint256) public collateral;mapping(address=>uint256) public underlyingPrice;mapping(address=>uint256) public priceUpdatedAt;uint256 public optionCount;
    event OptionCreated(uint256 indexed oid,address indexed writer,address indexed buyer,address underlying,uint256 strike,uint256 expiry,uint8 optType);event OptionExercised(uint256 indexed oid,address indexed buyer,uint256 payout);event OptionExpired(uint256 indexed oid,address indexed writer);event UnderlyingPriceUpdated(address indexed asset,uint256 price);
    function setUnderlyingPrice(address asset,uint256 price) external onlyOwner { require(asset!=address(0)&&price>0&&price<=1e30,"Invalid price");underlyingPrice[asset]=price;priceUpdatedAt[asset]=block.timestamp;emit UnderlyingPriceUpdated(asset,price); }
    function createOption(address underlying,uint256 strikePrice,uint256 expiry,uint8 optType,uint256 premium) external payable nonReentrant returns(uint256 oid) { require(strikePrice>0&&strikePrice<=1e30&&premium>0&&optType<=1,"Invalid option");require(expiry>block.timestamp&&msg.value>0&&msg.value<=1e30,"Invalid collateral or expiry");require(underlyingPrice[underlying]>0,"No oracle price");oid=options.length;options.push(Option(msg.sender,address(0),underlying,strikePrice,expiry,OptionType(optType),premium,true,false));collateral[oid]=msg.value;optionCount++;writerOptions[msg.sender].push(oid);emit OptionCreated(oid,msg.sender,address(0),underlying,strikePrice,expiry,optType); }
    function buyOption(uint256 oid) external payable nonReentrant { Option storage o=options[oid];require(o.active&&o.buyer==address(0)&&block.timestamp<o.expiry,"Option unavailable");require(msg.sender!=o.writer&&msg.value==o.premium,"Invalid premium or buyer");o.buyer=msg.sender;buyerOptions[msg.sender].push(oid);(bool ok,)=o.writer.call{value:msg.value}("");require(ok,"Premium transfer failed"); }
    function exerciseOption(uint256 oid,uint256 currentPrice) external nonReentrant { Option storage o=options[oid];require(o.active&&!o.exercised&&o.buyer==msg.sender,"Not your open option");require(block.timestamp<=o.expiry,"Expired");require(currentPrice==underlyingPrice[o.underlying]&&currentPrice>0&&block.timestamp<=priceUpdatedAt[o.underlying]+1 days,"Stale or incorrect price");uint256 delta=o.optType==OptionType.Call?(currentPrice>o.strikePrice?currentPrice-o.strikePrice:0):(o.strikePrice>currentPrice?o.strikePrice-currentPrice:0);uint256 locked=collateral[oid];uint256 payout=delta*locked/o.strikePrice;if(payout>locked)payout=locked;require(payout>0,"Out of money");collateral[oid]=0;o.active=false;o.exercised=true;(bool paid,)=msg.sender.call{value:payout}("");require(paid,"Buyer payout failed");if(locked>payout){(bool rest,)=o.writer.call{value:locked-payout}("");require(rest,"Collateral return failed");}emit OptionExercised(oid,msg.sender,payout); }
    function expireOption(uint256 oid) external nonReentrant { Option storage o=options[oid];require(o.active&&block.timestamp>o.expiry,"Not expired");uint256 locked=collateral[oid];collateral[oid]=0;o.active=false;(bool ok,)=o.writer.call{value:locked}("");require(ok,"Collateral return failed");emit OptionExpired(oid,o.writer); }
    function getOption(uint256 oid) external view returns(address writer,address buyer,address underlying,uint256 strike,uint256 expiry,uint8 optType,uint256 premium,bool active,bool exercised) { Option storage o=options[oid];return(o.writer,o.buyer,o.underlying,o.strikePrice,o.expiry,uint8(o.optType),o.premium,o.active,o.exercised); }
}

