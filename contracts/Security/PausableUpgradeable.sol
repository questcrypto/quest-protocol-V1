// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Utils/ContextUpgradeable.sol";
import "../Proxies/Initializable.sol";

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {

    event Paused(address account);

    event Unpaused(address account);

    bool internal _paused;


    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    function paused() internal view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }


    uint256[49] private __gap;
}