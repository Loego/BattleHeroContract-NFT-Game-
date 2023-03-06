// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./shared/IBattleHeroRewardWallet.sol";


contract BattleHeroPE is ContextUpgradeable, AccessControlEnumerableUpgradeable{
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => mapping(address => uint256)) private _allowances;

    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) _balances;

    uint8 _decimals;
    uint256 _scale;
    uint256 _ratio;
    
    IBattleHeroRewardWallet _rewardWallet;

    event PEExchanged(address who, uint256 amount);

    function initialize(
        address _rewardWalletAddress
    ) public initializer { 
        __Context_init();
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _rewardWallet = IBattleHeroRewardWallet(_rewardWalletAddress);
        _decimals     = 18;
        _scale        = 1 * 10 ** _decimals;
        _ratio        = 5;
    }

    function exchange(uint256 amount, address _token) public{
        uint256 _balance = _balances[msg.sender];     
        require(_balance > 0, "You dont have balance to exchange");
        require(_balance >= amount, "Amount excedeed balance");
        uint256 _reward = _PEtoBath(_balance);   
        _rewardWallet.distribute(_token, _reward, msg.sender);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit PEExchanged(msg.sender, amount);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public { 
        _allowances[msg.sender][spender] += amount;
    }

    function setMinterRole(address minter) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin can set a minter");
        _setupRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public{
        require(hasRole(MINTER_ROLE, _msgSender()), "You dont have a minter role");        
        _balances[to] += amount;
    }
    function burnFrom(address from, uint256 amount) public{
        require(_allowances[from][msg.sender] >= amount);
        burn(from, amount);
    }
    function burn(address to, uint256 amount) public { 
        require(hasRole(MINTER_ROLE, _msgSender()), "You dont have a minter role");        
        _balances[to] -= amount;
    }

    function _PEtoBath(uint256 _pe) internal view returns(uint256){
        return _pe.div(_ratio);
    }

    function scale(uint256 _peEther) public view returns(uint256){
        return _peEther * _scale;
    }

    function changeRatio(uint256 _newRatio) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin can change ratio");
        require(_newRatio > 0);
        _ratio = _newRatio;
    }

    function changeRewardWallet(address _newRewardWallet) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin can change reward wallet");
        require(_newRewardWallet != address(0));
        _rewardWallet = IBattleHeroRewardWallet(_newRewardWallet);
    }

}