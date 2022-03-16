// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Interfaces/IERC1155Upgradeable.sol";
import "./Interfaces/IERC1155MetadataURIUpgradeable.sol";
import "./Tokens/ERC1155HolderUpgradeable.sol";
import "./Utils/ERC165Upgradeable.sol";
import "./Utils/ContextUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Utils/StringsUpgradeable.sol";
import "./Access/AccessControlUpgradeable.sol";
import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";


contract NFTs is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable, ERC1155HolderUpgradeable , AccessControlUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;


  address assetWallet; //UI:1.Owner Details
  string private contractName;
  string private contractDescription;
  string private _uri;
  // Array of only 6 tokens that are available to mint
  uint256[5] private availableTokens;
  // from token id to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;
  // token owner authorize operator's transaction
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  // Total supply of each id
  mapping(uint256 => uint256) private _totalSupply;
  // To prevent duplicate properties
  mapping(string => bool) private propertyExists;

  mapping(address => Property) public propertyDetails;
  mapping(uint256 => address) public erc20Tansfers; 


  struct TokensIssued{
    uint256 TokenId;
    uint256 TimeStamp;
  }

  struct Property{
    string[] ImagesHash;  //UI:6. property Images
    string[] Address;  //UI:3. physical Address
    string[] SchoolsDist;  //UI:4. Neighborhood
    string[] Documents; //UI:7. property Documents
    uint256 Tax; //UI:5. T.I.M.E contract details
    uint256 Insurance;
    uint256 Maintenance;
    uint256 Expenses;
    string[] Floors; //UI:8. 
    string[] Amenities;  //UI:9.
    string[] PropertyInfo;  //UI:2. Property Info.
    TokensIssued[] tokens;
  }

  uint256 public constant TITLE = 0;
  uint256 public constant MANAGEMENT_RIGHT = 1;
  uint256 public constant INCOME_RIGHT = 2;
  uint256 public constant EQUITY_RIGHT = 3;
  uint256 public constant OCCUPANCY_RIGHT = 4;
  uint256 public constant GOVERNANCE_RIGHT = 5;

  //bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256(abi.encodePacked("CONTRACT_ADMIN_ROLE"));
  bytes32 public constant TREASURY_ROLE = keccak256(abi.encodePacked("TREASURY_ROLE"));
  bytes32 public constant OPS_ROLE = keccak256(abi.encodePacked("OPS_ROLE"));


  function initialize(string memory uri_, address treasury, address opsController, string memory _contractName, string memory _contractDescription) public initializer {
    __ERC1155Holder_init();
    __UUPSUpgradeable_init();
    __AccessControl_init();
  
    contractName = _contractName;
    contractDescription = _contractDescription;
    _setURI(uri_);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    //_setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //_setupRole(CONTRACT_ADMIN_ROLE, contractAdmin);
    _setupRole(TREASURY_ROLE, treasury);
    _setupRole(OPS_ROLE, opsController);

    propertyExists[uri_] = true;
  }


  function modifyUri(uint256 id) public view virtual onlyRole(DEFAULT_ADMIN_ROLE) returns(string memory) {
    require(exists(id),"NFT: non existent token");

    return string(abi.encodePacked(_uri, id.toString()));
  }

  function getContractAddress() public view override returns(address) {
    return address(this);
  }

  function totalSupply(uint256 id) public view override returns (uint256) {
    return _totalSupply[id];
  }

  function exists(uint256 id) public view override returns (bool) {
    return NFTs.totalSupply(id) > 0;
  }

  function uri(uint256) public view override returns (string memory) {
    return _uri;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable, ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
    return 
    interfaceId == type(IERC1155Upgradeable).interfaceId ||
    interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
    interfaceId == type(AccessControlUpgradeable).interfaceId ||
    interfaceId == type(ERC1155ReceiverUpgradeable).interfaceId ||
    super.supportsInterface(interfaceId);
  }

  function balanceOf(address account, uint256 id) public view override returns (uint256) {
    require(account != address(0), "NFT: balance query for the zero address");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view override returns (uint256[] memory) {
    require(accounts.length == ids.length, "NFT: accounts and ids length mismatch");
    
    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function isApprovedForAll(address account, address operator) public view override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function assetDetails(
    address _assetWallet, 
    string[] memory imageshash,
    string[] memory assetAddress,
    string[] memory neighborhood,
    string[] memory docs,
    uint256 tax,
    uint256 insurance,
    uint256 maintenance,
    uint256 expenses,
    string[] memory floors,
    string[] memory amenities,
    string[] memory info
  ) public virtual override {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NFT: unauthorized personnel");
    assetWallet =  _assetWallet;
    propertyDetails[assetWallet].ImagesHash = imageshash;
    propertyDetails[assetWallet].Address = assetAddress;
    propertyDetails[assetWallet].SchoolsDist = neighborhood;
    propertyDetails[assetWallet].Documents = docs;
    propertyDetails[assetWallet].Tax = tax;
    propertyDetails[assetWallet].Insurance = insurance;
    propertyDetails[assetWallet].Maintenance = maintenance;
    propertyDetails[assetWallet].Expenses = expenses;
    propertyDetails[assetWallet].Floors = floors;
    propertyDetails[assetWallet].Amenities = amenities;
    propertyDetails[assetWallet].PropertyInfo = info;

    emit AssetAdded (assetWallet, imageshash, docs);

  }

  function transferToVault(uint256 id, address toContract) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256, address){
    require(balanceOf(address(this), id) == 1, 'NFT: balance is not enough');
    require(AddressUpgradeable.isContract(toContract), "NFT: transfer to vault contract only");

    erc20Tansfers[id] = toContract;

    _safeTransferFrom(address(this), toContract, id, 1, "");

    emit TransferToVault(id, toContract);

    return (id, toContract);
  }


  function mintNft(uint256 id) public virtual override onlyRole(TREASURY_ROLE) returns(uint256){
    require(!exists(id) && id <= availableTokens.length,"NFT: token already minted or out of range");
    
    _mint(address(this), id, 1, "");

    propertyDetails[assetWallet].tokens.push(TokensIssued({TokenId: id, TimeStamp: block.timestamp}));

    return id;
  }

  function mintBatchNfts(uint256[] memory ids, uint256[] memory amounts) public virtual override onlyRole(TREASURY_ROLE) returns(uint256[] memory) {
  
    uint256 i = 0;
    for (i = 0; i <= ids.length; i++) {

      propertyDetails[assetWallet].tokens.push(TokensIssued({TokenId: ids[i], TimeStamp: block.timestamp}));

    }

    require(!exists(ids[i]) && ids[i] <= availableTokens.length, "NFT: token is minted or out of range");

    _mintBatch(address(this),ids, amounts,"");

     return ids;
  }

  function burnNFT(uint256 id) public virtual override onlyRole(TREASURY_ROLE) {
    require(exists(id), "NFT: NFT does not exist");

    _burn(address(this), id, 1);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(OPS_ROLE) {
    require(AddressUpgradeable.isContract(newImplementation), "Quest: new Implementation must be a contract");
  }


  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "NFT: caller is not owner nor approved");

    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "NFT: caller is not owner nor approved");

    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _setURI(string memory newuri) internal {
    _uri = newuri;
  }
 
  function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    require(to != address(0), "NFT: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "NFT: insufficient balance for transfer");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);
  }

  function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");
    require(to != address(0), "NFT: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "NFT: insufficient balance for transfer");
      unchecked {
        _balances[id][from] = fromBalance - amount;
              
      }
       _balances[id][to] += amount;        
    }

    emit TransferBatch(operator, from, to, ids, amounts);
  }

  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    require(to != address(0), "NFT: mint to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
    _balances[id][to] += amount;
   
    emit TransferSingle(operator, address(0), to, id, amount);
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(to != address(0), "NFT: mint to the zero address");
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);
  }

  
  function _burn(address from, uint256 id, uint256 amount) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    
    address operator = _msgSender(); 

    _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
    
    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "NFT: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
    require(from != address(0), "NFT: burn from the zero address");
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");
  
    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "NFT: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, "NFT: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
        
    emit ApprovalForAll(owner, operator, approved);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
 
    operator = _msgSender();
    data = data;
    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
         _totalSupply[ids[i]] += amounts[i];
        
      }
    }
    
    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];
        uint256 supply = _totalSupply[id];
        require(supply >= amount, "NFT: burn amount exceeds total Supply");
        unchecked {
          _totalSupply[id] = supply - amount;
        }
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

}


