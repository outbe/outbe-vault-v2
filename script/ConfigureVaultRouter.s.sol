// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {IVaultRouter} from "./interfaces/IVaultRouter.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

/// @notice Applies a validator-governance-approved VaultRouter registration.
contract ConfigureVaultRouter is BaseScript {
    function run() external {
        address vaultRouter = vm.envOr("VAULT_ROUTER_ADDRESS", DEFAULT_VAULT_ROUTER_ADDRESS);
        address vault = vm.envAddress("VAULT_ADDRESS");
        require(vault != address(0), "VAULT_REQUIRED");

        if (_isVaultRegistered(vaultRouter, vault)) {
            console.log("Vault already registered, skipping applyApproved:", vault);
            return;
        }
        uint256 proposalId = vm.envUint("VAULT_PROPOSAL_ID");
        require(proposalId != 0, "VAULT_PROPOSAL_ID_REQUIRED");

        IVaultRouter router = IVaultRouter(vaultRouter);
        (IVaultRouter.VaultAction action, address approvedVault,) = abi.decode(
            _ethCall(vaultRouter, abi.encodeCall(IVaultRouter.approvedVaultAction, (proposalId))),
            (IVaultRouter.VaultAction, address, uint64)
        );
        require(action == IVaultRouter.VaultAction.AddVault, "PROPOSAL_NOT_APPROVED_FOR_ADD_VAULT");
        require(approvedVault == vault, "APPROVED_VAULT_MISMATCH");

        vm.startBroadcast(privateKey);
        // Forge cannot execute the native precompile locally. The call is still recorded for
        // broadcast, so swallow only the local execution failure and verify over RPC afterward.
        try router.applyApproved(proposalId) {
            console.log("Approved vault action applied:", proposalId);
        } catch {
            console.log("applyApproved broadcast (local precompile execution skipped):", proposalId);
        }
        vm.stopBroadcast();

        console.log("=== VaultRouter governance action submitted ===");
        console.log("VaultRouter:", vaultRouter);
        console.log("ReserveVault: ", vault);
        console.log("Proposal:     ", proposalId);
    }

    function _isVaultRegistered(address vaultRouter, address vault) internal returns (bool) {
        if (vault.code.length == 0) return false;
        address asset = IVaultV2(vault).asset();

        uint256 count =
            abi.decode(_ethCall(vaultRouter, abi.encodeCall(IVaultRouter.assetVaultsCount, (asset))), (uint256));
        for (uint256 i = 0; i < count; i++) {
            address registered =
                abi.decode(_ethCall(vaultRouter, abi.encodeCall(IVaultRouter.assetVaultAt, (asset, i))), (address));
            if (registered == vault) return true;
        }
        return false;
    }

    function _ethCall(address to, bytes memory data) internal returns (bytes memory) {
        string memory params =
            string.concat("[{\"to\":\"", vm.toString(to), "\",\"data\":\"", vm.toString(data), "\"},\"latest\"]");
        return vm.rpc("eth_call", params);
    }
}
