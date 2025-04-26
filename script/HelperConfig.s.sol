// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReflectionToken} from "reflection-token/src/ReflectionToken.sol";

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
        if (block.chainid == 8453 || block.chainid == 123) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 84532 || block.chainid == 84531) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          CHAIN CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF,
            token: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF,
            token: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();
        ReflectionToken token = new ReflectionToken("RF", "RF", 1_000_000_000, 2000, owner);
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
