//SPDX-License-Identifier:MIT
pragma solidity >= 0.8.0;
contract MultiSwap {

constructor() {
 	IERC20(BNT).safeApprove(address(sushiRouter), type(uint256).max);
  	IERC20(INJ).safeApprove(address(uniswapRouter), type(uint256).max);
}

	IBancorNetwork private constant bancorNetwork = IBancorNetwork(0xb3fa5DcF7506D146485856439eb5e401E0796B5D);
	address private constant BANCOR_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address private constant BANCOR_ETHBNT_POOL = 0x1aCE5DD13Ba14CA42695A905526f2ec366720b13;
	address private constant BNT = 0xF35cCfbcE1228014F66809EDaFCDB836BFE388f5;

	function _tradeOnBancor(uint256 amountIn, uint256 amountOutMin) private {
  		bancorNetwork.convertByPath{value: msg.value}(_getPathForBancor(), amountIn, amountOutMin, address(0), address(0), 0);
	}
  
	function _getPathForBancor() private pure returns (address[] memory) {
    	address[] memory path = new address[](3);
    	path[0] = BANCOR_ETH_ADDRESS;
    	path[1] = BANCOR_ETHBNT_POOL;
    	path[2] = BNT;
    
    	return path;
	}

	IUniswapV2Router02 private constant sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
	address private constant INJ = 0x9108Ab1bb7D054a3C1Cd62329668536f925397e5;

	function _tradeOnSushi(uint256 amountIn, uint256 amountOutMin, uint256 deadline) private {
    	address recipient = address(this);
      
    	sushiRouter.swapExactTokensForTokens(
        	amountIn,
        	amountOutMin,
        	_getPathForSushiSwap(),
        	recipient,
        	deadline
    	);
	}

	function _getPathForSushiSwap() private pure returns (address[] memory) {
    	address[] memory path = new address[](2);
    	path[0] = BNT;
    	path[1] = INJ;
    
    	return path;
	}


	IUniswapRouter private constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	address private constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;

	function _tradeOnUniswap(uint256 amountIn, uint256 amountOutMin, uint256 deadline) private {
    	address tokenIn = INJ;
    	address tokenOut = DAI;
    	uint24 fee = 3000;
   		address recipient = msg.sender;
    	uint160 sqrtPriceLimitX96 = 0;
    
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
        tokenIn,
        tokenOut,
        fee,
        recipient,
        deadline,
        amountIn,
        amountOutMin,
        sqrtPriceLimitX96
    );
    
    uniswapRouter.exactInputSingle(params);
    uniswapRouter.refundETH();
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    	require(success, "refund failed");
	}

	function multiSwap(uint256 deadline, uint256 amountOutMinUniswap) external payable {
    	uint256 amountOutMinBancor = 1;
    	uint256 amountOutMinSushiSwap = 1;

    	_tradeOnBancor(msg.value, amountOutMinBancor);
   		_tradeOnSushi(IERC20(BNT).balanceOf(address(this)), amountOutMinSushiSwap, deadline);
    	_tradeOnUniswap(IERC20(INJ).balanceOf(address(this)), amountOutMinUniswap, deadline);
	}


	// meant to be called as view function
	function multiSwapPreview() external payable returns(uint256) {
    	uint256 daiBalanceUserBeforeTrade = IERC20(DAI).balanceOf(msg.sender);
    	uint256 deadline = block.timestamp + 300;
    
   		uint256 amountOutMinBancor = 1;
    	uint256 amountOutMinSushiSwap = 1;
    	uint256 amountOutMinUniswap = 1;
    
    	_tradeOnBancor(msg.value, amountOutMinBancor);
    	_tradeOnSushi(IERC20(BNT).balanceOf(address(this)), amountOutMinSushiSwap, deadline);
    	_tradeOnUniswap(IERC20(INJ).balanceOf(address(this)), amountOutMinUniswap, deadline);
    
    	uint256 daiBalanceUserAfterTrade = IERC20(DAI).balanceOf(msg.sender);
    	return daiBalanceUserAfterTrade - daiBalanceUserBeforeTrade;
	}	

	//const estimatedDAI = (await myContract.multiSwapPreview({ value: ethAmount }).call())[0];
	//const amountOutMinUniswap = estimatedDAI * 0.96;


}
