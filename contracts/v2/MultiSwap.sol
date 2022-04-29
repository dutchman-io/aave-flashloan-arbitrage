//SPDX-License-Identifier:MIT
pragma solidity ^ 0.8.0;
contract MultiSwap {
	constructor() {
  	

		IERC20(BNT).safeApprove(address(sushiRouter), type(uint256).max);
  		IERC20(INJ).safeApprove(address(uniswapRouter), type(uint256).max);
	}

//Now we have everything we need. Let's create a multiSwap function.

	function multiSwap(uint256 deadline, uint256 amountOutMinUniswap) external payable {
    	uint256 amountOutMinBancor = 1;
    	uint256 amountOutMinSushiSwap = 1;

    	_tradeOnBancor(msg.value, amountOutMinBancor);
    	_tradeOnSushi(IERC20(BNT).balanceOf(address(this)), amountOutMinSushiSwap, deadline);
    	_tradeOnUniswap(IERC20(INJ).balanceOf(address(this)), amountOutMinUniswap, deadline);
	}
}
