// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GreenERC20.sol";

contract GreenLaunchpad is Ownable(msg.sender) {
    event TokenDeployed(address tokenAddress, address bondingCurveAddress);
    event BondingCurveImplementationUpdated(address newBondingCurveAddress);
    event TokenImplementationUpdated(address newTokenImplementationAddress);
    event UniswapRouterUpdated(address newRouter);

    address public tokenImplementation;
    address public bondingCurveImplementation;
    address public uniswapRouter;
    
    error EmptyTokenImplementation();
    error EmptyBondingCurveImplementation();
    error EmptyUniswapRouter();

    constructor(address _tokenImplementation, address _bondingCurveImplementation, address _uniswapRouter) {
        if(_tokenImplementation == address(0)) revert EmptyTokenImplementation();
        if(_bondingCurveImplementation == address(0)) revert EmptyBondingCurveImplementation();
        if(_uniswapRouter == address(0)) revert EmptyUniswapRouter();
        tokenImplementation = _tokenImplementation;
        bondingCurveImplementation = _bondingCurveImplementation;
        uniswapRouter = _uniswapRouter;
    }

    function deployToken(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory metadataURI,
        uint256 marketCapThreshold
    ) external returns(address, address) {
        address tokenClone = Clones.clone(tokenImplementation);

        address curveClone = GreenERC20(tokenClone).initialize(
            name,
            symbol,
            maxSupply,
            marketCapThreshold,
            metadataURI,
            bondingCurveImplementation,
            uniswapRouter
        );

        emit TokenDeployed(tokenClone, curveClone);
        return (tokenClone, curveClone);
    }

    function setTokemImplementation(address _newTokenImplementation) external onlyOwner {
        if(_newTokenImplementation == address(0)) revert EmptyTokenImplementation();
        tokenImplementation = _newTokenImplementation;
        emit TokenImplementationUpdated(_newTokenImplementation);
    }

    function setBondingCurveImplementation(address _newBondingCurveImplementation) external onlyOwner {
        if(_newBondingCurveImplementation == address(0)) revert EmptyBondingCurveImplementation();
        bondingCurveImplementation = _newBondingCurveImplementation;
        emit BondingCurveImplementationUpdated(_newBondingCurveImplementation);
    }

    function setRouter(address _newRouter) external onlyOwner {
        if(_newRouter == address(0)) revert EmptyUniswapRouter();
        uniswapRouter = _newRouter;
        emit UniswapRouterUpdated(_newRouter);
    }
}
