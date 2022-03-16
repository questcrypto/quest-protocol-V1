// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./Security/PausableUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Access/OwnableUpgradeable.sol";
import "./Proxies/ERC1967Proxy.sol";
import "./NFTs.sol";

contract NFTsFactory is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    address NFTsAddress;
    address[] internal proxies;

    event contractDeployed(address indexed propContractAddr);

    function __NFTsFactory_init() public initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        NFTsAddress = address(new NFTs());
    }


    function deployTokens(
        string calldata uri_, 
        address treasury, 
        address opsController, 
        string calldata _contractName, 
        string calldata _contractDescription
    ) public virtual whenNotPaused returns(address){
        ERC1967Proxy proxy = new ERC1967Proxy(NFTsAddress, abi.encodeWithSelector(NFTs.initialize.selector, uri_, treasury, opsController, _contractName, _contractDescription));

        emit contractDeployed(address(proxy));

        proxies.push(address(proxy));

        return address(proxy);
    }

    function pause() external onlyOwner {
    _pause();
  }


    function unpause() external onlyOwner {
    _unpause();
  }

  function _authorizeUpgrade(address newImplementation) internal virtual  override onlyOwner {
    require (AddressUpgradeable.isContract(newImplementation), 'NFTsFactory: new factory must be a contract');
  }
}