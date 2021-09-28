// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./access/GovernanceAccessControl.sol";

contract VaultsParams is GovernanceAccessControl {
    bool public permissionless = false;
    bool public pendingPermissionless;
    uint256 public maxTokensPerVault = 10;
    uint256 public pendingMaxTokensPerVault;

    /// -------------------  PUBLIC, MUTATING, GOVERNANCE  -------------------

    function setPendingPermissionless(bool _pendingPermissionless) external {
        require(_isGovernanceOrDelegate(), "PGD");
        pendingPermissionless = _pendingPermissionless;
    }

    function commitPendingPermissionless() external {
        require(_isGovernanceOrDelegate(), "PGD");
        permissionless = pendingPermissionless;
        pendingPermissionless = false;
    }

    function setPendingMaxTokensPerVault(uint256 _pendingMaxTokensPerVault) external {
        require(_isGovernanceOrDelegate(), "PGD");
        pendingMaxTokensPerVault = _pendingMaxTokensPerVault;
    }

    function commitPendingMaxTokensPerVault() external {
        require(_isGovernanceOrDelegate(), "PGD");
        maxTokensPerVault = pendingMaxTokensPerVault;
        pendingMaxTokensPerVault = 0;
    }
}
