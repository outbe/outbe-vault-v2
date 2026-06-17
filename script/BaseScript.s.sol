// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";

contract BaseScript is Script {
    string public constant SALT_VERSION = "v0.0.1";

    address internal owner;
    uint256 internal privateKey;

    function setUp() public {
        privateKey = deployerPrivateKey();
        address signer = vm.addr(privateKey);
        owner = vm.envOr("OWNER_ADDRESS", signer);
    }

    function deployerPrivateKey() internal view returns (uint256) {
        string memory raw = vm.envString("PRIVATE_KEY");
        if (bytes(raw).length >= 2 && bytes(raw)[0] == "0" && (bytes(raw)[1] == "x" || bytes(raw)[1] == "X")) {
            return vm.parseUint(raw);
        }
        return vm.parseUint(string.concat("0x", raw));
    }

    function exportLine(string memory name, string memory value) public pure returns (string memory) {
        return string.concat("export ", name, "=", value);
    }

    function getEnvName() public view returns (string memory) {
        uint256 chainId = block.chainid;

        if (chainId == 31337) return "anvil";
        if (chainId == 424242) return "outbe-dev";
        if (chainId == 424243) return "local-dev";
        if (chainId == 97) return "bsc-testnet";
        if (chainId == 1) return "mainnet";
        if (chainId == 11155111) return "sepolia";
        if (chainId == 137) return "polygon";
        if (chainId == 42161) return "arbitrum";
        if (chainId == 10) return "optimism";
        if (chainId == 8453) return "base";
        if (chainId == 512512) return "outbe-privnet";
        if (chainId == 512215) return "local-reth";
        if (chainId == 54322345) return "outbe-peira";

        return string.concat("chain-", vm.toString(chainId));
    }

    function deploymentFile() public view returns (string memory) {
        return string.concat(".", getEnvName(), ".deployment.env");
    }

    function writeToDeploymentFile(string memory data) public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/", deploymentFile());
        vm.writeLine(path, data);
    }

    function printAndWrite(string memory data) public {
        console.log(data);
        writeToDeploymentFile(data);
    }

    function generateSalt(string memory name) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(name, block.chainid, SALT_VERSION));
    }
}
