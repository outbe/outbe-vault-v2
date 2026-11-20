// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @notice Subset of the VaultRouter native precompile ABI (deployed at a fixed
///         predeploy address) used by the deployment scripts. The canonical
///         interface lives in the outbe-chain repo at
///         contracts/precompiles/src/IVaultRouter.sol.
interface IVaultRouter {
    enum VaultAction {
        Unknown,
        AddVault,
        RemoveVault
    }

    /// @notice Returns the number of vaults registered for `asset`.
    function assetVaultsCount(address asset) external view returns (uint256);

    /// @notice Returns the reserve vault at `index` for `asset`. Reverts if out of bounds.
    function assetVaultAt(address asset, uint256 index) external view returns (address vault);

    /// @notice Applies a pending vault action once. Anyone may call. Strictly after the
    ///         governance window, deletes the record and emits VaultActionExpired instead.
    function applyVaultAction(uint256 proposalId) external;

    /// @notice Returns the pending vault action, or Unknown if no record remains.
    function getVaultAction(uint256 proposalId)
        external
        view
        returns (VaultAction action, address vault, uint64 createdAt);
}
