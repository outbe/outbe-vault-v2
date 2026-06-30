// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {IVaultProvider} from "../src/interfaces/IVaultProvider.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

/// @notice Registers the reserve vault on the VaultProvider.
contract ConfigureVaultProvider is BaseScript {
    function run() external {
        address vaultProvider = vm.envOr("VAULT_PROVIDER_ADDRESS", DEFAULT_VAULT_PROVIDER_ADDRESS);
        address vault = vm.envAddress("VAULT_ADDRESS");
        require(vault != address(0), "VAULT_REQUIRED");

        IVaultProvider provider = IVaultProvider(vaultProvider);

        vm.startBroadcast(privateKey);

        if (_isVaultRegistered(provider, vault)) {
            console.log("WARN: vault already added, skipping:", vault);
        } else {
            provider.addVault(vault);
            console.log("Vault added:", vault);
        }

        vm.stopBroadcast();

        console.log("=== VaultProvider configured ===");
        console.log("VaultProvider:", vaultProvider);
        console.log("ReserveVault: ", vault);
    }

    /// @dev Returns true when `vault` is already registered under its `asset()` in `provider`.
    ///      Used to skip `addVault` on re-runs so the broadcast does not include a call
    ///      that would revert with ReserveVaultAlreadyAdded().
    function _isVaultRegistered(IVaultProvider provider, address vault) internal view returns (bool) {
        if (vault.code.length == 0) return false;
        address asset = IVaultV2(vault).asset();
        uint256 count = provider.assetVaultsCount(asset);
        for (uint256 i = 0; i < count; i++) {
            if (provider.assetVaultAt(asset, i) == vault) {
                return true;
            }
        }
        return false;
    }
}
