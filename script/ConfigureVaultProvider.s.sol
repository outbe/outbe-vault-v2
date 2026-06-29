// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {IVaultProvider} from "../src/interfaces/IVaultProvider.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

/// @notice Registers the reserve vault and the liquidity routes on the VaultProvider.
/// @dev The VaultProvider is a native precompile at `VAULT_PROVIDER_ADDRESS`; this
///      script only configures it (nothing is deployed). Mirrors the registration
///      logic that used to live in the old DeployVaultProvider script.
///      Env:
///        PRIVATE_KEY            - broadcaster, must be the VaultProvider owner
///        VAULT_PROVIDER_ADDRESS - VaultProvider precompile
///        VAULT_ADDRESS          - reserve vault to register (asset read from the vault)
///        CREDIS_FACTORY_ADDRESS - CredisAnadosis liquidity source + Credis liquidity target
///        GEM_FACTORY_ADDRESS    - GemSettle liquidity source (deposit-only)
///        INTEX_FACTORY_ADDRESS  - IntexStrikePrice liquidity source (deposit-only)
contract ConfigureVaultProvider is BaseScript {
    function run() external {
        address vaultProvider = vm.envAddress("VAULT_PROVIDER_ADDRESS");
        address reserveVault = vm.envAddress("VAULT_ADDRESS");
        address credisFactory = vm.envAddress("CREDIS_FACTORY_ADDRESS");
        address gemFactory = vm.envAddress("GEM_FACTORY_ADDRESS");
        address intexFactory = vm.envAddress("INTEX_FACTORY_ADDRESS");

        require(vaultProvider != address(0), "VAULT_PROVIDER_REQUIRED");
        require(reserveVault != address(0), "VAULT_REQUIRED");

        IVaultProvider provider = IVaultProvider(vaultProvider);

        vm.startBroadcast(privateKey);

        if (_isVaultRegistered(provider, reserveVault)) {
            console.log("WARN: vault already added, skipping:", reserveVault);
        } else {
            provider.addVault(reserveVault);
            console.log("Vault added:", reserveVault);
        }

        provider.addLiquiditySource(credisFactory, IVaultProvider.LiquiditySource.CredisAnadosis);
        provider.addLiquidityTarget(credisFactory, IVaultProvider.LiquidityTarget.Credis);
        provider.addLiquiditySource(gemFactory, IVaultProvider.LiquiditySource.GemSettle);
        provider.addLiquiditySource(intexFactory, IVaultProvider.LiquiditySource.IntexStrikePrice);

        vm.stopBroadcast();

        console.log("=== VaultProvider configured ===");
        console.log("VaultProvider:", vaultProvider);
        console.log("ReserveVault: ", reserveVault);
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
