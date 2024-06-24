forge build --silent
jq '.abi' ./out/GreenERC20.sol/GreenERC20.json > './exports/GreenERC20.json'
jq '.abi' ./out/GreenCurve.sol/GreenCurve.json > './exports/GreenCurve.json'
jq '.abi' ./out/GreenLaunchpad.sol/GreenLaunchpad.json > './exports/GreenLaunchpad.json'
