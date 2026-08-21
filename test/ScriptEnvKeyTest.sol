// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {BaseScript} from "../script/BaseScript.s.sol";

/// @dev Exposes BaseScript's internal key helpers for testing.
contract BaseScriptHarness is BaseScript {
    function exposedEnvPrivateKeyOr(string memory name, uint256 fallbackKey) external view returns (uint256) {
        return envPrivateKeyOr(name, fallbackKey);
    }
}

contract ScriptEnvKeyTest is Test {
    uint256 internal constant ROUTER_KEY = 0xB0B;
    uint256 internal constant DEPLOY_KEY = 0xDEED;

    function harness() internal returns (BaseScriptHarness) {
        return new BaseScriptHarness();
    }

    function testReturnsParsedKeyWhenSet() public {
        vm.setEnv("VAULT_ROUTER_PRIVATE_KEY", vm.toString(bytes32(ROUTER_KEY)));
        assertEq(harness().exposedEnvPrivateKeyOr("VAULT_ROUTER_PRIVATE_KEY", DEPLOY_KEY), ROUTER_KEY);
    }

    function testAcceptsKeyWithoutHexPrefix() public {
        vm.setEnv("VAULT_ROUTER_PRIVATE_KEY", "0b0b");
        assertEq(harness().exposedEnvPrivateKeyOr("VAULT_ROUTER_PRIVATE_KEY", DEPLOY_KEY), 0x0b0b);
    }

    function testFallsBackWhenEmpty() public {
        vm.setEnv("VAULT_ROUTER_PRIVATE_KEY", "");
        assertEq(harness().exposedEnvPrivateKeyOr("VAULT_ROUTER_PRIVATE_KEY", DEPLOY_KEY), DEPLOY_KEY);
    }

    function testFallsBackWhenUnset() public {
        assertEq(harness().exposedEnvPrivateKeyOr("VAULT_ROUTER_PRIVATE_KEY_UNSET", DEPLOY_KEY), DEPLOY_KEY);
    }
}
