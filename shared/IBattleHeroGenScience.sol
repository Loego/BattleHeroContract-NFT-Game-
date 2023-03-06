pragma solidity 0.8.9;


contract IBattleHeroGenScience{
    enum Rarity{
        COMMON, 
        LOW_RARE, 
        RARE, 
        EPIC, 
        LEGEND,
        MITIC
    }    
    function generateWeapon(Rarity _rarity, string memory asset) public returns (string memory){}
    function generateWeapon(Rarity _rarity) public returns (string memory){}
    function generateWeapon() public returns (string memory){}
    function generateCharacter(Rarity _rarity, string memory asset) public returns (string memory){}
    function generateCharacter(Rarity _rarity) public returns (string memory){}
    function generateCharacter() public returns (string memory){}
    function generate() public returns(string memory){}
    function generateIntransferibleWeapon(Rarity _rarity) public returns (string memory){}
    function generateIntransferibleCharacter(Rarity _rarity) public returns (string memory){}
}