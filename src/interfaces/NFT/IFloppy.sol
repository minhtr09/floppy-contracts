// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IFloppy {
  /**
   * @dev Initializes the contract with an admin address
   * @param admin The address to be granted admin, minter, and setter roles
   */
  function initialize(address admin) external;

  /**
   * @dev Mints a single Floppy NFT
   * @param to The address to receive the minted token
   * @param id The token ID to mint
   * @param value The amount of tokens to mint
   */
  function mintFloppy(address to, uint256 id, uint256 value) external;

  /**
   * @dev Mints multiple Floppy NFTs in a batch
   * @param to The address to receive the minted tokens
   * @param ids An array of token IDs to mint
   * @param values An array of amounts for each token ID
   */
  function batchMintFLoppy(address to, uint256[] memory ids, uint256[] memory values) external;

  /**
   * @dev Sets the base URI for all token IDs
   * @param baseURI The new base URI to set
   */
  function setBaseURI(string memory baseURI) external;

  /**
   * @dev Sets the URI for a specific token ID
   * @param tokenId The ID of the token to set the URI for
   * @param tokenURI The new URI for the specified token
   */
  function setURI(uint256 tokenId, string memory tokenURI) external;

  /**
   * @dev Adds an address to the spender whitelist
   * @param _spender The address to whitelist
   */
  function whitelist(address _spender) external;

  /**
   * @dev Removes an address from the spender whitelist
   * @param _spender The address to remove from the whitelist
   */
  function unwhitelist(address _spender) external;
}
