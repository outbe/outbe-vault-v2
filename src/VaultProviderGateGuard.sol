// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.28;

import {
    IReceiveSharesGate,
    ISendSharesGate,
    IReceiveAssetsGate,
    ISendAssetsGate
} from "./interfaces/IGate.sol";

/// @notice VaultV2 gate that only permits the VaultProvider to move shares/assets.
/// @dev Replicates the VaultProvider precompile's gate hooks as an auditable Solidity
///      contract. All four checks return true only for the configured provider address.
contract VaultProviderGateGuard is
    IReceiveSharesGate,
    ISendSharesGate,
    IReceiveAssetsGate,
    ISendAssetsGate
{
    address public immutable vaultProvider;

    constructor(address _vaultProvider) {
        require(_vaultProvider != address(0), "VAULT_PROVIDER_REQUIRED");
        vaultProvider = _vaultProvider;
    }

    function canReceiveShares(address account) external view returns (bool) {
        return account == vaultProvider;
    }

    function canSendShares(address account) external view returns (bool) {
        return account == vaultProvider;
    }

    function canReceiveAssets(address account) external view returns (bool) {
        return account == vaultProvider;
    }

    function canSendAssets(address account) external view returns (bool) {
        return account == vaultProvider;
    }
}
