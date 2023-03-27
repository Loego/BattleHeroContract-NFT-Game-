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
