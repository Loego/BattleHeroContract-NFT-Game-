pragma solidity 0.8.9;

contract IBattleHeroPE{
    function balanceOf(address account) public view virtual returns (uint256) {}
    function mint(address to, uint256 amount) public virtual {}
    function scale(uint256 _peEther) public view returns(uint256){}
}