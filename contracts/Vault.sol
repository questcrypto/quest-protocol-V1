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
import "./Utils/SafeMath.sol";
import "./Security/ReentrancyGuardUpgradeable.sol";
import "./Interfaces/IVault.sol";
import "./Interfaces/IVaultFactory.sol";
import "./NFTs.sol";



contract Vault is Initializable, ERC20Upgradeable, IVault, ERC1155HolderUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

  using AddressUpgradeable for address;
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  //contracts storage
  NFTs internal Tokens;
  IERC20 private USDC ;



  //vault params
  uint256 internal tokenId;
  uint256 internal vaultId; //to be in factory better
  bool private _active = false;
  uint256 private timeStamp = block.timestamp;
  uint256 private listedPrice;


  //Enumberable mapping from address to it's share of fractions
  EnumerableMap.AddressToUintMap internal fractionsMap;
 
   modifier ActiveVault() {
    require(_active == true, "Vault: has to be active");
    _;
  }


  bytes32 public constant TREASURY_ROLE = keccak256(abi.encodePacked("TREASURY_ROLE"));
  
  function initialize(NFTs _Tokens, address hoa, address treasury, string memory name_, string memory symbol_) public virtual initializer {
    __ERC20_init(name_, symbol_);
    __ERC1155Holder_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, hoa);
    _setupRole(TREASURY_ROLE, treasury);
    
    Tokens = _Tokens;
    require(address(Tokens) != address(0), "Vault: wrong asset address");
    
    USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); 

    _active = true;
  }


  function _setPrice(uint256 newPrice) internal {
    listedPrice = newPrice;
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

  function isActive() public view virtual override returns(bool) {
    return _active;
  }


  function sealVault() public virtual override ActiveVault onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
    _active = false;

    emit VaultSealed(_active, timeStamp);

    return _active;
  }

  function listNFT(uint256 _tokenId, uint256 _listedPrice) public virtual ActiveVault onlyRole(TREASURY_ROLE) returns(uint256, uint256) {
    tokenId = _tokenId;
    _setPrice(_listedPrice);
    
    require(balanceOf(address(this), tokenId) == 1, "Vault: token is not received yet");

    emit NFTReceived(tokenId, _listedPrice);

    return (tokenId, _listedPrice);
  }

  function buyFractions(uint256 _amount) public payable nonReentrant virtual {
    require(msg.sender != address(0), "Vault: buyer is zero address");
    require(_amount <= listedPrice && _amount > 0, "Vault: zero amount or exceeds available fractions");

    uint256 remainBalance = listedPrice.sub(_amount);
    require(_amount <= remainBalance, "Vault: purchase is greater than available fractions");

    if(USDC.allowance(msg.sender, address(this)) <= 0) {
      revert("Vault: not enough USDC allowance approved");
    } else {
      USDC.safeTransferFrom(msg.sender, address(this), _amount);

      emit TransferReceived(_amount, _msgSender(), address(this));
    }
    
    fractionsMap.set(msg.sender, _amount);

    _mint(msg.sender, _amount);

    emit QuestMinted(_msgSender(), _amount, remainBalance);
  }

  //will take back quest and give usdc to end user, will not burn returned quest
  function returnFractions(uint256 refund) public payable virtual override {
    address sender = payable(msg.sender);
    require(sender != address(0), "Vault: transfer to zero address");
    
    uint256 userShare = _balances[sender];
    require(userShare <= refund, "Vault: refund exceeds recipient's balance");
    _balances[sender] = userShare.sub(refund);
    _totalSupply.add(refund);

    fractionsMap.remove(sender);

    USDC.safeTransfer(sender, refund);

    emit FractionsReturned(sender, refund);
  }

  function withdrawNFT(address to, uint256 _tokenId) public virtual ActiveVault onlyRole(TREASURY_ROLE) returns(uint256) {
    tokenId = _tokenId;
    require(to != address(0), "Vault: transfer to zero address");
    
    Tokens.safeTransferFrom(address(this), to, _tokenId, 1, "");
    
    _burn(address(this), listedPrice);

    emit NFTWithdrawal(to, _tokenId, listedPrice);

    _doSafeTransferAcceptanceCheck(msg.sender, address(this), to, _tokenId, 1, "");

    return tokenId;
  }

  function burnQuest(address from, uint256 amount) external virtual override ActiveVault onlyRole(TREASURY_ROLE) {
    require(amount <= _balances[from], "Vault: amount exceeds balance");

    _burn(from, amount);

    emit QuestBurned(from, amount);
  }

  function fractionHolders() external view virtual override returns(uint256) {
    return fractionsMap.length();
  }

  function fractionOwnerExists(address owner) external view virtual override returns(bool) {
    return fractionsMap.contains(owner);
  }

  function getOwnerShare(address owner) external view virtual override returns(uint256) {
    return fractionsMap.get(owner);
  }


  function reactiveVault() public virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
    require(!sealVault(),"Vault: not sealed to reactive");
    _active = true;

    emit VaultReoponed(_active, timeStamp);

    return _active;
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