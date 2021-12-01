// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IProtocolGovernance.sol";
import "./interfaces/ITrader.sol";
import "./interfaces/IChiefTrader.sol";
import "./libraries/ExceptionsLibrary.sol";

contract ChiefTrader is ERC165, IChiefTrader, ITrader {
    address public immutable protocolGovernance;
    address[] internal _traders;
    mapping(address => bool) public addedTraders;

    constructor(address _protocolGovernance) {
        protocolGovernance = _protocolGovernance;
    }

    /// @inheritdoc IChiefTrader
    function tradersCount() external view returns (uint256) {
        return _traders.length;
    }

    function getTrader(uint256 _index) external view returns (address) {
        return _traders[_index];
    }

    function traders() external view returns (address[] memory) {
        return _traders;
    }

    /// @inheritdoc IChiefTrader
    function addTrader(address traderAddress) external {
        _requireProtocolAdmin();
        require(traderAddress != address(this), ExceptionsLibrary.RECURRENCE_EXCEPTION);
        require(!addedTraders[traderAddress], ExceptionsLibrary.TRADER_ALREADY_REGISTERED_EXCEPTION);
        require(ERC165(traderAddress).supportsInterface(type(ITrader).interfaceId));
        require(!ERC165(traderAddress).supportsInterface(type(IChiefTrader).interfaceId));
        _traders.push(traderAddress);
        addedTraders[traderAddress] = true;
        emit AddedTrader(_traders.length - 1, traderAddress);
    }

    /// @inheritdoc ITrader
    function swapExactInput(
        uint256 traderId,
        uint256 amount,
        address,
        PathItem[] calldata path,
        bytes calldata options
    ) external returns (uint256) {
        require(traderId < _traders.length, ExceptionsLibrary.TRADER_NOT_FOUND_EXCEPTION);
        address traderAddress = _traders[traderId];
        address recipient = msg.sender;
        return ITrader(traderAddress).swapExactInput(0, amount, recipient, path, options);
    }

    /// @inheritdoc ITrader
    function swapExactOutput(
        uint256 traderId,
        uint256 amount,
        address,
        PathItem[] calldata path,
        bytes calldata options
    ) external returns (uint256) {
        require(traderId < _traders.length, ExceptionsLibrary.TRADER_NOT_FOUND_EXCEPTION);
        address traderAddress = _traders[traderId];
        address recipient = msg.sender;
        return ITrader(traderAddress).swapExactOutput(0, amount, recipient, path, options);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return (interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ITrader).interfaceId ||
            interfaceId == type(IChiefTrader).interfaceId);
    }

    function _requireProtocolAdmin() internal view {
        require(
            IProtocolGovernance(protocolGovernance).isAdmin(msg.sender),
            ExceptionsLibrary.PROTOCOL_ADMIN_REQUIRED_EXCEPTION
        );
    }

    event AddedTrader(uint256 indexed traderId, address traderAddress);
}