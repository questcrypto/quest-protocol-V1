// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC165Upgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }


    uint256[50] private __gap;
}