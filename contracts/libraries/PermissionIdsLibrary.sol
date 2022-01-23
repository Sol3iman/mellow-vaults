//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Stores permission ids for addresses
library PermissionIdsLibrary {
    // The msg.sender is allowed to register vault
    uint8 constant REGISTER_VAULT = 1;
    // The msg.sender is allowed to create vaults
    uint8 constant CREATE_VAULT = 2;
    // The token is allowed to be transfered by vault
    uint8 constant ERC20_TRANSFER = 3;
    // The token is allowed to be added to vault
    uint8 constant ERC20_VAULT_TOKEN = 4;
    // The pool is allowed to be used for swap
    uint8 constant ERC20_SWAP = 5;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by any strategy
    uint8 constant ERC20_APPROVE = 6;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by trusted strategy
    uint8 constant ERC20_APPROVE_RESTRICTED = 7;
    // Strategy allowed using restricted API
    uint8 constant TRUSTED_STRATEGY = 8;
}
