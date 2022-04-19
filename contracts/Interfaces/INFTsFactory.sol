// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INFTsFactory {

    event proxyDeployed(address indexed propContractAddr);

    function __NFTsFactory_init() external;

    function deployTokens(
        string calldata uri_,  
        address assetWallet,
        address hoa,
        address treasury, 
        string calldata _contractName, 
        uint256 propTaxId
    ) external returns(address);

    function assetContractAddress(address assetWallet) external view returns(address);

    function numOfAssets() external view returns(uint256);

    function allAssets() external view returns(address[] calldata);

    function isPaused() external view returns(bool);
}