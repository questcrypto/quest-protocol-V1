// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Tokens/ERC1155HolderUpgradeable.sol";
import "./Interfaces/IVault.sol";
import "./Access/AccessControlUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Utils/CountersUpgradeable.sol";
import "./Utils/SafeMath.sol";
import "./Security/ReentrancyGuardUpgradeable.sol";
import "./Tokens/SafeERC20.sol";
import "./NFTs.sol";


contract Vault is Initializable, ERC20Upgradeable, IVault, ERC1155HolderUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

  using AddressUpgradeable for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter vaultNums;

  //contracts storage
  NFTs internal Tokens;
  IERC20 private USDC;

  //vault params
  uint256 internal tokenId;
  uint256 internal vaultNum;
  bool internal _active = false;
  uint256 private timeStamp = block.timestamp;
  uint256 private USDCSupply;


  struct Fractions {
    address owner;
    uint256 share;
    bool claimed;
  }

  mapping(uint256 => Fractions[]) private fractionOwners;
  mapping(address => uint256) internal USDCBalances;
 
  bytes32 public constant TREASURY_ROLE = keccak256(abi.encodePacked("TREASURY_ROLE"));


  function initialize(NFTs _Tokens, address treasury, address hoa, string memory name_, string memory symbol_) public virtual initializer {
    __ERC20_init(name_, symbol_);
    __ERC1155Holder_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, hoa);
    _setupRole(TREASURY_ROLE, treasury);

    Tokens = _Tokens;
    require(address(Tokens) != address(0), "Vault: wrong asset address");

    //USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USDC address
    USDC = IERC20(0xFE724a829fdF12F7012365dB98730EEe33742ea2); //test purposes Ropsten contract address
    bool success = USDC.approve(address(this), uint256(1)); //to authorize interaction of vault with usdc
    require(success, "Vault: transfer USDC failed");
    
    vaultNums.increment();
    vaultNum = vaultNums.current();

    _active = true;

    emit VaultOpened(vaultNum, address(Tokens), timeStamp);
  }

  modifier ActiveVault() {
    require(_active == true, "Vault: has to be active");
    _;
  }

  function balanceOf(address account, uint256 _tokenId) public view returns(uint256) {
    return Tokens.balanceOf(account, _tokenId);
  }

  function isActive() public view virtual override returns(bool) {
    return _active;
  }


  function getVaultNum() external view virtual override returns(uint256) {
    return vaultNum;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
    return 
    interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
    interfaceId == type(IVault).interfaceId ||
    interfaceId == type(AccessControlUpgradeable).interfaceId ||

    super.supportsInterface(interfaceId);
  }

  function sealVault() public virtual override ActiveVault onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
    _active = false;

    emit VaultSealed(_active, timeStamp);

    return _active;
  }


  function wrapNft(uint256 _tokenId, uint256 price) public virtual override ActiveVault nonReentrant onlyRole(TREASURY_ROLE) returns(uint256, uint256) {
    tokenId = _tokenId;

    require(balanceOf(address(this), tokenId) <= 1, "Vault: token is not received yet");

    _mint(address(this), price);

    emit Wrapped(tokenId, address(this), price);

    return (tokenId, price);
  }

  function batchDistribution(uint256[] memory payments, address payable[] memory recipients, uint256[] memory shares) public virtual override ActiveVault onlyRole(DEFAULT_ADMIN_ROLE) {

    require(recipients.length == shares.length && recipients.length == payments.length, "Vault: recipients, payments, & shares mismatch");

    uint256 j = 0;
    uint256 len = shares.length;
    for(j = 0; j<=len; j++) {
      fractionOwners[vaultNum].push(Fractions(recipients[j], shares[j], true));

      require(recipients[j] != address(0), "Vault: transfer to zero address");
      require(shares[j] <= _totalSupply, "Vault: exceeds available supply");
      require(payments[j] == shares[j], "Vault: payments received not equal shares send");

      USDCBalances[recipients[j]] = payments[j];
      USDCSupply.add(payments[j]);
    }

    transfer(recipients[j], shares[j]);
  }

  function singleDistribution(uint256 payment, address payable recipient, uint256 share) public payable virtual override onlyRole(TREASURY_ROLE) {
    require(payment == share, "Vault: payment and share should be equal");
    require(share <= _totalSupply, "Vault: exceeds available supply");
    require(recipient != address(0), "Vault: transfer to zero address");

    USDCBalances[recipient] = payment;
    USDCSupply.add(payment);

    fractionOwners[vaultNum].push(Fractions(recipient, share, true));

    transfer(recipient, share);
  }

  function userUSDCBalance(address user) public view returns(uint256) {
    return USDC.balanceOf(user);
  }


  function unwrapFractions(address payable recipient, uint256 refund) public virtual override onlyRole(TREASURY_ROLE) {
    require(recipient != address(0), "Vault: transfer to zero address");
  
    uint256 userShare = _balances[recipient];
    require(userShare <= refund, "Vault: refund exceeds recipient's balance");
    _balances[recipient] = userShare.sub(refund);
    _totalSupply.sub(refund);

    _burn(recipient, refund);

    
    uint256 userRefund = USDCBalances[recipient];
    USDCBalances[recipient] = userRefund.sub(refund);
    USDCSupply.sub(refund);

   

    SafeERC20.safeTransferFrom(USDC, address(this), recipient, refund);
  }

  function unwrapNft(uint256 _tokenId, uint256 value) public virtual override ActiveVault onlyRole(TREASURY_ROLE) returns(uint256) {
    tokenId = _tokenId;
 
    _burn(address(this), value);

    return tokenId;
  }

  function takeOutNft(address to, uint256 _tokenId) public virtual override ActiveVault onlyRole(TREASURY_ROLE) returns(address, uint256) {
    _doSafeTransferAcceptanceCheck(msg.sender, address(this), to, _tokenId, 1, "");
    Tokens.safeTransferFrom(address(this), to, _tokenId, 1, "");

    return (to, _tokenId);
  }

  function reactiveVault() public virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
    require(!sealVault(),"Vault: not sealed to reactive");
    _active = true;

    emit VaultReoponed(_active, timeStamp);

    return _active;
  }

  function version() pure public virtual returns (string memory) {
    return "Startegic Quest Crypto Vault V1.0.0";
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
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