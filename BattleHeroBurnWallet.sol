// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHero.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract BattleHeroBurnWallet is
    AccessControlEnumerableUpgradeable {
    
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function initialize() public initializer{
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }
    function setBurnerRole(address burner) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _setupRole(BURNER_ROLE, burner);
    }
    function burn(address token, uint256 amount) public virtual{
        require(IBattleHero(token).balanceOf(address(this)) >= amount);
        require(hasRole(BURNER_ROLE, _msgSender()));
        IBattleHero(token).burn(amount);
    }
}