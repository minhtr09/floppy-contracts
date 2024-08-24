// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFloppyVault is IERC20 {
  /// @dev emit when user deposit ERC20 token.
  event Deposit(address indexed sender, address indexed owner, uint256 tokenAmount, uint256 shares);

  /// @dev emit when user withdraw ERC20 token.
  event Withdraw(
    address indexed sender, address indexed owner, address indexed receiver, uint256 tokenAmount, uint256 shares
  );

  /// @dev Revert when asset is address(0);
  error InvalidAssetAddress();

  /// @dev Revert when deposit or mint amount is 0;
  error InvalidAmount();

  /// @dev Attempted to withdraw more assets than the max amount for `receiver`.
  error ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

  /// @dev Attempted to redeem more shares than the max amount for `receiver`.
  error ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

  /// @dev Return token address managed by this vault.
  function asset() external view returns (address assetTokenAddress);

  /// @dev Return total token amout of this vault.
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /// @dev Return maximum amount of tokens user can withdraw.
  function maxWithdraw(address user) external view returns (uint256 tokenAmount);

  /// @dev Return maximum shares user can burn.
  function maxRedeem(address user) external view returns (uint256 shares);

  /// @dev Return the ideal amount of shares the Vault would exchange for the amount of tokens recieved.
  function convertToShares(uint256 assetAmount) external view returns (uint256 shares);

  /// @dev Return the ideal amount of tokens the Vault would exchange for the amount of shares.
  function convertToAssets(uint256 shares) external view returns (uint256 assetAmount);

  /**
   * @dev Return the actual shares would be recieved when deposit amount of tokens.
   * NOTE: this function may not equal to convertToShares because of tax, etc.
   */
  function previewDeposit(uint256 tokenAmount) external view returns (uint256 shares);

  /**
   * @dev Return the amount of shares need to burn in order to withdraw exactly an amount of tokens.
   * NOTE: this function may not equal to convertToShares because of tax, etc.
   */
  function previewWithdraw(uint256 tokenAmount) external view returns (uint256 shares);

  /**
   * @dev Return the token amount would need to deposit in order to mint exactly amount of shares.
   * NOTE: this function may not equal to convertToAssets because of tax, etc.
   */
  function previewMint(uint256 shares) external view returns (uint256 tokenAmount);

  /**
   * @dev Return the actual token amount would get when burn amount of shares.
   * NOTE: this function may not equal to convertToAssets because of tax, etc.
   */
  function previewRedeem(uint256 shares) external view returns (uint256 tokenAmount);

  /**
   * @dev Mint shares to the receiver based on the amount of tokens deposited to this Vault.
   *
   * Emit an {Deposit} event.
   */
  function deposit(uint256 tokenAmount, address receiver) external returns (uint256 shares);

  /**
   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * Emit an {Withdraw} event.
   */
  function withdraw(uint256 tokenAmount, address receiver, address owner) external returns (uint256 shares);

  /**
   * @dev Mint exactly amount of shares to the receiver by deposited to this Vault.
   *
   * Emit an {Deposit} event.
   */
  function mint(uint256 shares, address receiver) external returns (uint256 tokenAmount);

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * Emit an {Withdraw} event.
   */
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 tokenAmount);

  /**
   * @dev Pauses the Vault functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function pause() external;

  /**
   * @dev Unpauses the registrar controller's functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function unpause() external;
}
