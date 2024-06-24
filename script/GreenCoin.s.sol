// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {GreenCurve} from "../src/GreenCurve.sol";
import {GreenERC20} from "../src/GreenERC20.sol";
import {GreenLaunchpad} from "../src/GreenLaunchpad.sol";

contract GreenCoinScript is Script {
    function setUp() public {}

    function run() public {
        address router = vm.envAddress("ROUTER");
        address platformFeeReceiver = vm.envAddress("FEE_RECEIVER");
        uint256 platformFee = vm.envUint("PLATFORM_FEE");
        uint256 communityAllocationPercentage = vm.envUint("COMMUNITY_FEE");
        uint256 marketCapThreshold = vm.envUint("MARKET_CAP_THRESHOLD");
        uint256 tradeFee = vm.envUint("TRADE_FEE");

        vm.startBroadcast();
        // deploy erc20
        GreenERC20 greencoin = new GreenERC20();
        // deploy curve
        GreenCurve greenCurve = new GreenCurve();
        // deploy launchpad
        GreenLaunchpad launchpad = new GreenLaunchpad(address(greencoin), address(greenCurve), router,  platformFeeReceiver, marketCapThreshold, tradeFee, platformFee, communityAllocationPercentage);
        vm.stopBroadcast();
    }
}
