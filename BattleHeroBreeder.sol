// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";

contract BattleHeroBreeder is
    AccessControlEnumerable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BREED_ROLE  = keccak256("BREED_ROLE");

    IBattleHeroGenScience _genScience;
    IBattleHeroFactory _erc721factory;

    using Strings for uint256;

    constructor(
    address genScience, 
    address erc721) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BREED_ROLE, _msgSender());        
        setGenScience(genScience);
        setERC721Factory(erc721);
    }
    modifier isSetup() {
        require(address(_genScience) != address(0), "Setup not correctly");
        require(address(_erc721factory) != address(0), "Setup not correctly");
        _;
    }
