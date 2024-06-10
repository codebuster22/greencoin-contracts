// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract GreenCurve {
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public greenErc20Balance;
    uint256 public ethBalance;

    bool public bondingActive = false;

    IUniswapV2Router02 public uniswapRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    function initialize(address _tokenAddress, uint256 _maxSupply, uint256 _marketCapThreshold, address _uniswapRouter) external {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        token = IERC20(_tokenAddress);
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold; // example threshold 100k threshold
        greenErc20Balance = token.balanceOf(address(this));
        ethBalance = address(this).balance;
        bondingActive = true;
    }

    function buyTokens() public payable {
        require(bondingActive, "Bonding not active");
        // Example bonding curve pricing logic
        uint256 tokensToMint = msg.value; // simplistic example
        require(tokensToMint <= greenErc20Balance, "Not enough tokens");

        greenErc20Balance -= tokensToMint;
        ethBalance += msg.value;
        token.transfer(msg.sender, tokensToMint);

        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _calculateMarketCap() internal view returns(uint256) {
        return ethBalance;
    }

    function sellTokens(uint256 tokenAmount) public {
        require(bondingActive, "Bonding not active");

        uint256 ethToReturn = tokenAmount; // simplistic example
        ethBalance -=  ethToReturn;
        greenErc20Balance += tokenAmount;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
        require(address(this).balance >= ethToReturn, "Not enough ETH");

        payable(msg.sender).transfer(ethToReturn);
    }

    function endBonding() internal {
        bondingActive = false;
        uint256 totalTokens = token.balanceOf(address(this));
        uint256 totalEth = address(this).balance;

        // Approve Uniswap router to spend tokens
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

    receive() external payable {
        buyTokens();
    }
}
