// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INFTsFactory {

    event AssetProxyDeployed(address indexed propContractAddr);

    event PropertyAdded(uint256 indexed id, address indexed assetWallet, uint256 indexed taxId);

    function __NFTsFactory_init() external;

    function deployTokens(
        string calldata uri_,  
        address assetWallet,
        address hoa,
        address treasury, 
        string calldata _contractName, 
        uint256 propTaxId
    ) external returns(address);

    function assetContractByWallet(address assetWallet) external view returns(address);

    function assetContractById(uint256 assetId) external view returns(address);

    function numOfAssets() external view returns(uint256);

    function getAllAssets() external view returns(address[] calldata);

    function isPaused() external view returns(bool);
}