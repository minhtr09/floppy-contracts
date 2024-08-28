// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGeneralConfig } from "@fdk/interfaces/IGeneralConfig.sol";
import { FloppyVault } from "@contracts/FloppyVault.sol";

interface ISharedArgument is IGeneralConfig {
  struct FloppyVaultParam {
    address admin;
    address token;
    uint256 taxPercent;
  }

  struct FLPParam {
    address owner;
  }

  struct SharedParameter {
    FloppyVaultParam floppyVault;
    FLPParam flp;
  }

  function sharedArguments() external view returns (SharedParameter memory param);
}
