// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {Create2} from "../lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";

import {VaultV2} from "../src/VaultV2.sol";
import {VaultProviderGateGuard} from "../src/VaultProviderGateGuard.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

contract DeployVault is BaseScript {
    function run() external returns (address vaultAddress) {
        address vaultProvider = vm.envOr("VAULT_PROVIDER_ADDRESS", DEFAULT_VAULT_PROVIDER_ADDRESS);
        address asset = vm.envAddress("ERC20_ADDRESS");
        require(asset != address(0), "ERC20_ADDRESS_REQUIRED");

        bytes32 salt = generateSalt("Vault");
        bytes memory creationCode = abi.encodePacked(type(VaultV2).creationCode, abi.encode(owner, asset));
        vaultAddress = Create2.computeAddress(salt, keccak256(creationCode), CREATE2_FACTORY);

        // The gate guard is a plain Solidity contract that mirrors the VaultProvider precompile's
        // gate hooks (only the provider may move shares/assets), so the vault's gates point at it
        // instead of at the precompile. Its CREATE2 address is a deterministic function of the provider.
        bytes32 guardSalt = generateSalt("VaultProviderGateGuard");
        bytes memory guardCreationCode =
            abi.encodePacked(type(VaultProviderGateGuard).creationCode, abi.encode(vaultProvider));
        address guardAddress = Create2.computeAddress(guardSalt, keccak256(guardCreationCode), CREATE2_FACTORY);

        string memory assetName = IERC20(asset).name();
        string memory assetSymbol = IERC20(asset).symbol();

        string memory vaultName = string.concat("Vault for ", assetName);
        string memory vaultSymbol = string.concat("v", assetSymbol);

        IVaultV2 vault = IVaultV2(vaultAddress);

        bool alreadyDeployed = vaultAddress.code.length != 0;
        // sendAssetsGate is the last gate wired in _setVaultGates, so it doubles as a
        // "fully configured" sentinel. Reading it is safe: it is VaultV2 storage, not a
        // call into the gate. It is set to the guard, so compare against guardAddress.
        bool alreadyConfigured = alreadyDeployed && vault.sendAssetsGate() == guardAddress;

        if (alreadyConfigured) {
            console.log("Vault already deployed and configured, skipping:", vaultAddress);
        } else {
            vm.startBroadcast(privateKey);

            if (!alreadyDeployed) {
                Create2.deploy(0, salt, creationCode);
            }

            // Deploy the gate guard if it is not already present.
            if (guardAddress.code.length == 0) {
                Create2.deploy(0, guardSalt, guardCreationCode);
            }

            vault.setName(vaultName);
            vault.setSymbol(vaultSymbol);
            vault.setCurator(owner);

            // Route the vault's four transfer gates through the VaultProviderGateGuard so the
            // VaultProvider is the only address allowed to move shares/assets in and out of the reserve.
            _setVaultGates(vault, guardAddress);

            vm.stopBroadcast();
        }

        printAndWrite(exportLine("VAULT_ADDRESS", vm.toString(vaultAddress)));
        printAndWrite(exportLine("VAULT_SYMBOL", vaultSymbol));
        printAndWrite(exportLine("VAULT_NAME", vaultName));
        printAndWrite(exportLine("VAULT_PROVIDER_GATE_GUARD_ADDRESS", vm.toString(guardAddress)));
    }

    /// @dev Points all four VaultV2 gates at `gate` via the submit+set timelock dance.
    function _setVaultGates(IVaultV2 vault, address gate) internal {
        vault.submit(abi.encodeCall(IVaultV2.setReceiveSharesGate, (gate)));
        vault.setReceiveSharesGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setSendSharesGate, (gate)));
        vault.setSendSharesGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setReceiveAssetsGate, (gate)));
        vault.setReceiveAssetsGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setSendAssetsGate, (gate)));
        vault.setSendAssetsGate(gate);
    }
}
