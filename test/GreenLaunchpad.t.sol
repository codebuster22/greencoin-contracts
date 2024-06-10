// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GreenLaunchpad} from "../src/GreenLaunchpad.sol";
import {GreenERC20} from "../src/GreenERC20.sol";
import {GreenCurve} from "../src/GreenCurve.sol";

contract GreenLaunchpadTest is Test {
    GreenLaunchpad public launchpad;
    GreenERC20 public erc20Impl;
    GreenCurve public curveImpl;
    address public mockUniswapRouter = makeAddr("UniswapV2Router");

    function setUp() public {
        erc20Impl = new GreenERC20();
        curveImpl = new GreenCurve();
        launchpad = new GreenLaunchpad(address(erc20Impl), address(curveImpl), mockUniswapRouter);
    }

    function test_DeployWithInvalidToken() public {
        vm.expectRevert(GreenLaunchpad.EmptyTokenImplementation.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(address(0), address(curveImpl), mockUniswapRouter);
    }

    function test_DeployWithInvalidBondingCurve() public {
        vm.expectRevert(GreenLaunchpad.EmptyBondingCurveImplementation.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(address(erc20Impl), address(0), mockUniswapRouter);
    }

    function test_DeployWithInvalidRouter() public {
        vm.expectRevert(GreenLaunchpad.EmptyUniswapRouter.selector);
        GreenLaunchpad testLaunchpad = new GreenLaunchpad(address(erc20Impl), address(curveImpl), address(0));
    }

    function test_newTokemImplCannotBeZero() public {
        vm.expectRevert(GreenLaunchpad.EmptyTokenImplementation.selector);
        launchpad.setTokemImplementation(address(0));
    }

    function test_newBondingCurveImplCannotBeZero() public {
        vm.expectRevert(GreenLaunchpad.EmptyBondingCurveImplementation.selector);
        launchpad.setBondingCurveImplementation(address(0));
    }

    function test_newRouterCannotBeZero() public {
        vm.expectRevert(GreenLaunchpad.EmptyUniswapRouter.selector);
        launchpad.setRouter(address(0));
    }

    function test_onlyOwnerCanSetNewAddress() public {
        vm.startPrank(makeAddr("Unkown"));
        vm.expectRevert();
        launchpad.setBondingCurveImplementation(address(1));

        vm.expectRevert();
        launchpad.setTokemImplementation(address(1));

        vm.expectRevert();
        launchpad.setRouter(address(1));
        vm.stopPrank();

        launchpad.setBondingCurveImplementation(address(1));
        assertEq(address(1), launchpad.bondingCurveImplementation());

        launchpad.setTokemImplementation(address(1));
        assertEq(address(1), launchpad.tokenImplementation());

        launchpad.setRouter(address(1));
        assertEq(address(1), launchpad.uniswapRouter());
    }

    function test_deployTokens() public {
        (address tokenContract, address curveContract) = launchpad.deployToken("TEST", "TEST", 100, "ipfs://", 100);
        assertEq(GreenERC20(tokenContract).totalSupply(), 100);
        assertEq(GreenCurve(payable(curveContract)).bondingActive(), true);
        assertEq(GreenERC20(tokenContract).balanceOf(curveContract), 100);
    }
}
