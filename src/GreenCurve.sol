// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract GreenCurve {
    event GreenCurveInitialized(address token, uint256 tradeFee, address feeReceiver, uint256 maxSupply);
    event TokenBuy(uint256 ethIn, uint256 tokenOut, uint256 fee, address buyer);
    event TokenSell(uint256 tokenIn, uint256 ethOut, uint256 fee, address seller);
    // note: update the pool address at the time of deployment
    IUniswapV2Pair public constant WETH_USDC_PAIR = IUniswapV2Pair(0x61c31F973fb0255ebb717396F624766d36c64784);
    uint256 public constant V_ETH_BALANCE = 1.5 ether;
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public greenErc20Balance;
    uint256 public ethBalance;
    uint256 public tradeFee;
    address public feeReceiver;

    bool public saleActive;

    IUniswapV2Router02 public uniswapRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    error GreenCurveInactive();
    error PurchaseExceedsSupply();
    error NotEnoughETH();
    error FeeTransferFailed();
    error MaxSupplyCannotBeLowerThanSuppliedTokens();

    function initialize(
        address _tokenAddress,
        address _feeReceiver,
        uint256 _tradeFee,
        uint256 _maxSupply,
        uint256 _marketCapThreshold,
        address _uniswapRouter
    ) external payable {
        // sale is activate once the exchange is initialized
        saleActive = true;

        // register token
        token = IERC20(_tokenAddress);

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        tradeFee = _tradeFee;
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold;

        // fee receiver
        feeReceiver = _feeReceiver;
        greenErc20Balance = token.balanceOf(address(this));

        if (msg.value != 0) {
            _buy(msg.value, msg.sender);
        }

        // register initial balance
        // assume whatever is in the exchange was meant to be sent to contract
        ethBalance = address(this).balance;

        if(maxSupply < greenErc20Balance) revert MaxSupplyCannotBeLowerThanSuppliedTokens();

        emit GreenCurveInitialized(_tokenAddress, _tradeFee, _feeReceiver, _maxSupply);
    }

    function buyTokens() public payable {
        if (!saleActive) {
            revert GreenCurveInactive();
        }
        _buy(msg.value, msg.sender);
    }

    function sellTokens(uint256 tokenAmount) public {
        if (!saleActive) {
            revert GreenCurveInactive();
        }
        _sell(tokenAmount, msg.sender);
    }

    function marketCap() external view returns (uint256) {
        return _calculateMarketCap();
    }

    function getTokenPriceinETH() external view returns (uint256 ethAmount) {
        return _getSpotPrice();
    }

    function endBonding() internal {
        // deactivate sale
        saleActive = false;

        // calculate total liquidity
        uint256 totalTokens = greenErc20Balance;
        uint256 totalEth = ethBalance;

        // Approve router to spend tokens
        token.approve(address(uniswapRouter), totalTokens);

        // Add liquidity to Uniswap
        uniswapRouter.addLiquidityETH{value: totalEth}(
            address(token),
            totalTokens,
            0, // slippage is okay
            0, // slippage is okay
            address(0xdead),
            block.timestamp
        );

        emit BondingEnded(totalEth, totalTokens);
    }

    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee) internal pure returns (uint256, uint256) {
        require(amountIn > 0, "Amount in must be greater than 0");
        uint256 amountInWithFee = amountIn * (1000 - _tradeFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return (numerator / denominator, (amountIn * _tradeFee) / 1000);
    }

    function calculatePurchaseTokenOut(uint256 amountETHIn) public view returns (uint256, uint256 ) {
        uint256 tokenSupply = greenErc20Balance;
        return getAmountOutWithFee(amountETHIn, ethBalance + V_ETH_BALANCE, tokenSupply, tradeFee);
    }

    function calculateSaleTokenOut(uint256 amountTokenIn) public view returns (uint256, uint256 ) {
        uint256 tokenSupply = greenErc20Balance;
        return getAmountOutWithFee(amountTokenIn, tokenSupply, ethBalance + V_ETH_BALANCE, tradeFee);
    }

    function _buy(uint256 ethAmount, address receiver) internal {
        // calculate tokens to mint and fee in eth
        (uint256 tokensToMint, uint256 feeInEth) = calculatePurchaseTokenOut(ethAmount);
        if (tokensToMint > greenErc20Balance) {
            revert PurchaseExceedsSupply();
        }
        if(feeInEth > 0) {
            (bool success, ) = feeReceiver.call{value: feeInEth}("");
            if(!success) {
                revert FeeTransferFailed();
            }
        }
        greenErc20Balance -= tokensToMint;
        ethBalance += (ethAmount - feeInEth);
        token.transfer(receiver, tokensToMint);

        emit TokenBuy(ethAmount, tokensToMint, feeInEth, receiver);
        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _sell(uint256 tokenAmount,address receiver) internal {
        // calculate eth to refund and fee in token
        (uint256 ethToReturn, uint256 feeInToken) = calculateSaleTokenOut(tokenAmount);
        ethBalance -= ethToReturn;
        greenErc20Balance += (tokenAmount - feeInToken);
        require(token.transferFrom(receiver, address(this), tokenAmount), "Transfer failed");
        if(feeInToken > 0) {
            token.transfer(feeReceiver, feeInToken);
        }
        if (address(this).balance < ethToReturn) {
            revert NotEnoughETH();
        }

        payable(receiver).transfer(ethToReturn);
        emit TokenSell(tokenAmount, ethToReturn, feeInToken, receiver);
    }

    function _calculateMarketCap() internal view returns (uint256) {
        uint256 spotPrice = _getSpotPrice();
        uint256 wethPrice = _getWETHPrice();
        if(spotPrice > 10**45) {
            return maxSupply * (((spotPrice / 10**18) * wethPrice) / 10 ** 18);
        }
        return maxSupply * ((spotPrice * wethPrice) / 10**18) / 10 ** 18;
    }

    receive() external payable {
        buyTokens();
    }

    function _getSpotPrice() internal view returns(uint256) {
        return (ethBalance + 1.5 ether) * 10 ** 18 / greenErc20Balance;
    }

    function _getWETHPrice() internal view returns(uint256) {
        (uint256 _WETH_RESERVE, uint256 _USDC_RESERVE,) = WETH_USDC_PAIR.getReserves();
        uint256 price = (_USDC_RESERVE * 10 **12 * 10 ** 18) / _WETH_RESERVE;
        return price;
    }
}
