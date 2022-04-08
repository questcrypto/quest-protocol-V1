// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IVault {

    event NFTReceived(uint256 indexed tokenId, uint256 price); 

    event TransferReceived(uint256 amount, address indexed from, address to);

    event QuestMinted(address to, uint256 amount, uint256 reaminingFractions);

    event FractionsReturned(address sender, uint256 amount);

    event QuestBurned(address indexed, uint256 amount);

    event VaultSealed(bool active, uint256 timeStamp);  

    event VaultReoponed(bool active, uint256 timeStamp);

    event NFTWithdrawal(address indexed to, uint256 id, uint256 burnedAmount);

    function isActive() external view returns(bool);

    function balanceOf(address account, uint256 _tokenId) external view returns(uint256);

    function listNFT(uint256 tokenId, uint256 price) external returns(uint256, uint256);    

    function buyFractions(uint256 _amount) external payable;

    function returnFractions(uint256 refund) external payable;

    function burnQuest(address from, uint256 amount) external;

    function withdrawNFT(address to, uint256 id) external returns(uint256);

    function fractionHolders() external view returns(uint256);

    function fractionOwnerExists(address owner) external view returns(bool);

    function getOwnerShare(address owner) external view returns(uint256);

    function reactiveVault() external returns(bool);

    function sealVault() external returns(bool);  
}