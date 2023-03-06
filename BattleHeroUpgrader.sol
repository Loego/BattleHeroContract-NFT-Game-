// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";
import "./shared/IBattleHeroPE.sol";
import "./shared/IBattleHero.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BattleHeroUpgrader is Initializable {
    
    IBattleHeroGenScience _battleHeroGenScience;
    IBattleHeroBreeder _battleHeroBreeder;
    IBattleHeroFactory _battleHeroFactory;
    IBattleHero _battleHero;
    BattleHeroData _battleHeroData;
    address _battleHeroBurnWallet;
    mapping(IBattleHeroGenScience.Rarity => uint256) _upgradePrices;
    event HeroUpgraded(uint256 heroId, address who);
    function initialize(
        address _battleHeroGenScienceAddress, 
        address _battleHeroBreederAddress,
        address _battleHeroFactoryAddress,
        address _battleHeroAddress,
        address _battleHeroDataAddress,
        address _battleHeroBurnWalletAddress
    ) public initializer { 
        _battleHeroFactory    = IBattleHeroFactory(_battleHeroFactoryAddress);
        _battleHeroData       = BattleHeroData(_battleHeroDataAddress);
        _battleHeroGenScience = IBattleHeroGenScience(_battleHeroGenScienceAddress);
        _battleHeroBreeder    = IBattleHeroBreeder(_battleHeroBreederAddress);
        _battleHero           = IBattleHero(_battleHeroAddress);
        _battleHeroBurnWallet = _battleHeroBurnWalletAddress;

        _upgradePrices[IBattleHeroGenScience.Rarity.LOW_RARE] = 50 ether;
        _upgradePrices[IBattleHeroGenScience.Rarity.RARE]     = 150 ether;
        _upgradePrices[IBattleHeroGenScience.Rarity.EPIC]     = 500 ether;
        _upgradePrices[IBattleHeroGenScience.Rarity.LEGEND]   = 1000 ether;
        _upgradePrices[IBattleHeroGenScience.Rarity.MITIC]    = 2000 ether; 
    }

    function upgrade(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256 _tokenId3
    ) public {

        IBattleHeroFactory.Hero memory _hero1 = _battleHeroFactory.heroeOfId(_tokenId1);
        IBattleHeroFactory.Hero memory _hero2 = _battleHeroFactory.heroeOfId(_tokenId2);
        IBattleHeroFactory.Hero memory _hero3 = _battleHeroFactory.heroeOfId(_tokenId3);

        BattleHeroData.Rarity memory _rarity1 = _battleHeroData.getRarity(_hero1.deconstructed._rarity);
        BattleHeroData.Rarity memory _rarity2 = _battleHeroData.getRarity(_hero2.deconstructed._rarity);
        BattleHeroData.Rarity memory _rarity3 = _battleHeroData.getRarity(_hero3.deconstructed._rarity);

        _preUpgrade(_hero1, _hero2, _hero3, _rarity1, _rarity2, _rarity3);
        _processUpgrade(_hero1, _rarity1);

        _battleHeroFactory.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _tokenId1);
        _battleHeroFactory.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _tokenId2);
        _battleHeroFactory.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _tokenId3);
    }

    function _processUpgrade(
        IBattleHeroFactory.Hero memory _hero,
        BattleHeroData.Rarity memory _rarity
    ) internal {
        uint _rare         = uint(_rarity.rare);
        uint _maxRare      = uint(BattleHeroData.Rare.MITIC);        
        IBattleHeroGenScience.Rarity _upgradedRarity = _uintToRarity(_rare + 1);
        uint256 _upgradePrice = _upgradePrices[_upgradedRarity];
        string memory _gen;
        require(_rare < _maxRare, "You reach max rarity");
        require(_battleHero.balanceOf(msg.sender) >= _upgradePrice, "Insufficient BATH");
        require(_battleHero.allowance(msg.sender, address(this)) >= _upgradePrice, "Insufficient allowance");
        if(_isWeapon(_hero.deconstructed)){
            _gen = _battleHeroGenScience.generateWeapon(_upgradedRarity, _padLeft(_hero.deconstructed._asset));
        }else{
            _gen = _battleHeroGenScience.generateCharacter(_upgradedRarity, _padLeft(_hero.deconstructed._asset));
        }
        uint256 _heroId = _battleHeroBreeder.breed(msg.sender, _gen);
        _battleHero.transferFrom(msg.sender, _battleHeroBurnWallet, _upgradePrice);
        emit HeroUpgraded(_heroId, msg.sender);
    }

    function price(uint256 heroId) public view returns(uint256){
        IBattleHeroFactory.Hero memory _hero = _battleHeroFactory.heroeOfId(heroId);
        BattleHeroData.Rarity memory _rarity = _battleHeroData.getRarity(_hero.deconstructed._rarity);
        uint _rare         = uint(_rarity.rare);
        IBattleHeroGenScience.Rarity _upgradedRarity = _uintToRarity(_rare + 1);
        return _upgradePrices[_upgradedRarity];        
    }
    
    function _preUpgrade(
        IBattleHeroFactory.Hero memory _hero1,
        IBattleHeroFactory.Hero memory _hero2,
        IBattleHeroFactory.Hero memory _hero3, 
        BattleHeroData.Rarity memory _rarity1,
        BattleHeroData.Rarity memory _rarity2,
        BattleHeroData.Rarity memory _rarity3
    ) internal pure{
        require(_hero1.deconstructed._asset == _hero2.deconstructed._asset, "Inconsistent hero");
        require(_hero2.deconstructed._asset == _hero3.deconstructed._asset, "Inconsistent hero");
        require(_hero3.deconstructed._asset == _hero1.deconstructed._asset, "Inconsistent hero");

        require(_rarity1.rare == _rarity2.rare, "Inconsisten rarity");
        require(_rarity2.rare == _rarity3.rare, "Inconsisten rarity");
        require(_rarity3.rare == _rarity1.rare, "Inconsisten rarity");
    }
    function _isWeapon(
        BattleHeroData.DeconstructedGen memory deconstructed
    ) internal pure returns (bool){        
        return deconstructed._type > 49;
    }
    function _uintToRarity(uint _rarity) public pure returns(IBattleHeroGenScience.Rarity){
        if(_rarity == 0){
            return IBattleHeroGenScience.Rarity.COMMON;
        }
        if(_rarity == 1){
            return IBattleHeroGenScience.Rarity.LOW_RARE;
        }
        if(_rarity == 2){
            return IBattleHeroGenScience.Rarity.RARE;
        }
        if(_rarity == 3){
            return IBattleHeroGenScience.Rarity.EPIC;
        }
        if(_rarity == 4){
            return IBattleHeroGenScience.Rarity.LEGEND;
        }
        if(_rarity == 5){
            return IBattleHeroGenScience.Rarity.MITIC;
        }
        return IBattleHeroGenScience.Rarity.COMMON;
    }
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function _append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    function _padLeft(uint256 r0) internal pure returns(string memory){
        string memory appended = "";
        if(r0 < 10){
            appended = _append("0" , _uint2str(r0));
        }else{
            appended = _uint2str(r0);
        }
        return appended;
    }
}