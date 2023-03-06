// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";

contract BattleHeroStarterPack is ContextUpgradeable, AccessControlEnumerableUpgradeable{

    mapping(address => bool) _starterPackClaimed;
    
    bool _paused;
    
    address _owner;
    
    IBattleHeroBreeder _battleHeroBreeder;
    IBattleHeroGenScience _battleHeroGenScience;
    
    event StarterPackClaimed(address who, uint256[] tokenIds);

    function initialize(
        address _battleHeroBreederAddress, 
        address _battleHeroGenScienceAddress
    ) public initializer { 
        __Context_init();
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());        
        _paused = false;
        _battleHeroBreeder = IBattleHeroBreeder(_battleHeroBreederAddress);
        _battleHeroGenScience = IBattleHeroGenScience(_battleHeroGenScienceAddress);
    }

    function setBreeder(address _battleHeroBreederAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid role for set breeder");
        _battleHeroBreeder = IBattleHeroBreeder(_battleHeroBreederAddress);
    }
    function setGenScience(address _battleHeroGenScienceAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid role for set gen science");
        _battleHeroGenScience = IBattleHeroGenScience(_battleHeroGenScienceAddress);
    }

    function claim() public{
        require(!_starterPackClaimed[msg.sender], "Starter pack claimed");
        require(!_paused, "Starter pack is paused");
        uint256[] memory _tokenIds = new uint256[](2);
        string memory _characterGen = _battleHeroGenScience.generateIntransferibleCharacter(IBattleHeroGenScience.Rarity.COMMON);
        string memory _weaponGen    = _battleHeroGenScience.generateIntransferibleWeapon(IBattleHeroGenScience.Rarity.COMMON);
        uint256 _characterId = _battleHeroBreeder.breed(msg.sender, _characterGen);
        uint256 _weaponId    = _battleHeroBreeder.breed(msg.sender, _weaponGen);        
        _tokenIds[0] = _characterId;
        _tokenIds[1] = _weaponId;
        _starterPackClaimed[msg.sender] = true;
        emit StarterPackClaimed(msg.sender, _tokenIds);
    }
    function claimed(address from) public view returns(bool){
        return _starterPackClaimed[from];
    }
    function pause() public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _paused = true;
    }
    function upause() public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _paused = false;
    }
}