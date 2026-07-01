// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {IVaultProvider} from "./interfaces/IVaultProvider.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

/// @notice Registers the reserve vault on the VaultProvider.
contract ConfigureVaultProvider is BaseScript {
    function run() external {
        address vaultProvider = vm.envOr("VAULT_PROVIDER_ADDRESS", DEFAULT_VAULT_PROVIDER_ADDRESS);
        address vault = vm.envAddress("VAULT_ADDRESS");
        require(vault != address(0), "VAULT_REQUIRED");

        IVaultProvider provider = IVaultProvider(vaultProvider);

        if (_isVaultRegistered(vaultProvider, vault)) {
            console.log("Vault already registered, skipping addVault:", vault);
        } else {
            vm.startBroadcast(privateKey);
            // forge cannot execute the precompile locally, so this call reverts during the run
            // even though it succeeds on-chain. The transaction is still recorded and broadcast;
            // swallow the local revert so the script completes.
            try provider.addVault(vault) {
                console.log("Vault added:", vault);
            } catch {
                console.log("addVault broadcast (local precompile execution skipped):", vault);
            }
            vm.stopBroadcast();
        }

        console.log("=== VaultProvider configured ===");
        console.log("VaultProvider:", vaultProvider);
        console.log("ReserveVault: ", vault);
    }

    /// @dev True when `vault` is already registered under its `asset()` on the provider. The
    ///      provider is a precompile, so its views are queried over RPC (`eth_call`) rather than
    ///      through forge's local EVM, which cannot execute the precompile bytecode.
    function _isVaultRegistered(address vaultProvider, address vault) internal returns (bool) {
        if (vault.code.length == 0) return false;
        address asset = IVaultV2(vault).asset();

        uint256 count = abi.decode(
            _ethCall(vaultProvider, abi.encodeCall(IVaultProvider.assetVaultsCount, (asset))), (uint256)
        );
        for (uint256 i = 0; i < count; i++) {
            address registered = abi.decode(
                _ethCall(vaultProvider, abi.encodeCall(IVaultProvider.assetVaultAt, (asset, i))), (address)
            );
            if (registered == vault) return true;
        }
        return false;
    }

    /// @dev Performs `eth_call` against the live node so precompile logic runs natively.
    function _ethCall(address to, bytes memory data) internal returns (bytes memory) {
        string memory params = string.concat(
            "[{\"to\":\"", vm.toString(to), "\",\"data\":\"", vm.toString(data), "\"},\"latest\"]"
        );
        return vm.rpc("eth_call", params);
    }
}
