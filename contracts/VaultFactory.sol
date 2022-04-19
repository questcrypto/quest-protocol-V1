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



contract VaultFactory is Initializable, UUPSUpgradeable, IVaultFactory, PausableUpgradeable, OwnableUpgradeable {
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

    function deployVault(NFTs _Tokens, address treasury, address hoa, string memory name_, string memory symbol_) public virtual whenNotPaused returns(address){
      ERC1967Proxy proxy = new ERC1967Proxy(VaultAddress, abi.encodeWithSelector(Vault(address(0)).initialize.selector, _Tokens, treasury, hoa, name_, symbol_));
      _transferOwnership(hoa);

      address vaultProxyAddr = address(proxy);
      uint256 id = vaults.length;
      assetVaults[address(_Tokens)].push(vaultProxyAddr);
      vaults.push(vaultProxyAddr);

      emit VaultSetup (id, vaultProxyAddr, address(_Tokens));

      emit proxyDeployed(vaultProxyAddr);

      return (vaultProxyAddr);
    }

    function getVaultAddress(uint256 id) public view virtual override returns(address) {
        return vaults[id];
    }

    function getAllVaults() public view virtual override returns(address[] memory) {
        return vaults;
    }

    function getAssetVaults(address assetAddress) public view virtual override returns(address[] memory) {
        return assetVaults[assetAddress];
    }

    function numOfVaults() public view virtual override returns(uint256) {
        return uint(vaults.length);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isPaused() public view returns(bool){
        return _paused;
    }

    function _authorizeUpgrade(address newFactory) internal virtual override {
        require(AddressUpgradeable.isContract(newFactory), "VaultFactory: new factory must be a contract");
        require(newFactory != address(0), "VaultFactory: set to the zero address");
    }  
}