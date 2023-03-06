// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BattleHeroRewardWallet is Context, AccessControlEnumerable{
    
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    mapping(address => uint ) _lastClaim;
    
    using SafeMath for uint256;

    event TokensClaimed(address user, uint256 amount);
    uint claimDays = 5 days;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REWARD_DISTRIBUTOR_ROLE, _msgSender());
    }
    
    function addRewardDistributorRole(address distributorRole) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _setupRole(REWARD_DISTRIBUTOR_ROLE, distributorRole);
    }

    function changeClaimDays(uint _days) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You are not an admin");
        claimDays = _days;
    }
    function distribute(address _bath, uint256 _amount, address to) public virtual{
        require(block.timestamp >= _lastClaim[to] + claimDays, "You need to wait for next claim");
        require(IERC20(_bath).balanceOf(address(this)) > 0, "No reward tokens left");        
        require(hasRole(REWARD_DISTRIBUTOR_ROLE, msg.sender), "You are not distributor role");
        address beneficiary = to;
        SafeERC20.safeTransfer(IERC20(_bath), beneficiary, _amount);                
        _lastClaim[to] = block.timestamp;
        emit TokensClaimed(beneficiary, _amount);
    }
}   