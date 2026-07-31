// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {
    IReceiveSharesGate,
    ISendSharesGate,
    IReceiveAssetsGate,
    ISendAssetsGate
} from "./interfaces/IGate.sol";

/// @notice VaultV2 gate that only permits the VaultRouter to move shares/assets.
/// @dev Replicates the VaultRouter precompile's gate hooks as an auditable Solidity
///      contract. All four checks return true only for the configured router address.
contract VaultRouterGateGuard is
    IReceiveSharesGate,
    ISendSharesGate,
    IReceiveAssetsGate,
    ISendAssetsGate
{
    address public immutable vaultRouter;

    constructor(address _vaultRouter) {
        require(_vaultRouter != address(0), "VAULT_ROUTER_REQUIRED");
        vaultRouter = _vaultRouter;
    }

    function canReceiveShares(address account) external view returns (bool) {
        return account == vaultRouter;
    }

    function canSendShares(address account) external view returns (bool) {
        return account == vaultRouter;
    }

    function canReceiveAssets(address account) external view returns (bool) {
        return account == vaultRouter;
    }

    function canSendAssets(address account) external view returns (bool) {
        return account == vaultRouter;
    }
}
