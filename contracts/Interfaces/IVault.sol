// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVault {

    event NFTWrapped(uint256 indexed tokenId, uint256 indexed price); 

    event FractionPurchased(uint256 share, address indexed buyer);  

    event FractionsReturned(address sender, uint256 amount);

    event UsdcTransferred(address indexed to, uint256 amount);

    event QuestBurned(address indexed, uint256 amount);

    event VaultSealed(bool active, uint256 timeStamp);  

    event VaultReoponed(bool active, uint256 timeStamp);    

    event NFTWithdrawal(address indexed to, uint256 id, uint256 burnedAmount);

    event UnsoldFractionsClaimed(address indexed to, uint256 amount);

    function isActive() external view returns(bool);   

    function balanceOf(address account, uint256 _tokenId) external view returns(uint256);      

    function wrapNFT(uint256 price) external;    

    function withdrawFractions(uint256 _amount) external;

    function returnFractions(address from, uint256 share) external;

    function burnQuest(address from, uint256 amount) external;    

    function unwrapNFT(address to, uint256 id) external;

    function holdersCount() external view returns(uint256);     

    function fractionOwnerExists(address owner) external view returns(bool);    
    
    function getOwnerShare(address owner) external view returns(uint256);   
    
    function reactiveVault() external returns(bool);    
    
    function sealVault() external returns(bool);
    
}