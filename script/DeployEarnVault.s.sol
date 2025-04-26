// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {EarnVault} from "src/EarnVault.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEarnVault is Script {
    function run() external returns (EarnVault, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address initialOwner, address token) = config.activeNetworkConfig();

        vm.startBroadcast();
        EarnVault vault = new EarnVault(initialOwner, token);
        vm.stopBroadcast();

        return (vault, config);
    }
}
