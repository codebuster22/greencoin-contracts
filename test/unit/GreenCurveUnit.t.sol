pragma solidity 0.8.24;

import {GreenCurveBase, GreenCurve} from "../base/GreenCurve.base.sol";
import {console} from "forge-std/console.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {console} from "forge-std/console.sol";

// do fork testing
// forge test --mc GreenCurveUnit_Fork --fork-url https://base-rpc.publicnode.com
contract GreenCurveUnit_Fork is GreenCurveBase {
    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee) internal pure returns (uint256, uint256) {
        require(amountIn > 0, "Amount in must be greater than 0");
        uint256 amountInWithFee = amountIn * (1000 - _tradeFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return (numerator / denominator, (amountIn * _tradeFee) / 1000);
    }

    function test_revert_initializeMaxSupplyLowerThanSuppliedTokens() public {
        GreenCurve curveImpl = new GreenCurve();
        curve = GreenCurve(payable(Clones.clone(address(curveImpl))));
        erc20.mint(address(curve), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        vm.expectRevert(GreenCurve.MaxSupplyCannotBeLowerThanSuppliedTokens.selector);
        curve.initialize(address(erc20), feeReceiver, tradeFee, platformFee, marketCapThreshold, router);
    }

    function test_initialize() public {
        GreenCurve curveImpl = new GreenCurve();
        curve = GreenCurve(payable(Clones.clone(address(curveImpl))));
        erc20.mint(address(curve), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        curve.initialize(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
        assertEq(address(curve.token()), address(erc20));
        assertEq(curve.maxSupply(), maxSupply);
        assertEq(curve.marketCapThreshold(), marketCapThreshold);
        assertEq(curve.greenErc20Balance(), totalToBeSold);
        assertEq(curve.ethBalance(), 0);
        assertEq(curve.tradeFee(), tradeFee);
        assertEq(curve.feeReceiver(), feeReceiver);
        assertEq(curve.saleActive(), true);
        assertEq(address(curve.uniswapRouter()), router);
    }

    function test_initializeWithInitialBuy() public {
        GreenCurve curveImpl = new GreenCurve();
        curve = GreenCurve(payable(Clones.clone(address(curveImpl))));
        erc20.mint(address(curve), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        (uint256 tokenAmountOut, uint256 fee) = getAmountOutWithFee(1e17,1.5 ether, totalToBeSold, tradeFee);
        curve.initialize{value: 1e17}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
        assertEq(address(curve.token()), address(erc20));
        assertEq(curve.maxSupply(), maxSupply);
        assertEq(curve.marketCapThreshold(), marketCapThreshold);
        assertEq(curve.greenErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(curve.ethBalance(), 1e17 - fee);
        assertEq(erc20.balanceOf(address(this)), tokenAmountOut);
        assertEq(feeReceiver.balance, fee);
        assertEq(curve.tradeFee(), tradeFee);
        assertEq(curve.feeReceiver(), feeReceiver);
        assertEq(curve.saleActive(), true);
        assertEq(address(curve.uniswapRouter()), router);
    }
    
    function test_initializeWithInitialBuyWithLowEth() public {
        GreenCurve curveImpl = new GreenCurve();
        curve = GreenCurve(payable(Clones.clone(address(curveImpl))));
        erc20.mint(address(curve), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        (uint256 tokenAmountOut, uint256 fee) = getAmountOutWithFee(1e10,1.5 ether, totalToBeSold, tradeFee);
        curve.initialize{value: 1e10}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
        assertEq(address(curve.token()), address(erc20));
        assertEq(curve.maxSupply(), maxSupply);
        assertEq(curve.marketCapThreshold(), marketCapThreshold);
        assertEq(curve.greenErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(curve.ethBalance(), 1e10 - fee);
        assertEq(erc20.balanceOf(address(this)), tokenAmountOut);
        assertEq(feeReceiver.balance, fee);
        assertEq(curve.tradeFee(), tradeFee);
        assertEq(curve.feeReceiver(), feeReceiver);
        assertEq(curve.saleActive(), true);
        assertEq(address(curve.uniswapRouter()), router);
    }

    function test_marketCap() public {
        assertLe(curve.marketCap(), 6000 ether);
    }

    function test_tokenPriceinETH() public {
        assertEq(curve.getTokenPriceinETH(), (1.5 ether) * 10 ** 18 / totalToBeSold);
    }

    function test_buy() public {
        curve.buyTokens{value: 1 ether}();
    }

    function test_sell() public {
        curve.buyTokens{value: 1 ether}();
        erc20.approve(address(curve), erc20.balanceOf(address(this)));
        curve.sellTokens(erc20.balanceOf(address(this)));
    }

    function test_buyToCreatingLiquidityPool() public {
        uint256 currentMarketCap;
        uint256 beforeBalance = 0;
        while (currentMarketCap < marketCapThreshold) {
            curve.buyTokens{value: 1 ether}();
            currentMarketCap = curve.marketCap();
            console.log("market cap");
            console.log(currentMarketCap);
            beforeBalance = erc20.balanceOf(address(this));
        }

        // sell
        erc20.approve(address(curve), beforeBalance);
        vm.expectRevert(GreenCurve.GreenCurveInactive.selector);
        curve.sellTokens(beforeBalance);

        // cannot buy after pool is created
        vm.expectRevert(GreenCurve.GreenCurveInactive.selector);
        curve.buyTokens{value: 1 ether}();
    }

    function test_buy_fuzz(uint256 _ethAmount) public {
        // no one in right mind will invest more than 10^45 ETH.
        // the whole world GDP is at 29 Billion ETH, which is 1.9 * 10 ^ 10.
        _ethAmount = bound(_ethAmount, 1, type(uint112).max);
        vm.deal(address(this), _ethAmount);
        curve.buyTokens{value: _ethAmount}();
    }

    function test_buy_MaxValue() public {
        vm.deal(address(this), type(uint112).max);
        curve.buyTokens{value: type(uint112).max}();
    }

    function test_sell_maxValue() public {
        vm.deal(address(this), type(uint112).max);
        curve.buyTokens{value: type(uint112).max}();
        uint256 balance = erc20.balanceOf(address(this));
        vm.expectRevert(GreenCurve.GreenCurveInactive.selector);
        curve.sellTokens(balance);
    }

    function test_buy_minValue() public {
        assertEq(erc20.balanceOf(address(this)), 0);
        curve.buyTokens{value: 1}();
        assertNotEq(erc20.balanceOf(address(this)), 0);
    }

    function test_sell_minValue() public {
        curve.buyTokens{value: 1}();

        assertNotEq(erc20.balanceOf(address(this)), 0);
        erc20.approve(address(curve), type(uint256).max);
        curve.sellTokens(erc20.balanceOf(address(this)));
        assertEq(erc20.balanceOf(address(this)), 0);
    }

    function test_sell_fuzz(uint256 _ethAmount,uint256 _tokenSellAmount) public {
        _ethAmount = bound(_ethAmount, 1, type(uint112).max);
        _tokenSellAmount = bound(_tokenSellAmount, 1, type(uint112).max);
        vm.deal(address(this), _ethAmount);
        curve.buyTokens{value: _ethAmount}();

        // sell
        erc20.approve(address(curve), _tokenSellAmount);
        if(curve.marketCap() > marketCapThreshold) {
            vm.expectRevert(GreenCurve.GreenCurveInactive.selector);
            curve.sellTokens(_tokenSellAmount);
        } else {
            if(_tokenSellAmount > erc20.balanceOf(address(this))) {
                vm.expectRevert();
            }
            curve.sellTokens(_tokenSellAmount);
        }
    }

    receive() external payable {}
}
