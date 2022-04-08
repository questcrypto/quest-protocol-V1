// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVaultFactory {

    event VaultInit (uint256 indexed vaultId, address vaultAddress, address assetAddress, uint256 time);

    event VaultProxyDeployed(address indexed VaultProxyAddr);

    function __VaultFactory_init() external;

    function vaultById(uint256 vaultNo) external view returns(address);

    function getAllVaults() external view returns(address[] memory);

    function getAssetVaults(address assetAddress) external view returns(address[] memory);

    function vaultCount() external view returns(uint256);

    function isPaused() external view returns(bool);

}