// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/voltz/IVoltzFactory.sol";
import "./IVaultGovernance.sol";
import "./IVoltzVault.sol";

interface IVoltzVaultGovernance is IVaultGovernance {

    struct delayedProtocolParams {
        IVoltzFactory voltzFactory; /// not sure about this
    }

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedProtocolParamsTimestamp.
    /// @param params New params
    function stagedDelayProtocolParams(DelayedProtocolParams calldata params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelatedProtocolParams() external;


    /// @notice Deploys a new vault.
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param owner_ Owner of the vault NFT
    function createVault(address[] memory vaultTokens_, address owner_)
        external 
        returns (IVoltzVault vault, uint256 nft);
}