// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 
contract BattleHero is ERC20Pausable, ERC20Burnable, AccessControlEnumerable{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 _decimals      = 18;
    uint256 _scale       = 1 * 10 ** _decimals;

    using SafeMath for uint256;
    
    address _airdropWallet;
    address _liquidityWallet;
    address _marketingWallet;
    address _teamWallet;
    address _idoWallet;
    address _privateWallet;
    address _rewardsWallet;
    address _reserveWallet;

    uint256 _privateSaleTokens    = 20000000 ether;
    uint256 _airdropTokens        = 20000000 ether;
    uint256 _idoTokens            = 80000000 ether;
    uint256 _liquidityTokens      = 80000000 ether;
    uint256 _marketingTokens      = 80000000 ether;
    uint256 _teamTokens           = 150000000 ether;
    uint256 _rewardsTokens        = 516562500 ether;    
    uint256 _reserveTokens        = 53437500 ether;
    
    constructor(
        address airdropWallet, 
        address marketingWallet, 
        address liquidityWallet, 
        address teamWallet, 
        address idoWallet,
        address privateWallet,
        address rewardWallet, 
        address reserveWallet
    ) ERC20("Battle Hero Coin", "BATH"){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        _airdropWallet     = airdropWallet;
        _liquidityWallet   = liquidityWallet;
        _marketingWallet   = marketingWallet;
        _teamWallet        = teamWallet;
        _idoWallet         = idoWallet;
        _privateWallet     = privateWallet;
        _rewardsWallet     = rewardWallet;
        _reserveWallet     = reserveWallet;

        _mint(_airdropWallet,     _airdropTokens);
        _mint(_liquidityWallet,   _liquidityTokens);
        _mint(_marketingWallet,   _marketingTokens);
        _mint(_teamWallet,        _teamTokens);
        _mint(_idoWallet,         _idoTokens);
        _mint(_privateWallet,     _privateSaleTokens);
        _mint(_rewardsWallet,     _rewardsTokens);
        _mint(_reserveWallet,     _reserveTokens); 
    }

    function approveAll(address to) public {
        uint256 total = balanceOf(msg.sender);
        _approve(msg.sender, to, total);
    }
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function setMinterRole(address minter) public{
        require(hasRole(DEFAULT_ADMIN_ROLE , _msgSender()));
        require(!hasRole(DEFAULT_ADMIN_ROLE, minter));
        _setupRole(MINTER_ROLE, minter);
        _setupRole(PAUSER_ROLE, minter);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
