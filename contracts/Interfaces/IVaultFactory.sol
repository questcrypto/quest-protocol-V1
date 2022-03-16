// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVaultFactory {

    event VaultSetup (uint256 indexed vaultNo, uint256 tokenId);

    function newVault() external returns(uint256);  //done

    function vaultAddress(uint256 id) external view returns(address);

    function getAllVaults() external view returns(address[] memory);

}