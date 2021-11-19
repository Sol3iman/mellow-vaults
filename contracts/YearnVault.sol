// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/external/aave/ILendingPool.sol";
import "./interfaces/external/yearn/IYearnVault.sol";
import "./interfaces/IYearnVaultGovernance.sol";
import "./Vault.sol";

/// @notice Vault that interfaces Yearn protocol in the integration layer.
contract YearnVault is Vault {
    address[] private _yTokens;

    /// @notice Creates a new contract.
    /// @param vaultGovernance_ Reference to VaultGovernance for this vault
    /// @param vaultTokens_ ERC20 tokens under Vault management
    constructor(IVaultGovernance vaultGovernance_, address[] memory vaultTokens_)
        Vault(vaultGovernance_, vaultTokens_)
    {
        _yTokens = new address[](vaultTokens_.length);
        for (uint256 i = 0; i < _vaultTokens.length; i++) {
            _yTokens[i] = _yearnVaultRegistry().latestVault(_vaultTokens[i]);
            require(_yTokens[i] != address(0), "VDE");
        }
    }

    /// @inheritdoc Vault
    function tvl() public view override returns (uint256[] memory tokenAmounts) {
        address[] memory tokens = _vaultTokens;
        tokenAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < _yTokens.length; i++) {
            IYearnVault yToken = IYearnVault(_yTokens[i]);
            /// TODO: Verify it's not subject to manipulation like in Cream hack
            tokenAmounts[i] = (yToken.balanceOf(address(this)) * yToken.pricePerShare()) / (10**yToken.decimals());
        }
    }

    function _push(uint256[] memory tokenAmounts, bytes memory)
        internal
        override
        returns (uint256[] memory actualTokenAmounts)
    {
        address[] memory tokens = _vaultTokens;
        for (uint256 i = 0; i < _yTokens.length; i++) {
            if (tokenAmounts[i] == 0) {
                continue;
            }

            address token = tokens[i];
            _allowTokenIfNecessary(token);
            IYearnVault yToken = IYearnVault(_yTokens[i]);
            yToken.deposit(tokenAmounts[i], address(this));
        }
        actualTokenAmounts = tokenAmounts;
    }

    function _pull(
        address to,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) internal override returns (uint256[] memory actualTokenAmounts) {
        address[] memory tokens = _vaultTokens;
        uint256 maxLoss = abi.decode(options, (uint256));
        for (uint256 i = 0; i < _yTokens.length; i++) {
            if (tokenAmounts[i] == 0) {
                continue;
            }

            address token = tokens[i];
            _allowTokenIfNecessary(token);
            IYearnVault yToken = IYearnVault(_yTokens[i]);
            uint256 yTokenAmount = (tokenAmounts[i] / yToken.pricePerShare()) * (10**yToken.decimals());
            require(yTokenAmount < yToken.balanceOf(address(this)), "INSY");
            yToken.withdraw(yTokenAmount, to, maxLoss);
            (tokenAmounts[i], address(this));
        }
        actualTokenAmounts = tokenAmounts;
    }

    function _allowTokenIfNecessary(address token) internal {
        if (IERC20(token).allowance(address(_yearnVaultRegistry()), address(this)) < type(uint256).max / 2) {
            IERC20(token).approve(address(_yearnVaultRegistry()), type(uint256).max);
        }
    }

    function _yearnVaultRegistry() internal view returns (IYearnVaultRegistry) {
        return IYearnVaultGovernance(address(_vaultGovernance)).delayedProtocolParams().yearnVaultRegistry;
    }
}
