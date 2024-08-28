// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseGeneralConfig } from "@fdk/BaseGeneralConfig.sol";
import { Contract } from "./utils/Contract.sol";

contract GeneralConfig is BaseGeneralConfig {
  constructor() BaseGeneralConfig("", "deployments/") { }

  function _setUpContracts() internal virtual override {
    _mapContractName(Contract.FloppyVault);
    _mapContractName(Contract.FLP);
  }

  function _mapContractName(Contract contractEnum) internal {
    _contractNameMap[contractEnum.key()] = contractEnum.name();
  }
}

//13dafbb54ac92cd783c508a17fb09b57a8a44bd4 wbct scrip
