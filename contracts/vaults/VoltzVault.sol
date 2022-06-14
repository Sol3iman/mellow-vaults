// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/external/voltz/IVoltzFactory.sol"; //WIP
import "../interfaces/vaults/IVoltzVaultGovernance.sol";
import "../interfaces/vaults/IVoltzVault.sol";
import "../libraries/ExceptionsLibrary.sol";
import "./IntegrationVault.sol";


contract VoltzVault is IVoltzVault, IntegrationVault {
    using SafeERC20 for IERC20;

    /// @inheritdoc IMellowVault
    IERC20RootVault public vault;

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IVault
    function tvl() public view override returns(
        uint256[] memory minTokenAmounts, 
        uint256[] memory maxTokenAmounts) {
            IERC20RootVault vault_ = vault;
            uint256 balance = vault_.balanceOf(address(this));
            uint256 supply = vault_.totalSupply();
            (minTokenAmounts, maxTokenAmounts) = vault_.tvl();
            for (uint256 i = 0; i < minTokenAmounts.length; i++) {
                minTokenAmounts[i] = FullMath.mulDiv(balance, minTokenAmounts[i], supply);
                maxTokenAmounts[i] = FullMath.mulDiv(balance, maxTokenAmounts[i], supply);
            /// WIP
            }
        }
    
    // -------------------  EXTERNAL, MUTATING  -------------------

    // @inheritdoc IVoltzVault
    function initialize(
        uint256 nft_,
        addres[] memory vaultTokens_,
        IERC20RootVault vaultTokens_ //this might be needed if Voltz doesn't have a token
        ) external {
            _initialize(vaultTokens_, nft_);
            address[] memory vTokens = vault_.vaultTokens();
            for (uint256 i = 0; i < vaultTokens_.length; i++) {
                require(vTokens[i] == vaultTokens_[i], ExceptionsLibrary.INVALID_TOKEN);
            }
            IVaultRegistry registry = _vaultGovernance.internalParams().registry;
            require(registry.nftForVault(address(vault)) > 0, ExceptionsLibrary.INVALID_INTERFACE);
            vault = vault_;
            /// WIP, the above I think creates vTokens for our Voltz vault which are tracked by the the registry
        }

    // -------------------  INTERNAL, VIEW  -----------------------
    function _isReclaimForbidden(address token) 
        internal
        view 
        override
        returns (bool) {
            address[] memory vTokens = vault.vaultTokens();
            for ( uint256 i = 0; i < vTokens.length; ++i) {
                if (vTokens[i] == token) {
                    return true;
                }
            }
            return false;
            /// WIP
        }   

    // -------------------  INTERNAL, MUTATING  -------------------
    function _push(uint256[] memory tokenAmounts, bytes memory options)
        internal 
        override
        returns (uint256[] memory actualTokenAmounts) {
            ///WIP

    }

    function _pull(
        address to,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) internal override returns (uint256[] memory actualTokenAmounts) {
        ///WIP
    }
























}