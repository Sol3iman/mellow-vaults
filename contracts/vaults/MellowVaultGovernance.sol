// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "../interfaces/vaults/IMellowVault.sol";
import "../interfaces/vaults/IMellowVaultGovernance.sol";
import "../libraries/ExceptionsLibrary.sol";
import "./VaultGovernance.sol";

/// @notice Governance that manages all Mellow Vaults params and can deploy a new Mellow Vault.
contract MellowVaultGovernance is IMellowVaultGovernance, VaultGovernance {
    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) VaultGovernance(internalParams_) {}

    /// @inheritdoc IMellowVaultGovernance
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        IERC20RootVault underlyingVault
    ) external returns (IMellowVault vault, uint256 nft) {
        address vaddr;
        (vaddr, nft) = _createVault(owner_);
        vault = IMellowVault(vaddr);
        vault.initialize(nft, vaultTokens_, underlyingVault);
    }
}
