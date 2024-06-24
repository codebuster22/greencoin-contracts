pragma solidity 0.8.24;

import {GreenLaunchpadBase} from "../base/GreenLaunchpad.base.sol";
import {GreenLaunchpad} from "../../src/GreenLaunchpad.sol";
import {GreenERC20} from "../../src/GreenERC20.sol";
import {GreenCurve} from "../../src/GreenCurve.sol";

contract GreenLaunchpadUnit is GreenLaunchpadBase {
    function test_DeployWithInvalidToken() public {
        vm.expectRevert(GreenLaunchpad.EmptyTokenImplementation.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(
            address(0),
            address(curveImpl),
            mockUniswapRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidGreenCurve() public {
        vm.expectRevert(GreenLaunchpad.EmptyGreenCurveImplementation.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(
            address(erc20Impl),
            address(0),
            mockUniswapRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidRouter() public {
        vm.expectRevert(GreenLaunchpad.EmptyUniswapRouter.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(
            address(erc20Impl),
            address(curveImpl),
            address(0),
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidPlatformFeeReceiver() public {
        vm.expectRevert(GreenLaunchpad.EmptyPlatformFeeReceiver.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(
            address(erc20Impl),
            address(curveImpl),
            mockUniswapRouter,
            address(0),
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithGreaterThan100Fee() public {
        vm.expectRevert(GreenLaunchpad.FeeGreaterThanHundred.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(
            address(erc20Impl),
            address(curveImpl),
            mockUniswapRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            100 * 1e18,
            1 * 1e18
        );
    }

    function test_onlyOwnerCanSetNewMarketCap() public {
        vm.startPrank(makeAddr("Unkown"));
        vm.expectRevert();
        launchpad.setMarketCapThreshold(10);
        vm.stopPrank();

        launchpad.setMarketCapThreshold(10);
        assertEq(10, launchpad.marketCapThreshold());
    }

    function test_deployTokens() public {
        (address tokenContract, address curveContract) = launchpad.deployToken("TEST", "TEST", "ipfs://", 100);
        assertEq(GreenERC20(tokenContract).totalSupply(), 100);
        assertEq(GreenCurve(payable(curveContract)).saleActive(), true);
        assertEq(GreenERC20(tokenContract).balanceOf(curveContract), 90);
        assertEq(GreenERC20(tokenContract).balanceOf(platformFeeReceiver), 1);
        assertEq(GreenERC20(tokenContract).balanceOf(address(this)), 9);
    }

    function test_revert_renounceOwnership() public {
        vm.expectRevert();
        launchpad.renounceOwnership();
    }

    function test_setPlatformFee() public {
        launchpad.setPlatformFeePercentage(1);
        assertEq(launchpad.platformFeePercentage(), 1);
    }

    function test_revert_setPlatformFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setPlatformFeePercentage(1);
        assertEq(launchpad.platformFeePercentage(), platfromFeePercentage);
    }

    function test_setCommunityFee() public {
        launchpad.setCommunityPerecentage(1);
        assertEq(launchpad.communityPercentage(), 1);
    }

    function test_revert_setCommunityFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setCommunityPerecentage(1);
        assertEq(launchpad.communityPercentage(), communityPercentage);
    }

    function test_setTradeFee() public {
        launchpad.setTradeFee(1);
        assertEq(launchpad.tradeFee(), 1);
    }

    function test_revert_setTradeFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setTradeFee(1);
        assertEq(launchpad.tradeFee(), tradeFee);
    }

    function test_setPlatformFeeReceiver() public {
        launchpad.setPlatformFeeAddress(payable(makeAddr("newPlatformFeeReceiver")));
        assertEq(launchpad.platformFeeAddress(), makeAddr("newPlatformFeeReceiver"));
    }

    function test_revert_setPlatformFeeReceiverNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setPlatformFeeAddress(payable(makeAddr("newPlatformFeeReceiver")));
        assertEq(launchpad.platformFeeAddress(), platformFeeReceiver);
    }

    function test_revert_setPlatformFeeReceiverAsZero() public {
        vm.expectRevert(GreenLaunchpad.EmptyPlatformFeeReceiver.selector);
        launchpad.setPlatformFeeAddress(payable(address(0)));
        assertEq(launchpad.platformFeeAddress(), platformFeeReceiver);
    }
}
