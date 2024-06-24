source .env
forge script script/GreenCoin.s.sol:GreenCoinScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow --delay 15 --retries 30