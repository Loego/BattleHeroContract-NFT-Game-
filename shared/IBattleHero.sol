pragma solidity 0.8.9;

contract IBattleHero{
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {}
    function balanceOf(address account) public view virtual returns (uint256) {}
    function allowance(address owner, address spender) public view virtual returns (uint256) {}
    function burn(uint256 amount) public virtual {}
    function burnFrom(address account, uint256 amount) public virtual {}
    function mint(address to, uint256 amount) public virtual {}
}