pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {GreenLaunchpad} from "../../src/GreenLaunchpad.sol";
import {GreenERC20} from "../../src/GreenERC20.sol";
import {GreenCurve} from "../../src/GreenCurve.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract GreenERC20Base is Test {
    GreenERC20 public erc20;
    address public factory = makeAddr("factory");
    address public curveImplementation;

    function setUp() public {
        GreenERC20 erc20Implementation = new GreenERC20();
        erc20 = GreenERC20(Clones.clone(address(erc20Implementation)));
        curveImplementation = address(new GreenCurve());
    }
}
