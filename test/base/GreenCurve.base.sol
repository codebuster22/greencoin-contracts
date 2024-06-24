pragma solidity ^0.8.20;

import {GreenCurve} from "../../src/GreenCurve.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/Test.sol";
import {MockPair} from "../mocks/MockPair.sol";
import {WNative} from "../mocks/WNative.sol";

contract GreenCurveBase is Test {
    GreenCurve public curve;
    ERC20Mock public erc20;
    address public factory = makeAddr("factory");
    address public curveImplementation;
    uint256 public HUNDRED_PERCENTAGE = 100 * 1e18;
    uint256 public maxSupply = 1_000_000_000 ether;
    uint256 public marketCapThreshold = 100_000 ether;
    uint256 public platformFee = 1 * 1e18; // 1 %
    uint256 public platformShare = maxSupply * platformFee / HUNDRED_PERCENTAGE;
    uint256 public communityFee = 1 * 1e18; // 1 %
    uint256 public communityShare = maxSupply * communityFee / HUNDRED_PERCENTAGE;
    uint256 public tradeFee = 3; // 0.3%
    uint256 public totalToBeSold = maxSupply - platformShare - communityShare;
    address public owner = makeAddr("owner");
    address public community = makeAddr("community");
    address public protocol = makeAddr("protocol");
    address public router = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public feeReceiver = makeAddr("feeReceiver");

    function setUp() public {
        GreenCurve curveImpl = new GreenCurve();
        curve = GreenCurve(payable(Clones.clone(address(curveImpl))));
        erc20 = new ERC20Mock();
        erc20.mint(address(curve), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        curve.initialize(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
    }
}
