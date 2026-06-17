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

        vm.stopBroadcast();

        printAndWrite(exportLine("VAULT_ADDRESS", vm.toString(vault)));
        printAndWrite(exportLine("VAULT_SYMBOL", assetSymbol));
    }
}
