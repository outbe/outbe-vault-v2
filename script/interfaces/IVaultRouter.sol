// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @notice Subset of the VaultRouter native precompile ABI (deployed at a fixed
///         predeploy address) used by the deployment scripts. The canonical
///         interface lives in the outbe-chain repo at
///         contracts/precompiles/src/IVaultRouter.sol.
interface IVaultRouter {
    /// @notice Returns the number of vaults registered for `asset`.
    function assetVaultsCount(address asset) external view returns (uint256);

    /// @notice Returns the reserve vault at `index` for `asset`. Reverts if out of bounds.
    function assetVaultAt(address asset, uint256 index) external view returns (address vault);

    /// @notice Registers an ownerless `vault` for its underlying asset and ISO 4217
    ///         reference currency. Reverts if the vault owner is not renounced, the
    ///         asset has no reference currency, or the vault is already registered.
    function addVault(address vault) external;
}
