// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/external/univ2/IUniswapV2Pair.sol";
import "../interfaces/external/univ2/IUniswapV2Factory.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IUniV2Oracle.sol";
import "../libraries/external/FullMath.sol";
import "../libraries/external/TickMath.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../libraries/CommonLibrary.sol";
import "../DefaultAccessControl.sol";

contract UniV2Oracle is IUniV2Oracle {
    IUniswapV2Factory public immutable factory;

    constructor(IUniswapV2Factory factory_) {
        factory = factory_;
    }

    function spotPrice(address token0, address token1) external view returns (uint256 spotPriceX96) {
        require(token1 > token0, ExceptionsLibrary.SORTED_AND_UNIQUE);
        address pool = factory.getPair(token0, token1);
        require(pool != address(0), ExceptionsLibrary.UNISWAP_POOL_NOT_FOUND);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        spotPriceX96 = FullMath.mulDiv(reserve1, CommonLibrary.Q96, reserve0);
    }
}