// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Proxies/Initializable.sol";
import "./Interfaces/INFTsFactory.sol";
import "./Access/OwnableUpgradeable.sol";
import "./Security/PausableUpgradeable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./Proxies/ERC1967Proxy.sol";
import "./Utils/AddressUpgradeable.sol";
import "./NFTs.sol";


contract NFTsFactory is Initializable, INFTsFactory, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  
  //Implementation address
  address NFTsAddress;
  
  //Iterable proxy mapping
  mapping(address=> address) internal assetsMap;
  address[] internal assets;


  function __NFTsFactory_init() public virtual override initializer {
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    NFTsAddress = address(new NFTs());
  }

  function deployTokens(
    string memory uri_,
    address assetWallet,
    address hoa,
    address treasury, 
    string memory _contractName, 
    uint256 propTaxId
  ) public virtual whenNotPaused onlyOwner returns(address){
      ERC1967Proxy proxy = new ERC1967Proxy(
        NFTsAddress, 
        abi.encodeWithSelector(
          NFTs(address(0)).initialize.selector, 
          uri_, 
          assetWallet, 
          hoa, 
          treasury, 
          _contractName, 
          propTaxId
        )
      );
      
      address assetProxy = address(proxy);
      uint256 assetId = assets.length;
  
      assetsMap[assetWallet] = assetProxy;
      assets.push(assetProxy);
 
      emit PropertyAdded(assetId, assetWallet, propTaxId);

      emit AssetProxyDeployed(assetProxy);

      return (assetProxy);
  }


  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function isPaused() external view override returns(bool){
    return _paused;
  }

  function assetContractByWallet(address assetWallet) external view virtual override returns(address) {
    return assetsMap[assetWallet];
  }

  function numOfAssets() external view virtual override returns(uint256) {
    return assets.length;
  }

  function assetContractById(uint256 assetId) external view virtual override returns(address) {
    return assets[assetId];
  }

  function getAllAssets() external view virtual override returns(address[] memory) {
    return assets;
  }

  function _authorizeUpgrade(address newFactory) internal virtual override onlyOwner {
    require(AddressUpgradeable.isContract(newFactory), "NFTsFactory: new factory must be a contract");
    require(newFactory != address(0), "NFTsFactory: set to the zero address");
  }

}