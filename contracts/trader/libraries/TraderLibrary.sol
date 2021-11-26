// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/ITrader.sol";

library TraderLibrary {
    string constant MASTER_REQUIRED_EXCEPTION = "MS";
    string constant PROTOCOL_ADMIN_REQUIRED_EXCEPTION = "PA";
    string constant TRADER_ALREADY_REGISTERED_EXCEPTION = "TE";
    string constant TRADER_NOT_FOUND_EXCEPTION = "UT";
    string constant TRADE_FAILED_EXCEPTION = "TF";

    bytes4 constant TRADER_INTERFACE_ID = (
        ITrader.masterTrader.selector ^
        ITrader.swapExactInputMultihop.selector ^
        ITrader.swapExactOutputMultihop.selector ^
        ITrader.swapExactInputSingle.selector ^
        ITrader.swapExactOutputSingle.selector
    );
}
