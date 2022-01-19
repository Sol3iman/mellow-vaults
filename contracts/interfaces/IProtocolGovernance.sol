// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param permissionless If `true` anyone can spawn vaults, o/w only Protocol Governance Admin
    /// @param maxTokensPerVault Max different token addresses that could be managed by the protocol
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged verification scripts for the given selector address can be committed.
    /// @param selectorAddress Address combined with selector (right 4 bytes for selector)
    /// @return Zero if there are no staged verification scripts, timestamp otherwise
    function stagedVerificationScriptsTimestamps(uint256 selectorAddress) external view returns (uint256);

    /// @notice Staged verification scripts for the given selector address.
    /// @param selectorAddress Address combined with selector (right 4 bytes for selector)
    /// @return Staged verification script
    function stagedVerificationScripts(uint256 selectorAddress) external view returns (bytes memory);

    /// @notice Verification scripts for the given selector address.
    /// @param selectorAddress Address combined with selector (right 4 bytes for selector)
    /// @return Verification script, an evm-like bytecode for verification
    function verificationScripts(uint256 selectorAddress) external view returns (bytes memory);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function pendingParamsTimestamp() external view returns (uint256);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged granted permission grant.
    function rollbackAllPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commits all staged permission grants for which governance delay passed
    function commitAllPermissionGrantsSurpassedDelay() external;

    /// @notice Revoke permission instantly for the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Reset verification script instantly for the given selectorAddress.
    /// @param selectorAddress Address combined with selector (right 4 bytes for selector)
    function resetVerificationScript(address selectorAddress) external;

    /// @notice Commits all verification scripts for which delay passed
    function commitAllVerificationScriptsSurpassedDelay() external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function setPendingParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could be committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;

    /// @notice Stage verification script that could be committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param selectorAddress Address combined with selector (right 4 bytes for selector)
    /// @param verificationScript Script to stage
    function stageVerificationScript(uint256 selectorAddress, bytes memory verificationScript) external;
}
