// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {Create2} from "../lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import {BaseScript} from "./BaseScript.s.sol";

import {VaultV2} from "../src/VaultV2.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IVaultV2} from "../src/interfaces/IVaultV2.sol";

contract DeployVault is BaseScript {
    function run() external returns (address vault) {
        address asset = vm.envAddress("ERC20_ADDRESS");
        string memory vaultName = vm.envString("VAULT_NAME");
        address vaultProvider = vm.envAddress("VAULT_PROVIDER_ADDRESS");
        require(vaultProvider != address(0), "VAULT_PROVIDER_REQUIRED");

        bytes32 salt = generateSalt("Vault");
        bytes memory creationCode = abi.encodePacked(type(VaultV2).creationCode, abi.encode(owner, asset));
        vault = Create2.computeAddress(salt, keccak256(creationCode), CREATE2_FACTORY);

        vm.startBroadcast(privateKey);
        if (vault.code.length == 0) {
            Create2.deploy(0, salt, creationCode);
        }

        string memory assetSymbol = IERC20(asset).symbol();

        IVaultV2(vault).setName(vaultName);
        IVaultV2(vault).setSymbol(assetSymbol);
        IVaultV2(vault).setCurator(owner);

        // Route the vault's four transfer gates to the VaultProvider so it is the
        // only address allowed to move shares/assets in and out of the reserve.
        _setVaultGates(IVaultV2(vault), vaultProvider);

        vm.stopBroadcast();

        printAndWrite(exportLine("VAULT_ADDRESS", vm.toString(vault)));
        printAndWrite(exportLine("VAULT_SYMBOL", assetSymbol));
    }

    /// @dev Points all four VaultV2 gates at `gate` via the submit+set timelock dance,
    ///      then verifies the gates took effect and `gate` ends up unblocked.
    function _setVaultGates(IVaultV2 vault, address gate) internal {
        vault.submit(abi.encodeCall(IVaultV2.setReceiveSharesGate, (gate)));
        vault.setReceiveSharesGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setSendSharesGate, (gate)));
        vault.setSendSharesGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setReceiveAssetsGate, (gate)));
        vault.setReceiveAssetsGate(gate);
        vault.submit(abi.encodeCall(IVaultV2.setSendAssetsGate, (gate)));
        vault.setSendAssetsGate(gate);

        require(vault.receiveSharesGate() == gate, "RECEIVE_SHARES_GATE_NOT_SET");
        require(vault.sendSharesGate() == gate, "SEND_SHARES_GATE_NOT_SET");
        require(vault.receiveAssetsGate() == gate, "RECEIVE_ASSETS_GATE_NOT_SET");
        require(vault.sendAssetsGate() == gate, "SEND_ASSETS_GATE_NOT_SET");
        require(vault.canReceiveShares(gate), "VAULT_PROVIDER_RECEIVE_SHARES_BLOCKED");
        require(vault.canSendShares(gate), "VAULT_PROVIDER_SEND_SHARES_BLOCKED");
        require(vault.canSendAssets(gate), "VAULT_PROVIDER_DEPOSIT_BLOCKED");
        require(vault.canReceiveAssets(gate), "VAULT_PROVIDER_WITHDRAW_BLOCKED");
    }
}
