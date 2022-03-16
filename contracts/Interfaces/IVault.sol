// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC165Upgradeable.sol";


interface IVault is IERC165Upgradeable{

    event VaultOpened(uint256 vaultNo, address indexed vaultManager, address indexed vaultAddress, uint256 openAt); //Done

    event Wrapped(uint256 tokenId, address indexed to, uint256 price);  //done

    event Distributed(address indexed to, uint256 amount, uint256 timeReceived);

    event VaultSealed(bool active, uint256 timeStamp);  //done

    event VaultReoponed(bool active, uint256 timeStamp);


    function wrapNft(uint256 tokenId, uint256 price) external returns(uint256, uint256);    //done

    function sealVault() external returns(bool);    //done

    function getVaultStatus() external view returns(uint256, address, bool);    //done

    function getVaultManager() external view returns(address);  //done


}