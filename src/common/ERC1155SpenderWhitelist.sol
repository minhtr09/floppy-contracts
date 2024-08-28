// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SpenderWhitelist } from "./SpenderWhitelist.sol";
import { ERC1155URIStorageUpgradeable } from
  "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract ERC1155SpenderWhitelist is SpenderWhitelist, ERC1155URIStorageUpgradeable {
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    if (whitelisted[operator]) {
      return true;
    }

    return super.isApprovedForAll(account, operator);
  }
}
