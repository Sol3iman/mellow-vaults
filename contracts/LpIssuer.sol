// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/Common.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IProtocolGovernance.sol";
import "./DefaultAccessControl.sol";
import "./LpIssuerGovernance.sol";

contract LpIssuer is ERC20, DefaultAccessControl, LpIssuerGovernance {
    using SafeERC20 for IERC20;

    GovernanceParams private _governanceParams;
    uint256 private _limitPerAddress;
    address[] private _tokens;

    /// @notice Creates a new contract
    /// @param name_ Name of the ERC-721 token
    /// @param symbol_ Symbol of the ERC-721 token
    /// @param gatewayVault Reference to Gateway Vault
    /// @param limitPerAddress Max amount of LP token per address
    /// @param admin Admin of the Issuer
    constructor(
        string memory name_,
        string memory symbol_,
        IVault gatewayVault,
        IProtocolGovernance protocolGovernance,
        uint256 limitPerAddress,
        address admin,
        address[] memory tokens
    )
        ERC20(name_, symbol_)
        DefaultAccessControl(admin)
        LpIssuerGovernance(GovernanceParams({protocolGovernance: protocolGovernance, gatewayVault: gatewayVault}))
    {
        _governanceParams = GovernanceParams({gatewayVault: gatewayVault, protocolGovernance: protocolGovernance});
        _limitPerAddress = limitPerAddress;
        _tokens = tokens;
    }

    /// @notice Set new LP token limit per address
    /// @param newLimitPerAddress - new value for limit per address
    function setLimit(uint256 newLimitPerAddress) external {
        require(isAdmin(msg.sender), "ADM");
        _limitPerAddress = newLimitPerAddress;
    }

    /// @notice Deposit tokens into LpIssuer
    /// @param tokenAmounts Amounts of tokens to push
    /// @param optimized Whether to use gas optimization or not. When `true` the call can have some gas cost reduction
    /// but the operation is not guaranteed to succeed. When `false` the gas cost could be higher but the operation is guaranteed to succeed.
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param.
    function deposit(
        uint256[] calldata tokenAmounts,
        bool optimized,
        bytes memory options
    ) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(governanceParams().gatewayVault), tokenAmounts[i]);
        }
        uint256[] memory tvl = governanceParams().gatewayVault.tvl();
        uint256[] memory actualTokenAmounts = governanceParams().gatewayVault.push(
            _tokens,
            tokenAmounts,
            optimized,
            options
        );
        uint256 amountToMint;
        if (totalSupply() == 0) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                // TODO: check if there could be smth better
                if (actualTokenAmounts[i] > amountToMint) {
                    amountToMint = actualTokenAmounts[i]; // some number correlated to invested assets volume
                }
            }
        }
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (tvl[i] > 0) {
                uint256 newMint = (actualTokenAmounts[i] * totalSupply()) / tvl[i];
                // TODO: check this algo. The assumption is that everything is rounded down.
                // So that max token has the least error. Think about the case when one token is dust.
                if (newMint > amountToMint) {
                    amountToMint = newMint;
                }
            }
            if (tokenAmounts[i] > actualTokenAmounts[i]) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, tokenAmounts[i] - actualTokenAmounts[i]);
            }
        }
        require(amountToMint + balanceOf(msg.sender) <= _limitPerAddress, "LPA");
        if (amountToMint > 0) {
            _mint(msg.sender, amountToMint);
        }

        emit Deposit(msg.sender, _tokens, actualTokenAmounts, amountToMint);
    }

    /// @notice Withdraw tokens from LpIssuer
    /// @param to Address to withdraw to
    /// @param lpTokenAmount Amount of token to withdraw
    /// @param optimized Whether to use gas optimization or not. When `true` the call can have some gas cost reduction
    /// but the operation is not guaranteed to succeed. When `false` the gas cost could be higher but the operation is guaranteed to succeed.
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param.
    function withdraw(
        address to,
        uint256 lpTokenAmount,
        bool optimized,
        bytes memory options
    ) external {
        require(totalSupply() > 0, "TS");
        uint256[] memory tokenAmounts = new uint256[](_tokens.length);
        uint256[] memory tvl = governanceParams().gatewayVault.tvl();
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenAmounts[i] = (lpTokenAmount * tvl[i]) / totalSupply();
        }
        uint256[] memory actualTokenAmounts = governanceParams().gatewayVault.pull(
            address(this),
            _tokens,
            tokenAmounts,
            optimized,
            options
        );
        uint256 protocolExitFee = governanceParams().protocolGovernance.protocolExitFee();
        address protocolTreasury = governanceParams().protocolGovernance.protocolTreasury();
        uint256[] memory exitFees = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (actualTokenAmounts[i] == 0) {
                continue;
            }
            exitFees[i] = (actualTokenAmounts[i] * protocolExitFee) / Common.DENOMINATOR;
            actualTokenAmounts[i] -= exitFees[i];
            IERC20(_tokens[i]).safeTransfer(protocolTreasury, exitFees[i]);
            IERC20(_tokens[i]).safeTransfer(to, actualTokenAmounts[i]);
        }
        _burn(msg.sender, lpTokenAmount);
        emit Withdraw(msg.sender, _tokens, actualTokenAmounts, lpTokenAmount);
        emit ExitFeeCollected(msg.sender, protocolTreasury, _tokens, exitFees);
    }

    event Deposit(address indexed from, address[] tokens, uint256[] actualTokenAmounts, uint256 lpTokenMinted);
    event Withdraw(address indexed from, address[] tokens, uint256[] actualTokenAmounts, uint256 lpTokenBurned);
    event ExitFeeCollected(address indexed from, address to, address[] tokens, uint256[] amounts);
}
