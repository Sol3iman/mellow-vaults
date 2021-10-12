// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/external/univ3/INonfungiblePositionManager.sol";
import "./interfaces/IVaultFactory.sol";
import "./VaultManager.sol";
import "./UniV3Vault.sol";

contract UniV3VaultFactory is IVaultFactory {
    function deployVault(
        address[] calldata tokens,
        address strategyTreasury,
        bytes calldata options
    ) external override returns (address) {
        uint256 fee;
        assembly {
            fee := calldataload(options.offset)
        }
        UniV3Vault vault = new UniV3Vault(tokens, IVaultManager(msg.sender), strategyTreasury, uint24(fee));
        return address(vault);
    }
}
