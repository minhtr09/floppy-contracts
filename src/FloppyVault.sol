// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// import "@oenzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC20, IERC20} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@interfaces/IFloppyVault.sol";

contract FloppyVault is IFloppyVault, ERC20Upgradeable, Initializable {
    /// @dev Gap for upgradability.
    uint256[50] private _____gap;
    /// @dev Address of the token asset.
    IERC20 internal _asset;

    constructor() ERC20("", "") {
        _disableInitializers();
    }

    function initialize(IERC20 asset) external initializer {
        if (address(asset) == address(0)) revert InvalidAssetAddress();
        _asset = asset;
        _totalSupply = 10e9 * 1e18; // 10 billions.
        _name = "Floppy Vault";
        _symbol = "FVT";
    }

    /// @inheritdoc IFloppyVault
    function asset() external view returns (address assetTokenAddress) {
        assetTokenAddress = address(_asset);
    }

    /// @inheritdoc IFloppyVault
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /// @inheritdoc IFloppyVault
    function convertToShares(
        uint256 assetAmount
    ) external view returns (uint256 shares);

    /// @inheritdoc IFloppyVault
    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assetAmount);

    /// @inheritdoc IFloppyVault
    function previewDeposit(
        uint256 tokenAmount
    ) external view returns (uint256 shares);

    /// @inheritdoc IFloppyVault
    function previewWithdraw(
        uint256 tokenAmount
    ) external view returns (uint256 shares);

    /// @inheritdoc IFloppyVault
    function previewMint(
        uint256 shares
    ) external view returns (uint256 tokenAmount);

    /// @inheritdoc IFloppyVault
    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 tokenAmount);

    /// @inheritdoc IFloppyVault
    function deposit(
        uint256 tokenAmount,
        address receiver
    ) external returns (uint256 shares);

    /// @inheritdoc IFloppyVault
    function withdraw(
        uint256 tokenAmount,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /// @inheritdoc IFloppyVault
    function mint(
        uint256 shares,
        address receiver
    ) external returns (uint256 tokenAmount);

    /// @inheritdoc IFloppyVault
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 tokenAmount);
}
