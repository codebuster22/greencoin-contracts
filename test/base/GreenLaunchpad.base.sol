// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GreenLaunchpad} from "../../src/GreenLaunchpad.sol";
import {GreenERC20} from "../../src/GreenERC20.sol";
import {GreenCurve} from "../../src/GreenCurve.sol";

contract GreenLaunchpadBase is Test {
    GreenLaunchpad public launchpad;
    GreenERC20 public erc20Impl;
    GreenCurve public curveImpl;
    address public mockUniswapRouter = makeAddr("UniswapRouter");
    address public platformFeeReceiver = makeAddr("PlatformFeeReceiver");
    uint256 public marketCapThreshold = 1_000_000_000;
    uint256 public platfromFeePercentage = 1 * 1e18;
    uint256 public communityPercentage = 9 * 1e18;
    uint256 public tradeFee = 1 * 1e17;

    function setUp() public {
        erc20Impl = new GreenERC20();
        curveImpl = new GreenCurve();
        launchpad = new GreenLaunchpad(
            address(erc20Impl),
            address(curveImpl),
            mockUniswapRouter,
            platformFeeReceiver,
            marketCapThreshold,
            tradeFee,
            platfromFeePercentage,
            communityPercentage
        );
    }
}
