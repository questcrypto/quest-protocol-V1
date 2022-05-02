// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./Tokens/ERC1155HolderUpgradeable.sol";
import "./Tokens/SafeERC20.sol";
import "./ERC20Upgradeable.sol";
import "./Utils/EnumerableMap.sol";
import "./Access/AccessControlUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Security/ReentrancyGuardUpgradeable.sol";
import "./Interfaces/IVault.sol";
import "./Interfaces/IVaultFactory.sol";
import "./NFTs.sol";


contract Vault is Initializable, ERC20Upgradeable, IVault, ERC1155HolderUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

  using AddressUpgradeable for address;
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  using SafeERC20 for IERC20;


  //contracts storage
  NFTs internal Tokens;
  IERC20 private USDC ;

  //vault params
  uint256 internal tokenId;
  bool private _active = false;
  uint256 private timeStamp = block.timestamp;
  uint256 private listedPrice;
  uint256 public usdcCounterIn;
  uint256 public usdcCounterOut;

  uint256 private questId;

  //Enumberable mapping from address to it's share of fractions
  EnumerableMap.AddressToUintMap internal fractionsMap;
  address[] owners;

  bytes32 public constant TREASURY_ROLE = keccak256(abi.encodePacked("TREASURY_ROLE"));



   modifier ActiveVault() {
    require(_active == true, "Vault: has to be active");
    _;
  }

  
  
  function initialize(
    NFTs _Tokens, 
    address hoa, 
    address treasury, 
    string memory name_, 
    string memory symbol_, 
    uint256 serialNo, 
    uint256 _tokenId
  ) public virtual initializer {
    __ERC20_init(name_, symbol_);
    __ERC1155Holder_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, hoa);
    _setupRole(TREASURY_ROLE, treasury);
    
    Tokens = _Tokens;
    require(address(Tokens) != address(0), "Vault: asset is zero address");
    
    USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    bool success = USDC.approve(address(this), listedPrice);
    require(success, "Vault: unsuccessful approval");

    questId = serialNo;
    tokenId = _tokenId;

    _active = true;
  }

  function sealVault() external virtual override ActiveVault onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
    _active = false;

    emit VaultSealed(_active, timeStamp);

    return _active;
  }

  function reactiveVault() external virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
    require(_active == false,"Vault: not sealed to reactive");
    
    _active = true;

    emit VaultReoponed(_active, timeStamp);

    return _active;
  }

  function isActive() external view virtual override returns(bool) {
    return _active;
  }


  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
    return 
    interfaceId == type(ERC1155ReceiverUpgradeable).interfaceId ||
    interfaceId == type(AccessControlUpgradeable).interfaceId ||
    interfaceId == type(IVault).interfaceId ||

    super.supportsInterface(interfaceId);
  }

  function balanceOf(address account, uint256 _tokenId) public view returns(uint256) {
    return Tokens.balanceOf(account, _tokenId);
  }

  function wrapNFT(uint256 _listedPrice) public virtual ActiveVault onlyRole(TREASURY_ROLE) {
    listedPrice = _listedPrice;    

    require(balanceOf(address(this), tokenId) == 1, "Vault: token is not received yet");

    _mint(address(this), listedPrice);

    emit NFTWrapped(tokenId, listedPrice);
  }

  function availableFractions() external view returns(uint256) {
    return balanceOf(address(this));
  }


  function claimUnsold(address account) external ActiveVault onlyRole(TREASURY_ROLE) {
    
    _transfer(address(this), account, balanceOf(address(this)));

    emit UnsoldFractionsClaimed(account, balanceOf(address(this)));
  }

  
  function vaultUsdcBalance() public view returns(uint256) {
    return USDC.balanceOf(address(this));
  }

  function ownerIndex(uint256 index) public view returns(address, uint256) {
    return fractionsMap.at(index);
  }

  function withdrawFractions(uint256 _deposit) public ActiveVault nonReentrant virtual {  
    require(msg.sender != address(0), "Vault: buyer is zero address");
    require(_deposit <= _totalSupply && _deposit > 0, "Vault: zero amount or exceeds available fractions");
    
    if(_deposit > USDC.allowance(_msgSender(), address(this))) {
      revert("Vault: insufficient allowance of USDC");
    } else {
      USDC.safeTransferFrom(_msgSender(), address(this), _deposit);
      usdcCounterIn++;
      owners.push(msg.sender);
      fractionsMap.set(msg.sender, _deposit);
      _transfer(address(this), _msgSender(), _deposit);

      emit FractionPurchased(_deposit, _msgSender());
    }    
  }

  function allOwners() public view returns(address[] memory) {
    return owners;
  }

  //will take back quest and give usdc to end user, will not burn returned quest
  function returnFractions(address from, uint256 share) public virtual override ActiveVault onlyRole(TREASURY_ROLE) {
    require(fractionsMap.contains(from), "Vault: address does not exist");

    if(share == balanceOf(from)) {
      fractionsMap.remove(from);
      _balances[from] -= share;
      _balances[address(this)] += share;
      USDC.safeTransfer(from, share);
      usdcCounterOut++;
      for(uint256 i = 0; i <= owners.length - 1; i++) {
        owners[i] = owners[i + 1];
        owners.pop();
      }
     
      emit FractionsReturned(from, share);

    } else {
      revert("Vault: share should be equal balance");
    }  
  }

  
  function unwrapNFT(address to, uint256 _tokenId) public virtual ActiveVault onlyRole(TREASURY_ROLE) {
    tokenId = _tokenId;
    require(to != address(0), "Vault: transfer to zero address");
    require(balanceOf(address(this)) >= listedPrice, "Vault: burn amount should equal price");
    
    Tokens.safeTransferFrom(address(this), to, _tokenId, 1, "");
    
    _burn(address(this), listedPrice);

    emit NFTWithdrawal(to, _tokenId, listedPrice);

    _doSafeTransferAcceptanceCheck(msg.sender, address(this), to, _tokenId, 1, "");
  }

  //helper function to burn quest when needed
  function burnQuest(address from, uint256 amount) public virtual override ActiveVault onlyRole(TREASURY_ROLE) {
    require(amount <= balanceOf(from), "Vault: amount exceeds balance");

    _burn(from, amount);

    emit QuestBurned(from, amount);
  }

  function transferUSDC(address to, uint256 value) external virtual nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    USDC.safeTransfer(to, value);
    usdcCounterOut++;
    emit UsdcTransferred(to, value);
  }

  function holdersCount() public view virtual override returns(uint256) {
    return fractionsMap.length();
  }

  function fractionOwnerExists(address owner) public view virtual override returns(bool) {
    return fractionsMap.contains(owner);
  }

  function getOwnerShare(address owner) public view virtual override returns(uint256) {
    return fractionsMap.get(owner);
  }

  function version() pure public virtual returns (string memory) {
    return "V1.0.0";
  }

  function _authorizeUpgrade(address newImplementation) internal virtual onlyRole(DEFAULT_ADMIN_ROLE) override {
    require(AddressUpgradeable.isContract(newImplementation), "Vault: new Implementation must be a contract");
    require(newImplementation != address(0), "Vault: set to the zero address");
  }
  

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
          }
        } catch Error(string memory reason) {
          revert(reason);
        } catch {
          revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

}