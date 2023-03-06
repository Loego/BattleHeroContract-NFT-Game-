// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract BattleHeroChestShop is ContextUpgradeable, AccessControlEnumerableUpgradeable {

    uint256 public CHARACTER_CHEST;
    uint256 public WEAPON_CHEST;
    uint256 public MIX_CHEST;

    using SafeMathUpgradeable for uint256;

    mapping(address => mapping(uint256 => uint256)) _balances;
    mapping(uint256 => uint256) _prices;

    IBattleHero _battleHero;
    IBattleHeroBreeder _battleHeroBreeder;
    IBattleHeroGenScience _battleHeroGenScience;

    address _battleHeroBurnWallet;

    event ChestPurchased(address who, uint256 chestId, uint256 when);
    event ChestOpened(address who, uint256 chestId, uint256[] tokenIds, uint256 when);

    function initialize(
        address _battleHeroContractAddress,
        address _battleHeroBreederContractAddress, 
        address _battleHeroGenScienceContractAddress,
        address _battleHeroBurnWalletAddress
    ) public initializer { 
        
        __Context_init();
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        CHARACTER_CHEST = 0;
        WEAPON_CHEST    = 1;
        MIX_CHEST       = 2;
        
        setBattleHero(_battleHeroContractAddress);
        setBattleHeroBreeder(_battleHeroBreederContractAddress);
        setBattleHeroGenScience(_battleHeroGenScienceContractAddress);

        _battleHeroBurnWallet    = _battleHeroBurnWalletAddress;
        _prices[CHARACTER_CHEST] = 900 ether;
        _prices[WEAPON_CHEST]    = 900 ether;
        _prices[MIX_CHEST]       = 1440 ether;
    }

    function setBattleHero(address _battleHeroContractAddress) public {
        _battleHero = IBattleHero(_battleHeroContractAddress);
    }
    
    function setBattleHeroBreeder(address _battleHeroBreederContractAddress) public {
        _battleHeroBreeder = IBattleHeroBreeder(_battleHeroBreederContractAddress);
    }

    function setBattleHeroGenScience(address _battleHeroGenScienceContractAddress) public {
        _battleHeroGenScience = IBattleHeroGenScience(_battleHeroGenScienceContractAddress);
    }

    function balanceOf(address owner, uint256 chestId) public view returns(uint256){
        return _balances[owner][chestId];
    }
    function purchase(uint256 _chestId) public virtual{
        uint256 _amount = 1;
        uint256 _calculatedPrice = _prices[_chestId] * _amount;
        require(_battleHero.balanceOf(msg.sender) >= _calculatedPrice, "Insufficient balance");
        require(_battleHero.allowance(msg.sender, address(this)) >= _calculatedPrice, "Insufficient allowance");
        _balances[msg.sender][_chestId] = _balances[msg.sender][_chestId].add(_amount);
        _battleHero.transferFrom(msg.sender, _battleHeroBurnWallet, _calculatedPrice);
        emit ChestPurchased(msg.sender, _chestId, block.timestamp);
    }
    function purchase(uint256 _chestId, uint256 _amount) public virtual{
        uint256 _calculatedPrice = _prices[_chestId] * _amount;
        require(_battleHero.balanceOf(msg.sender) >= _calculatedPrice, "Insufficient balance");
        require(_battleHero.allowance(msg.sender, address(this)) >= _calculatedPrice, "Insufficient allowance");
        _balances[msg.sender][_chestId] = _balances[msg.sender][_chestId].add(_amount);
        _battleHero.transferFrom(msg.sender, _battleHeroBurnWallet, _calculatedPrice);
        emit ChestPurchased(msg.sender, _chestId, block.timestamp);
    }
    function open(uint256 _chestId) public virtual{        
        require(_balances[msg.sender][_chestId] >= 1, "You should to buy more chests");        
        _openChest(_chestId);        
    }
    function open(uint256 _chestId, uint256 _amount) public virtual{        
        require(_balances[msg.sender][_chestId] >= _amount, "You should to buy more chests");        
        for(uint i = 0; i < _amount; i++){
            _openChest(_chestId);
        }
    }

    function _openChest(uint256 _chestId) internal {
        uint256[] memory _tokenIds = new uint256[](2);
        if(_chestId == 0){
            string memory _genCharacter = _battleHeroGenScience.generateCharacter();
            uint256 _characterId = _battleHeroBreeder.breed(msg.sender, _genCharacter);
            _tokenIds[0] = _characterId;
        }
        if(_chestId == 1){
            string memory _genWeapon = _battleHeroGenScience.generateWeapon();
            uint256 _weaponId = _battleHeroBreeder.breed(msg.sender, _genWeapon);
            _tokenIds[1] = _weaponId;
        }
        if(_chestId == 2){
            string memory _genCharacter = _battleHeroGenScience.generateCharacter();
            string memory _genWeapon = _battleHeroGenScience.generateWeapon();
            uint256 _characterId = _battleHeroBreeder.breed(msg.sender, _genCharacter);
            uint256 _weaponId    = _battleHeroBreeder.breed(msg.sender, _genWeapon);
            _tokenIds[0] = _characterId;
            _tokenIds[1] = _weaponId;
        }
        _balances[msg.sender][_chestId] = _balances[msg.sender][_chestId].sub(1);
        emit ChestOpened(msg.sender, _chestId, _tokenIds, block.timestamp);
    }
}
