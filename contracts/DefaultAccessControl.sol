// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IDefaultAccessControl.sol";

/// @notice This is a default access control with 2 roles -
/// ADMIN and ADMIN_DELEGATE
contract DefaultAccessControl is IDefaultAccessControl, AccessControlEnumerable {
    bytes32 internal constant ADMIN_ROLE = keccak256("admin");
    bytes32 internal constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");

    constructor(address admin) {
        require(admin != address(0), "ZADM");
        _setupRole(ADMIN_ROLE, admin);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
    }

    function isAdmin() public view returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender) || hasRole(ADMIN_DELEGATE_ROLE, msg.sender);
    }
}