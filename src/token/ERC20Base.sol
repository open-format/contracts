// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.16;

import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {ERC20MetadataStorage} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {Pausable} from "@solidstate/contracts/security/Pausable.sol";

contract ERC20 is SolidStateERC20, Ownable, Pausable {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    constructor(string memory _name, string memory _symbol) {
        ERC20MetadataStorage.Layout storage s = ERC20MetadataStorage.layout();
        _setOwner(msg.sender);

        s.name = _name;
        s.symbol = _symbol;
        s.decimals = 18;
    }

    /**
     * @notice Mints a token.
     * @param _to Address of the receiver of the token.
     * @param _amount Number of tokens to mint.
     */

    function mint(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns a number of tokens that an account holds.
     * @param _account Address of the owner of the tokens to be burnt.
     * @param _amount Amount of tokens to be be burnt.
     */

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }

    /**
     * @notice Set pause state to true
     */

    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Set pause state to false
     */

    function unpause() public onlyOwner {
        _unpause();
    }
}
