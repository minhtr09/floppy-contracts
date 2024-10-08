// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseMigration } from "@fdk/BaseMigration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { GeneralConfig } from "./GeneralConfig.sol";
import "./interfaces/ISharedArgument.sol";
import { LibProxy } from "@fdk/libraries/LibProxy.sol";

abstract contract Migration is BaseMigration {
  ISharedArgument public constant config = ISharedArgument(address(CONFIG));

  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(GeneralConfig).creationCode);
  }

  function _sharedArguments() internal virtual override returns (bytes memory rawArgs) {
    ISharedArgument.SharedParameter memory param;

    if (network() == DefaultNetwork.RoninTestnet.key() || network() == DefaultNetwork.LocalHost.key()) {
      address defaultAdmin = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;
      address tempErc20Token = 0x7DCdfe41708fdB651bAAFD2A392A1eCB808A25FE;
      address proxyAdminOwner = 0x02eB3F2A2779A023ff5c700eddAc5620806fcf27;
      vm.label(defaultAdmin, "Default Admin");
      vm.label(tempErc20Token, "Temp Erc20 Token");

      // FloppyVault
      param.floppyVault.admin = defaultAdmin;
      param.floppyVault.token = tempErc20Token;
      param.floppyVault.taxPercent = 5_000;
      // FLP
      param.flp.owner = defaultAdmin;
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }

  function _checkAdmin(address deployedContract) internal {
    if (network() == DefaultNetwork.RoninTestnet.key()) {
      string memory proxyAdmin = vm.envString("PROXY_ADMIN");
      vm.assertEq(vm.toString(LibProxy.getProxyAdmin(address(deployedContract), false)), proxyAdmin);
    }
  }

  function _toSingletonArray(address addr) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = addr;
  }
}
