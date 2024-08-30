// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC1155SpenderWhitelist } from "src/common/ERC1155SpenderWhitelist.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { ERC1155URIStorageUpgradeable } from
  "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { IFloppy } from "../interfaces/NFT/IFloppy.sol";

contract Floppy is IFloppy, ERC1155SpenderWhitelist, AccessControlEnumerable {
  bytes32 public constant MINTER_ROLE = "MINTER_ROLE";
  bytes32 public constant SETTER_ROLE = "SETTER_ROLE";

  /// @dev Gap for upgradability.
  uint256[50] private _____gap;

  constructor() {
    _disableInitializers();
  }

  function initialize(address admin) external initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_ROLE, admin);
    _grantRole(SETTER_ROLE, admin);
  }

  /// @inheritdoc IFloppy
  function mintFloppy(address to, uint256 id, uint256 value) external onlyRole(MINTER_ROLE) {
    _mint(to, id, value, "");
  }

  /// @inheritdoc IFloppy
  function batchMintFLoppy(address to, uint256[] memory ids, uint256[] memory values) external onlyRole(MINTER_ROLE) {
    _mintBatch(to, ids, values, "");
  }

  /// @inheritdoc IFloppy
  function setBaseURI(string memory baseURI) external onlyRole(SETTER_ROLE) {
    _setBaseURI(baseURI);
  }

  /// @inheritdoc IFloppy
  function setURI(uint256 tokenId, string memory tokenURI) external onlyRole(SETTER_ROLE) {
    _setURI(tokenId, tokenURI);
  }

  /// @inheritdoc IFloppy
  function whitelist(address _spender) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _whitelist(_spender);
  }

  /// @inheritdoc IFloppy
  function unwhitelist(address _spender) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unwhitelist(_spender);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC1155Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _msgSender() internal view override(Context, ContextUpgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
    return super._msgData();
  }

  function _contextSuffixLength() internal view override(Context, ContextUpgradeable) returns (uint256) {
    return super._contextSuffixLength();
  }
}
