// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

interface IERC1155Upgradeable is IERC165Upgradeable{

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event AssetAdded(address walletKey, string[] images, string[] documents);

    event TransferToVault(uint256 tokenid, address indexed transferTo);

    event URI(string value, uint256 indexed id);

    function getContractAddress() external view returns(address);

    function totalSupply(uint256 id) external view returns(uint256);

    function exists(uint256 id) external view returns(bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function mintNft(uint256 id) external returns(uint256);

    function mintBatchNfts(uint256[] memory ids, uint256[] memory amounts) external returns(uint256[] memory);

    function burnNFT(uint256 id) external;

    function transferToVault(uint256 id, address to) external returns(uint256, address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function assetDetails(
        address wallet,
        string[] memory picHash,
        string[] memory physicalAddress,
        string[] memory community,
        string[] memory papers,
        uint256 taxes,
        uint256 insur,
        uint256 maintain,
        uint256 costs,
        string[] memory levels,
        string[] memory extras,
        string[] memory data
    ) external;


} 