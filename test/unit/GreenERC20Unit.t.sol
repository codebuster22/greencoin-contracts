pragma solidity ^0.8.20;

import {GreenERC20Base} from "../base/GreenERC20.base.sol";
import {GreenLaunchpad} from "../../src/GreenLaunchpad.sol";
import {GreenERC20} from "../../src/GreenERC20.sol";
import {GreenCurve} from "../../src/GreenCurve.sol";

contract GreenERC20Unit is GreenERC20Base {
    string public name = "ERC20";
    string public symbol = "ERC20_SYMBOL";
    uint256 public maxSupply = 1_000_000e18;
    uint256 public marketCapThreshold = 100_000e18;
    string public metadataUri = "ipfs://metadata";
    address public router = makeAddr("UniswapRouter");
    address public platformFeeReceiver = makeAddr("platformFeeReceiver");

    function test_initialize() public {
        assertEq(erc20.greenCurve(), address(0));
        GreenERC20.InitializeParams memory params = GreenERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            maxSupply,
            1,
            9,
            marketCapThreshold,
            curveImplementation,
            platformFeeReceiver,
            router,
            address(this)
        );
        erc20.initialize(params);
        assertNotEq(erc20.greenCurve(), address(0));
        assertEq(erc20.name(), name);
        assertEq(erc20.symbol(), symbol);
        assertEq(erc20.metadataURI(), metadataUri);
        assertEq(address(GreenCurve(erc20.greenCurve()).uniswapRouter()), router);
        assertEq(address(GreenCurve(erc20.greenCurve()).token()), address(erc20));
        assertEq(GreenCurve(erc20.greenCurve()).maxSupply(), maxSupply);
        assertEq(GreenCurve(erc20.greenCurve()).marketCapThreshold(), marketCapThreshold);
        assertEq(GreenCurve(erc20.greenCurve()).greenErc20Balance(), maxSupply);
        assertEq(GreenCurve(erc20.greenCurve()).ethBalance(), 0);
        assertEq(GreenCurve(erc20.greenCurve()).saleActive(), true);
    }

    function test_revert_initializeWithEmptyMetadata() public {
        vm.expectRevert(GreenERC20.MetadataEmpty.selector);
        GreenERC20.InitializeParams memory params = GreenERC20.InitializeParams(
            name,
            symbol,
            "",
            0,
            maxSupply,
            0,
            0,
            marketCapThreshold,
            curveImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
    }

    function test_revert_initializeWithZeroMaxSupply() public {
        vm.expectRevert(GreenERC20.CannotSellZeroTokens.selector);

        GreenERC20.InitializeParams memory params = GreenERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            0,
            0,
            0,
            marketCapThreshold,
            curveImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
    }

    function test_revert_initializeWithNonZeroPlatformFeeAndZeroReceiver() public {
        vm.expectRevert(GreenERC20.PlatformFeeReceiverEmpty.selector);
        GreenERC20.InitializeParams memory params = GreenERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            100,
            1,
            9,
            marketCapThreshold,
            curveImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
    }
}
