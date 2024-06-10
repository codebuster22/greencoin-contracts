// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./GreenCurve.sol";

contract GreenERC20 is ERC20Upgradeable {
    string public metadataURI;
    address payable public bondingCurve;

    bool public initialized = false;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _marketCapThreshold, string memory _metadataURI, address _bondingCurveImplementation, address  _uniswapRouter) external initializer returns(address) {
        __ERC20_init(_name, _symbol);

        metadataURI = _metadataURI;

        bondingCurve = payable(Clones.clone(_bondingCurveImplementation));
        GreenCurve(bondingCurve).initialize(address(this), _maxSupply, _marketCapThreshold, _uniswapRouter);
        _approve(address(this), bondingCurve, _maxSupply);
        _mint(bondingCurve, _maxSupply);
        GreenCurve(bondingCurve).startBonding();
        return bondingCurve;
    }
}
