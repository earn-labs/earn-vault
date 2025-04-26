// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReflectionTokenMock} from "test/mocks/ReflectionTokenMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address initialOwner;
        address token;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    uint256 constant CONSTANT = 0;

    constructor() {
        if (block.chainid == 1 || block.chainid == 123) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          CHAIN CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0x0cf66382d52C2D6c1D095c536c16c203117E2B2f,
            token: 0x0b61C4f33BCdEF83359ab97673Cb5961c6435F4E
        });
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0xEcA5652Ebc9A3b7E9E14294197A86b02cD8C3A67,
            token: 0xc8bdD7805fAd8dc59b753FEcCCDf17b98c17465b
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();
        ReflectionTokenMock token = new ReflectionTokenMock("RF", "RF", 1_000_000_000, 2000, owner);
        vm.stopBroadcast();

        console.log("Token deployed at: %s", address(token));

        return NetworkConfig({initialOwner: owner, token: address(token)});
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
