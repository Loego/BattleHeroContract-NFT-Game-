// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";


contract BattleHeroMarketplace is
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable{
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    struct Auction{
        uint256 heroId;
        uint256 price;
        uint256 auctionId;
        address auctioner;
    }

    IBattleHeroFactory _battleHeroFactory;
    IBattleHero _battleHero;

    mapping(uint256 => Auction) _auctions;
    mapping(uint256 => bool) _heroesInAuction;
    mapping(uint256 => uint256) _heroesAuctionId;      

    CountersUpgradeable.Counter private _auctionTracker;

    address _owner;   
    address _battleHeroBurnWallet; 
    uint256 FEE; 
    
    event AuctionCreated(address seller, uint256 heroId, uint256 price);
    event AuctionFinished(address buyer, address seller, uint256 heroId, uint256 price);

    address _battleHeroReserve;

    function initialize(
        address _battleHeroFactoryAddress, 
        address _battleHeroAddress, 
        address _battleHeroBurnWalletAddress,
        address _battleHeroReserveWallet
    ) public initializer { 
        __Context_init();
        __AccessControlEnumerable_init();
        _owner = msg.sender;
        _battleHeroBurnWallet = _battleHeroBurnWalletAddress;
        FEE = 5;
        setBattleHeroFactory(_battleHeroFactoryAddress);
        setBattleHero(_battleHeroAddress);
        setBattleHeroReserve(_battleHeroReserveWallet);
    }
    function setBattleHeroReserve(address reserve) public {
        require(msg.sender == _owner);
        require(reserve != address(0));
        _battleHeroReserve = reserve;
    }
    function setBattleHeroFactory(address battleHeroFactoryAddress) public {
        require(msg.sender == _owner);
        require(battleHeroFactoryAddress != address(0));
        _battleHeroFactory = IBattleHeroFactory(battleHeroFactoryAddress);
    }
    function setBattleHero(address battleHeroAddress) public {
        require(msg.sender == _owner);
        require(battleHeroAddress != address(0));
        _battleHero = IBattleHero(battleHeroAddress);
    }

    function setBattleHeroBurnWallet(address battleHeroBurnWalletAddress) public {
        require(msg.sender == _owner);
        require(battleHeroBurnWalletAddress != address(0));
        _battleHeroBurnWallet = battleHeroBurnWalletAddress;
    }

    function createAuction(
        uint256 _heroId, 
        uint256 _price
    ) public {
        require(!_heroesInAuction[_heroId], "Hero currently in auction");
        require(!_battleHeroFactory.isLocked(_heroId), "Herro currently locked");
        require(_battleHeroFactory.isApproved(address(this), _heroId), "Unnapproved hero");     
        require(_battleHeroFactory.ownerOf(_heroId) == msg.sender, "You are not owner");
        require(_price > 0, "Invalid price");
        uint256 _currentAuction    = _auctionTracker.current();
        _auctions[_currentAuction] = Auction(_heroId, _price, _currentAuction , msg.sender);
        _heroesAuctionId[_heroId]  = _currentAuction;
        _heroesInAuction[_heroId]  = true;        
        _auctionTracker.increment();
        _battleHeroFactory.lockHero(_heroId);
        emit AuctionCreated(msg.sender, _heroId, _price);
    }

    function purchase(uint256 _auctionId) public {
        Auction memory _auction = getAuction(_auctionId);
        address heroOwner = _battleHeroFactory.ownerOf(_auction.heroId);
        require(_battleHero.allowance(msg.sender, address(this)) >= _auction.price, "Insufficient allowance");
        require(_battleHero.balanceOf(msg.sender) >= _auction.price, "Insufficient balance");
        require(_battleHeroFactory.isApproved(address(this), _auction.heroId), "Unnapproved hero");
        require(_battleHeroFactory.isLocked(_auction.heroId), "Herro currently not locked");
        require(_heroesInAuction[_auction.heroId], "Hero currently not in auction");    
        require(heroOwner != msg.sender, "Owner can not buy his NFT");
        _processPurchase(_auction);
        _removeAuction(_auctionId);
        emit AuctionFinished(msg.sender, heroOwner, _auction.heroId, _auction.price);
    }

    function isSelling(uint256 tokenId) public view returns(bool){
        return _heroesInAuction[tokenId];
    }

    function getAuction(uint256 _auctionId) public view returns(Auction memory){
        return _auctions[_auctionId];
    }

    function totalAuctions() public view returns(uint256){
        return _auctionTracker.current();
    }

    function auctionIdOfHero(uint256 _heroId) public view returns(uint256){
        return _heroesAuctionId[_heroId];
    }

    function cancelAuction(uint256 _auctionId) public  {
        Auction memory _auction = getAuction(_auctionId);
        require(_battleHeroFactory.ownerOf(_auction.heroId) == msg.sender, "You are not owner");   
        require(_battleHeroFactory.isLocked(_auction.heroId), "Herro currently not locked");
        require(_heroesInAuction[_auction.heroId], "Hero currently not in auction");            
        _removeAuction(_auctionId);
    }

    function _processPurchase(Auction memory _auction) private { 
        uint256 _calculatedFee = _auction.price.mul(FEE).div(100);
        uint256 _reserveFee = _calculatedFee.mul(20).div(100);
        uint256 _burnFee    = _calculatedFee.mul(80).div(100);
        _battleHeroFactory.unlockHero(_auction.heroId);
        require(!_battleHeroFactory.isLocked(_auction.heroId));
        _battleHeroFactory.transferFrom(_auction.auctioner, msg.sender, _auction.heroId);
        _battleHero.transferFrom(msg.sender, _battleHeroBurnWallet, _burnFee);        
        _battleHero.transferFrom(msg.sender, _battleHeroReserve, _reserveFee);
        _battleHero.transferFrom(msg.sender, _auction.auctioner, (_auction.price) - _calculatedFee);
    }

    function _removeAuction(uint256 _auctionId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        Auction memory _auction = _auctions[_auctionId];
        uint256 lastAuctionId   = totalAuctions() - 1;
        _battleHeroFactory.unlockHero(_auction.heroId);   
        // Si el ultimoID es igual al que queremos eliminar no hace falta el swap
        if(_auctionId != lastAuctionId){
            Auction memory _gapAuction           = _auctions[lastAuctionId];
            _gapAuction.auctionId                = _auctionId;
            _auctions[_auction.auctionId]        = _gapAuction;
            _heroesAuctionId[_gapAuction.heroId] = _auction.auctionId;
            _auctions[lastAuctionId]             = _auction;
        }
        
        delete _heroesAuctionId[_auction.heroId];
        delete _heroesInAuction[_auction.heroId];
        delete _auctions[lastAuctionId];             
        _auctionTracker.decrement();
    }
}