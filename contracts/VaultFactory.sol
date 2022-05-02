// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Security/PausableUpgradeable.sol";
import "./Interfaces/IVaultFactory.sol";
import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./Proxies/ERC1967Proxy.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Interfaces/IVaultFactory.sol";
import "./Interfaces/IERC1155Upgradeable.sol";
import "./Access/OwnableUpgradeable.sol";
import "./Vault.sol";



contract VaultFactory is Initializable, IVaultFactory, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;

    //logic address
    address VaultAddress;

    //iterable vault mapping
    address[] internal vaults;
    mapping(address => address[]) assetVaults;


    function __VaultFactory_init() public virtual override initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        VaultAddress = address(new Vault());
    }

    function deployVault(NFTs _Tokens, address hoa, address treasury, string memory name_, string memory symbol_, uint256 serialNo, uint256 _tokenId) public virtual whenNotPaused onlyOwner returns(address, uint256){
      ERC1967Proxy proxy = new ERC1967Proxy(VaultAddress, abi.encodeWithSelector(Vault(address(0)).initialize.selector, _Tokens, hoa, treasury, name_, symbol_, serialNo, _tokenId));

      address vaultProxyAddr = address(proxy);
      uint256 vaultId = vaults.length;
    
      assetVaults[address(_Tokens)].push(vaultProxyAddr);
      vaults.push(vaultProxyAddr);
    
      emit VaultInit (vaultId, _tokenId, vaultProxyAddr, address(_Tokens), block.timestamp);

      emit VaultProxyDeployed(vaultProxyAddr);

      return (vaultProxyAddr, vaultId);
    }

    function vaultById(uint256 vaultNo) external view returns(address) {
        return vaults[vaultNo];
    }

    function getAllVaults() external view virtual override returns(address[] memory) {
        return vaults;
    }

    function getAssetVaults(address assetAddress) external view virtual override returns(address[] memory) {
        return assetVaults[assetAddress];
    }

    function vaultCount() external view virtual override returns(uint256) {
        return vaults.length;
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

    function _authorizeUpgrade(address newFactory) internal virtual onlyOwner override {
        require(AddressUpgradeable.isContract(newFactory), "VaultFactory: new factory must be a contract");
        require(newFactory != address(0), "VaultFactory: set to the zero address");
    }  
}