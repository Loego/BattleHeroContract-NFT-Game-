// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHeroPE.sol";
import "./shared/IBattleHero.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BattleHeroTrainer is Initializable {

    struct Slot{
        uint256 hero;
        bool exists;
        uint256 when;
    }

    mapping(address => uint256) _slots;
    mapping(address => mapping(uint256 => mapping(uint256 => Slot))) _trainingPair;
    mapping(address => bool) _training;

    BattleHeroData _battleHeroData;
    IBattleHeroFactory _battleHeroFactory;
    IBattleHeroPE _battleHeroPE;
    IBattleHero _battleHero;

    address _owner;

    uint256 MIN_SLOTS;
    uint256 MAX_SLOTS;
    uint256 SLOT_PRICE;
    uint256 TRAINING_DURATION;


    using SafeMathUpgradeable for uint256;

    function initialize(
        address _battleHeroDataAddress, 
        address _battleHeroFactoryAddress, 
        address _battleHeroPEAddress,
        address _battleHeroAddress
    ) public initializer { 
        MIN_SLOTS         = 6;
        MAX_SLOTS         = 30;
        SLOT_PRICE        = 1500 ether;
        TRAINING_DURATION = 1 days;
        _owner = msg.sender;
        setBattleHeroData(_battleHeroDataAddress);  
        setBattleHeroFactory(_battleHeroFactoryAddress); 
        setBattleHeroPE(_battleHeroPEAddress); 
        setBattleHero(_battleHeroAddress);    
    }

    function setTrainDuration(uint256 _trainingTime) public{
        require(msg.sender == _owner);
        TRAINING_DURATION = _trainingTime;
    }

    function setBattleHeroData(address battleHeroDataAddress) public {
        require(msg.sender == _owner);
        require(battleHeroDataAddress != address(0));
        _battleHeroData = BattleHeroData(battleHeroDataAddress);
    }
    
    function setBattleHeroFactory(address battleHeroFactoryAddress) public {
        require(msg.sender == _owner);
        require(battleHeroFactoryAddress != address(0));
        _battleHeroFactory = IBattleHeroFactory(battleHeroFactoryAddress);
    }
    
    function setBattleHeroPE(address battleHeroPEAddress) public {
        require(msg.sender == _owner);
        require(battleHeroPEAddress != address(0));
        _battleHeroPE = IBattleHeroPE(battleHeroPEAddress);
    }
    
    function setBattleHero(address battleHeroAddress) public {
        require(msg.sender == _owner);
        require(battleHeroAddress != address(0));
        _battleHero = IBattleHero(battleHeroAddress);
    }

    function isTraining(address from, uint256 heroId) public view returns(bool){
        bool _tr = false;
        for(uint i = 0; i < _slots[from]; i++){
            if(_trainingPair[from][i][0].hero == heroId || _trainingPair[from][i][1].hero == heroId){
                if(_trainingPair[from][i][0].exists == true || _trainingPair[from][i][1].exists == true){
                    _tr = true;
                }
            }
        }
        return _tr;
    }

    function slots(address from) public view returns(uint256){
        if(_slots[from] == 0){
            return MIN_SLOTS;
        }
        return _slots[from] + MIN_SLOTS;
    }

    function getSlot(address from, uint256 slot) public view returns(Slot memory, Slot memory) { 
        return (_trainingPair[from][slot][0], _trainingPair[from][slot][1]);
    }

    function train(uint256[] memory _characters , uint256[] memory _weapons) public virtual {
        require(_characters.length == _weapons.length, "Invalid pairs");
        for(uint i = 0; i < _characters.length; i++){
            uint256 _character = _characters[i];
            uint256 _weapon    = _weapons[i];
            trainPair(i, _character, _weapon);
        }
    }

    function claimSlots(uint256[] memory _slotsToClaim) public virtual {
        uint256 _peTotal = 0;
        for(uint i = 0; i < _slotsToClaim.length; i++){
            _preClaim(_slotsToClaim[i]);
            uint256 _peCalculated = calculateBySlot(_slotsToClaim[i]);            
            _peTotal = _peTotal + _peCalculated;
            removeTrainPair(_slotsToClaim[i]);
        }
        _battleHeroPE.mint(msg.sender, _battleHeroPE.scale(_peTotal));
    }

    function claimAll() public virtual { 
        uint256 _peTotal = 0;
        uint256 _sl = slots(msg.sender);
        for(uint i = 0; i < _sl; i++){
            _preClaim(i);
            uint256 _peCalculated = calculateBySlot(i);            
            _peTotal = _peTotal + _peCalculated;
            removeTrainPair(i);
        }
        _training[msg.sender] = false;
        _battleHeroPE.mint(msg.sender, _battleHeroPE.scale(_peTotal));
    }

    function claimPair(uint256 slot) public {
        _preClaim(slot);
        Slot memory _characterSlot                = _trainingPair[msg.sender][slot][0];
        Slot memory _weaponSlot                   = _trainingPair[msg.sender][slot][1];
        IBattleHeroFactory.Hero memory _character = _battleHeroFactory.heroeOfId(_characterSlot.hero);                
        IBattleHeroFactory.Hero memory _weapon    = _battleHeroFactory.heroeOfId(_weaponSlot.hero);                
        uint256 _peTotal = _calculateByHeroes(_character, _weapon);
        _battleHeroPE.mint(msg.sender, _peTotal);
        removeTrainPair(slot);
    }

    function _calculateByHeroes(
        IBattleHeroFactory.Hero memory _character,
        IBattleHeroFactory.Hero memory _weapon
    ) internal view returns(uint256){
        uint256 _peTotal = 0;
        if(_character.exists){            
            uint256 _characterCalculated              = _calculate(_character.deconstructed._rarity);            
            _peTotal                                  = _peTotal + _characterCalculated;
        }
        if(_weapon.exists){            
            uint256 _weaponCalculated                 = _calculate(_weapon.deconstructed._rarity);
            _peTotal                                  = _peTotal +  _weaponCalculated;
        }
        BattleHeroData.Rarity memory _characterRarity  = _battleHeroData.getRarity(_character.deconstructed._rarity);
        BattleHeroData.Rarity memory _weaponRarity     = _battleHeroData.getRarity(_weapon.deconstructed._rarity);

        if(_isRarityBonus(_characterRarity, _weaponRarity)){
            uint256 bonus = _peTotal.mul(5).div(100);
            _peTotal = _peTotal + bonus;
        }

        if(_isRandomBonus(_character, _weapon)){
            uint256 bonus = _peTotal.mul(5).div(100);
            _peTotal = _peTotal + bonus;
        }        
        
        return _peTotal;
    }

    function calculateBySlot(uint256 slot) public view returns(uint256){
        uint256 _peTotal = 0;
        Slot memory _characterSlot                = _trainingPair[msg.sender][slot][0];
        Slot memory _weaponSlot                   = _trainingPair[msg.sender][slot][1];
        if(_characterSlot.exists){
            IBattleHeroFactory.Hero memory _character = _battleHeroFactory.heroeOfId(_characterSlot.hero);                
            uint256 _characterCalculated              = _calculate(_character.deconstructed._rarity);
            _peTotal                                  = _peTotal + _characterCalculated;
        }
        if(_weaponSlot.exists){
            IBattleHeroFactory.Hero memory _weapon    = _battleHeroFactory.heroeOfId(_weaponSlot.hero);                
            uint256 _weaponCalculated                 = _calculate(_weapon.deconstructed._rarity);
            _peTotal                                  = _peTotal +  _weaponCalculated;
        }
        return _peTotal;
    }

    function calculate(uint256[] memory _ids) public view returns(uint256){
        uint256 _pe = 0;
        for(uint256 i = 0; i < _ids.length; i++){
            _pe = _pe.add(_calculate(_ids[i]));
        }
        return _pe;
    }

    function cancel() public {
        for(uint i = 0; i < slots(msg.sender); i++){
            removeTrainPair(i);
        }
    }

    function purchaseExtraSlot() public{
        require(_battleHero.balanceOf(msg.sender) >= SLOT_PRICE);
        require(_battleHero.allowance(msg.sender, address(this)) >= SLOT_PRICE);        
        uint256 _currentSlots = slots(msg.sender);
        require(_currentSlots <= MAX_SLOTS, "You reach max slots");        
        _slots[msg.sender]    = _slots[msg.sender] + 1;
        _battleHero.burnFrom(msg.sender, SLOT_PRICE);
    }

    function trainPair(        
        uint256 slot,
        uint256 character,         
        uint256 weapon
    ) public {
        require(_battleHeroFactory.ownerOf(character) == msg.sender, "You are not the hero owner");
        require(_battleHeroFactory.ownerOf(weapon)    == msg.sender, "You are not the hero owner");
        require(_battleHeroFactory.heroeOfId(character).exists, "Hero doesnt exists");
        require(_battleHeroFactory.heroeOfId(weapon).exists   , "Hero doesnt exists");
        require(!_trainingPair[msg.sender][slot][0].exists          , "Slot for this character is full");
        require(!_trainingPair[msg.sender][slot][1].exists          , "Slot for this weapon is full");
        require(!_battleHeroFactory.isLocked(character)       , "This character is locked");
        require(!_battleHeroFactory.isLocked(weapon)          , "This weapon is locked");
        require(!_isWeapon(character)                         , "Invalid pair");
        require(_isWeapon(weapon)                             , "Invalid pair");    
        uint256 _now = block.timestamp;
        _trainingPair[msg.sender][slot][0] = Slot(character, true, _now);
        _trainingPair[msg.sender][slot][1] = Slot(weapon,    true, _now);
        _battleHeroFactory.lockHero(character);
        _battleHeroFactory.lockHero(weapon);
    }
    function removeTrainPair(
        uint256 slot
    ) public {
        _battleHeroFactory.unlockHero(_trainingPair[msg.sender][slot][0].hero);
        _battleHeroFactory.unlockHero(_trainingPair[msg.sender][slot][1].hero);
        _trainingPair[msg.sender][slot][0] = Slot(0, false, 0);
        _trainingPair[msg.sender][slot][1] = Slot(0, false, 0);
        delete _trainingPair[msg.sender][slot][0];
        delete _trainingPair[msg.sender][slot][1];
    }
    function _preClaim(uint256 _sl) internal view { 
        if(_trainingPair[msg.sender][_sl][0].exists){
            require(block.timestamp >= (_trainingPair[msg.sender][_sl][0].when + TRAINING_DURATION), "Train not finished");
            require(block.timestamp >= (_trainingPair[msg.sender][_sl][1].when + TRAINING_DURATION), "Train not finished");
        }
    }
    function _calculate(
        uint256 gen
    ) internal view returns(uint256){
        BattleHeroData.TrainingLevel memory trainingLevel = _battleHeroData.getTrainingLevel(gen);          
        return _battleHeroPE.scale((trainingLevel.level * trainingLevel.pct)) / 100;
    }
    function _isWeapon(
        uint256 tokenId
    ) internal view returns (bool){
        IBattleHeroFactory.Hero memory hero = _battleHeroFactory.heroeOfId(tokenId);
        BattleHeroData.DeconstructedGen memory deconstructed = _battleHeroData.deconstructGen(hero.genetic);                        
        return deconstructed._type > 49;
    }
    function _isRarityBonus(
        BattleHeroData.Rarity memory _characterRarity,
        BattleHeroData.Rarity memory _weaponRarity
    ) internal view returns(bool){
        if(_characterRarity.rare == _weaponRarity.rare){
        uint256 _nonce = _characterRarity.max + _weaponRarity.min;
        uint256 _block = block.number;
        uint pct = 2 - 1;
        uint256 _result = uint8(uint256(keccak256(abi.encodePacked(_nonce, _block, block.difficulty)))) % pct;
        _result = _result + 1;
        return _result == 1;
        }
        return false;
    }
    function _isRandomBonus(
        IBattleHeroFactory.Hero memory _character, 
        IBattleHeroFactory.Hero memory _weapon) internal view returns(bool){
        if(!_character.exists || !_weapon.exists){
            return false;
        }
        uint256 _nonce = _character.deconstructed._rarity + _weapon.deconstructed._rarity;
        uint256 _block = block.number;
        uint pct = 2 - 1;
        uint256 _result = uint8(uint256(keccak256(abi.encodePacked(_nonce, _block, block.difficulty)))) % pct;
        _result = _result + 1;
        return _result == 1;
    }
}