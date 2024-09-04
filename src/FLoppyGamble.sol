// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@interfaces/IFloppyGamble.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract FloppyGamble is IFloppyGamble, Initializable, Ownable {
  uint256 public constant MAX_PERCENTAGE = 100_000;
  /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
  /// @dev keccak256("Permit(address requester,address receiver,uint256 points,uint256 betAmount,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x94f4aee5e6d55f6240dc5a2f99ac56687f70186dfc1647b622b06d9de812dd92;
  bytes32 public DOMAIN_SEPARATOR;
  /// @dev Mapping of bet IDs to their corresponding bet information
  mapping(uint256 betId => BetInfo info) internal _bets;
  /// @dev Mapping of bet tiers to their corresponding points ranges
  mapping(BetTier tier => PointsRange range) internal _pointsRanges;
  /// @dev Mapping of bet tiers to their corresponding reward percentages
  mapping(BetTier tier => uint256 rewardPercentage) internal _rewardPercentages;
  /// @dev Counter for bet IDs
  uint256 internal _ids;
  /// @dev Maximum allowed bet amount
  uint256 internal _maxBetAmount;
  /// @dev Minimum allowed bet amount
  uint256 internal _minBetAmount;
  /// @dev Percentage of the bet amount to be deducted as a penalty when a bet is canceled
  uint256 internal _penaltyForCanceledBet;
  /// @dev Address of the signer for bet validation
  address internal _signer;
  /// @dev ERC20 token used for betting
  IERC20 internal _asset;
  /// @dev Address of the wallet used to distribute rewards
  address internal _wallet;
  /// @dev Reserved space for upgradeability
  uint256[50] private _____gap;

  constructor() Ownable(_msgSender()) {
    _disableInitializers();
  }

  function initialize(
    IERC20 asset,
    address wallet,
    uint256 maxBetAmount,
    uint256 minBetAmount,
    address signer,
    uint256 penaltyForCanceledBet,
    // Points ranges for each bet tier
    // pointsRanges[0] -> Bronze
    // pointsRanges[1] -> Silver
    // pointsRanges[2] -> Gold
    // pointsRanges[3] -> Diamond
    PointsRange[4] calldata pointsRanges,
    // Reward percentages for each bet tier
    // rewardPercentages[0] -> Bronze
    // rewardPercentages[1] -> Silver
    // rewardPercentages[2] -> Gold
    // rewardPercentages[3] -> Diamond
    uint256[4] calldata rewardPercentages
  ) external initializer {
    _transferOwnership(_msgSender());
    _updateDomainSeparator();
    _asset = asset;
    _wallet = wallet;
    _signer = signer;
    _maxBetAmount = maxBetAmount;
    _minBetAmount = minBetAmount;
    _penaltyForCanceledBet = penaltyForCanceledBet;
    _pointsRanges[BetTier.Bronze] = pointsRanges[0];
    _pointsRanges[BetTier.Silver] = pointsRanges[1];
    _pointsRanges[BetTier.Gold] = pointsRanges[2];
    _pointsRanges[BetTier.Diamond] = pointsRanges[3];
    _rewardPercentages[BetTier.Bronze] = rewardPercentages[0];
    _rewardPercentages[BetTier.Silver] = rewardPercentages[1];
    _rewardPercentages[BetTier.Gold] = rewardPercentages[2];
    _rewardPercentages[BetTier.Diamond] = rewardPercentages[3];
  }

  /// @inheritdoc IFloppyGamble
  function placeBet(address receiver, uint256 amount, BetTier tier) external {
    if (amount > _maxBetAmount || amount < _minBetAmount) revert InvalidBetAmount();
    if (tier == BetTier.Unknown) revert InvalidBetTier();
    if (receiver == address(0)) revert NullAddress();

    SafeERC20.safeTransferFrom(_asset, _msgSender(), address(this), amount);
    uint256 id = _ids++;

    _bets[id] = BetInfo({
      requester: _msgSender(),
      receiver: receiver,
      amount: amount,
      tier: tier,
      status: BetStatus.Pending,
      points: 0,
      reward: 0,
      win: false,
      claimed: false
    });

    emit BetPlaced(_msgSender(), id);
  }

  /// @inheritdoc IFloppyGamble
  function cancelBet(uint256 betId) external {
    BetInfo storage betInfo = _bets[betId];
    if (betInfo.status != BetStatus.Pending) revert BetNotPending(betId);
    if (betInfo.requester != _msgSender()) revert ErrNotRequester();

    uint256 betAmount = betInfo.amount;
    uint256 penaltyAmount = betAmount * _penaltyForCanceledBet / MAX_PERCENTAGE;
    SafeERC20.safeTransfer(_asset, _wallet, penaltyAmount);
    SafeERC20.safeTransfer(_asset, _msgSender(), betAmount - penaltyAmount);

    betInfo.status = BetStatus.Canceled;
    emit BetCanceled(_msgSender(), betId);
  }

  /// @inheritdoc IFloppyGamble
  function resolveBet(uint256 betId, uint256 points, uint256 deadline, bytes memory signature) external {
    BetInfo storage betInfo = _bets[betId];
    if (deadline < block.timestamp) revert SignatureExpired();
    if (betInfo.status != BetStatus.Pending) revert BetNotPending(betId);

    _validateSignature(betInfo.requester, betInfo.receiver, points, betInfo.amount, deadline, signature);

    betInfo.status = BetStatus.Resolved;
    betInfo.points = points;
    betInfo.win = points >= _pointsRanges[betInfo.tier].minPoints;
    if (betInfo.win) {
      betInfo.reward = betInfo.amount * _rewardPercentages[betInfo.tier] / MAX_PERCENTAGE;
    }

    emit BetResolved(betId);
  }

  /// @inheritdoc IFloppyGamble
  function resolveBetAndClaimReward(
    uint256 betId,
    uint256 points,
    uint256 deadline,
    bytes memory signature
  ) external returns (uint256 rewardAmount) {
    this.resolveBet(betId, points, deadline, signature);
    rewardAmount = this.claimReward(betId);
  }

  /// @inheritdoc IFloppyGamble
  function claimReward(uint256 betId) external returns (uint256 rewardAmount) {
    BetInfo storage betInfo = _bets[betId];
    if (betInfo.status != BetStatus.Resolved) revert BetNotResolved(betId);
    if (!betInfo.win) revert BetLost(betId);
    if (betInfo.claimed) revert RewardAlreadyClaimed(betId);

    betInfo.claimed = true;
    rewardAmount = betInfo.reward;
    _claimReward(betInfo.receiver, rewardAmount);
  }

  /// @inheritdoc IFloppyGamble
  function setMinBetAmount(uint256 minBetAmount) external onlyOwner {
    _minBetAmount = minBetAmount;
    emit MinBetAmountUpdated(minBetAmount);
  }

  /// @inheritdoc IFloppyGamble
  function setMaxBetAmount(uint256 maxBetAmount) external onlyOwner {
    _maxBetAmount = maxBetAmount;
    emit MaxBetAmountUpdated(maxBetAmount);
  }

  /// @inheritdoc IFloppyGamble
  function setSigner(address signer) external onlyOwner {
    _signer = signer;
    emit SignerUpdated(signer);
  }

  /// @inheritdoc IFloppyGamble
  function setAsset(IERC20 asset) external onlyOwner {
    _asset = asset;
    emit AssetUpdated(address(asset));
  }

  /// @inheritdoc IFloppyGamble
  function setWallet(address wallet) external onlyOwner {
    _wallet = wallet;
    emit WalletUpdated(wallet);
  }

  /// @inheritdoc IFloppyGamble
  function setPenaltyForCanceledBet(uint256 penaltyForCanceledBet) external onlyOwner {
    _penaltyForCanceledBet = penaltyForCanceledBet;
    emit PenaltyForCanceledBetUpdated(penaltyForCanceledBet);
  }

  /// @inheritdoc IFloppyGamble
  function setPointsRanges(PointsRange[] calldata pointsRanges) external onlyOwner {
    if (pointsRanges.length != 4) revert InvalidLength();
    _pointsRanges[BetTier.Bronze] = pointsRanges[0];
    _pointsRanges[BetTier.Silver] = pointsRanges[1];
    _pointsRanges[BetTier.Gold] = pointsRanges[2];
    _pointsRanges[BetTier.Diamond] = pointsRanges[3];
    emit PointsRangesUpdated(pointsRanges);
  }

  /// @inheritdoc IFloppyGamble
  function setRewardPercentages(uint256[] calldata rewardPercentages) external onlyOwner {
    if (rewardPercentages.length != 4) revert InvalidLength();
    _rewardPercentages[BetTier.Bronze] = rewardPercentages[0];
    _rewardPercentages[BetTier.Silver] = rewardPercentages[1];
    _rewardPercentages[BetTier.Gold] = rewardPercentages[2];
    _rewardPercentages[BetTier.Diamond] = rewardPercentages[3];
    emit RewardPercentagesUpdated(rewardPercentages);
  }

  /// @inheritdoc IFloppyGamble
  function getMaxPointsForTier(BetTier tier) external view returns (uint256) {
    return _pointsRanges[tier].maxPoints;
  }

  /// @inheritdoc IFloppyGamble
  function getMinPointsForTier(BetTier tier) external view returns (uint256) {
    return _pointsRanges[tier].minPoints;
  }

  /// @inheritdoc IFloppyGamble
  function getMaxPointsRangeForTier(BetTier tier) external view returns (uint256, uint256) {
    PointsRange memory range = _pointsRanges[tier];
    return (range.minPoints, range.maxPoints);
  }

  /// @inheritdoc IFloppyGamble
  function getReward(BetTier tier, uint256 betAmount) external view returns (uint256) {
    return betAmount * _rewardPercentages[tier] / MAX_PERCENTAGE;
  }

  /// @inheritdoc IFloppyGamble
  function getBetInfo(uint256 betId) external view returns (BetInfo memory) {
    return _bets[betId];
  }

  /// @inheritdoc IFloppyGamble
  function getMaxBetAmount() external view returns (uint256) {
    return _maxBetAmount;
  }

  /// @inheritdoc IFloppyGamble
  function getMinBetAmount() external view returns (uint256) {
    return _minBetAmount;
  }

  /// @inheritdoc IFloppyGamble
  function getSigner() external view returns (address) {
    return _signer;
  }

  /// @inheritdoc IFloppyGamble
  function getAsset() external view returns (address) {
    return address(_asset);
  }

  /// @inheritdoc IFloppyGamble
  function getWallet() external view returns (address) {
    return _wallet;
  }

  /// @dev Helper function for claiming reward.
  function _claimReward(address receiver, uint256 amount) internal {
    SafeERC20.safeTransfer(_asset, receiver, amount);
    emit RewardClaimed(receiver, amount);
  }

  function _validateSignature(
    address requester,
    address receiver,
    uint256 points,
    uint256 betAmount,
    uint256 deadline,
    bytes memory signature
  ) internal {
    address signer = ECDSA.recover(
      MessageHashUtils.toTypedDataHash(
        DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, requester, receiver, points, betAmount, deadline))
      ),
      signature
    );
    if (signer != _signer) revert InvalidSignature();
  }

  /// @dev Updates domain separator.
  function _updateDomainSeparator() internal {
    bytes32 nameHash = keccak256(bytes("FloppyGamble"));
    bytes32 versionHash = keccak256(bytes("1"));
    assembly ("memory-safe") {
      let free_mem_ptr := mload(0x40) // Load the free memory pointer.
      mstore(free_mem_ptr, DOMAIN_TYPEHASH)
      mstore(add(free_mem_ptr, 0x20), nameHash)
      mstore(add(free_mem_ptr, 0x40), versionHash)
      mstore(add(free_mem_ptr, 0x60), chainid())
      mstore(add(free_mem_ptr, 0x80), address())
      sstore(DOMAIN_SEPARATOR.slot, keccak256(free_mem_ptr, 0xa0))
    }
  }
}
