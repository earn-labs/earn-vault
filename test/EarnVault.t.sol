// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployEarnVault} from "script/DeployEarnVault.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {EarnVault} from "src/EarnVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// import {ReflectionToken} from "reflection-token/src/ReflectionToken.sol";

contract TestScript is Test {
    // configuration
    DeployEarnVault public deployment;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    EarnVault public vault;
    IERC20 public token;

    // helpers
    address public owner;

    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");

    uint256 constant STARTING_BALANCE = 1_000_000 ether;
    uint256 constant DEPOSIT_AMOUNT = 10_000 ether;

    // events
    event Deposited(address indexed sender, uint256 indexed amount);
    event Withdrawn(address indexed sender, uint256 indexed amount);
    event ReflectionsWithdrawn(address indexed sender, uint256 indexed amount);
    event ReflectionsUpdated(uint256 indexed amount);

    // modifiers
    modifier funded(address account) {
        vm.prank(owner);
        token.transfer(account, STARTING_BALANCE);
        _;
    }

    modifier approved() {
        vm.prank(owner);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        _;
    }

    modifier deposited() {
        vm.startPrank(owner);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    modifier withReflections() {
        uint256 transferAmount = 50_000 ether;

        vm.startPrank(owner);
        token.transfer(USER1, STARTING_BALANCE);
        token.transfer(USER2, STARTING_BALANCE);
        vm.stopPrank();

        vm.prank(USER1);
        token.transfer(USER2, transferAmount);

        vm.prank(USER2);
        token.transfer(USER1, transferAmount);

        _;
    }

    // set up
    function setUp() external virtual {
        deployment = new DeployEarnVault();
        (vault, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfig();

        owner = vault.owner();
        token = IERC20(vault.getTokenAddress());
    }

    // helper
    function sendRandomTokenToVault() public returns (ERC20Mock) {
        ERC20Mock randomToken = new ERC20Mock();
        uint256 amount = 100_000 ether;

        vm.startPrank(owner);
        randomToken.mint(owner, amount);
        randomToken.transfer(address(vault), amount);
        vm.stopPrank();

        return randomToken;
    }

    /*//////////////////////////////////////////////////////////////
                              TEST DEPLOYMENT
    //////////////////////////////////////////////////////////////*/
    function test__Deployment() public view {
        assertEq(vault.owner(), networkConfig.initialOwner);
        assertEq(vault.getTokenAddress(), networkConfig.token);

        console.log("Token address: ", vault.getTokenAddress());
        console.log("Vault owner: ", vault.owner());
    }

    /*//////////////////////////////////////////////////////////////
                              TEST DEPOSIT
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__Deposit() public approved {
        vm.prank(owner);
        vault.deposit(DEPOSIT_AMOUNT);

        assertEq(vault.getTotalDeposits(), DEPOSIT_AMOUNT);
    }

    // EVENTS
    function test__Emit__Deposit() public approved {
        vm.expectEmit(true, true, true, true);
        emit Deposited(owner, DEPOSIT_AMOUNT);

        vm.prank(owner);
        vault.deposit(DEPOSIT_AMOUNT);
    }

    // ERRORS
    function test__Revert__NotOwnerDeposits() public funded(USER1) {
        vm.prank(USER1);
        token.approve(address(vault), DEPOSIT_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.deposit(DEPOSIT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                        TEST REGISTER DEPOSIT
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__RegisterDeposit() public {
        vm.startPrank(owner);
        token.transfer(address(vault), DEPOSIT_AMOUNT);
        uint256 gasLeft = gasleft();
        vault.registerDeposit(DEPOSIT_AMOUNT);
        console.log("Gas used: ", gasLeft - gasleft());
        vm.stopPrank();

        assertEq(vault.getTotalDeposits(), DEPOSIT_AMOUNT);
    }

    // EVENTS
    function test__Emit__RegisterDeposit() public approved {
        vm.prank(owner);
        token.transfer(address(vault), DEPOSIT_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Deposited(owner, DEPOSIT_AMOUNT);

        vm.prank(owner);
        vault.registerDeposit(DEPOSIT_AMOUNT);
    }

    // ERRORS
    function test__Revert__NotOwnerRegistersDeposit() public funded(USER1) {
        vm.prank(USER1);
        token.transfer(address(vault), DEPOSIT_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.registerDeposit(DEPOSIT_AMOUNT);
    }

    function test__Revert__RegistersDepositTooLarge() public deposited withReflections {
        uint256 reflections = vault.getTotalReflections();

        vm.prank(owner);
        token.transfer(address(vault), DEPOSIT_AMOUNT);

        vm.expectRevert(EarnVault.EarnVault__InvalidDepositAmount.selector);

        vm.prank(owner);
        vault.registerDeposit(DEPOSIT_AMOUNT + reflections + 1);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST WITHDRAW
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__Withdraw() public deposited {
        uint256 withdrawalAmount = 500 ether;

        vm.startPrank(owner);
        uint256 gasLeft = gasleft();
        vault.withdraw(withdrawalAmount);
        console.log("Gas used: ", gasLeft - gasleft());
        vm.stopPrank();

        assertEq(vault.getTotalDeposits(), DEPOSIT_AMOUNT - withdrawalAmount);
        assertEq(token.balanceOf(address(vault)), DEPOSIT_AMOUNT - withdrawalAmount);
    }

    function test__WithdrawMaxDeposit() public deposited withReflections {
        uint256 withdrawalAmount = DEPOSIT_AMOUNT + 20;
        uint256 totalDeposits = vault.getTotalDeposits();

        uint256 startingBalance = token.balanceOf(owner);

        vm.prank(owner);
        vault.withdraw(withdrawalAmount);

        assertGt(vault.getTotalReflections(), 0);
        assertEq(vault.getTotalDeposits(), 0);
        assertEq(token.balanceOf(owner), startingBalance + totalDeposits);
    }

    // EVENTS
    function test__Emit__Withdraw() public deposited {
        uint256 withdrawalAmount = 500 ether;

        vm.expectEmit(true, true, true, true);
        emit Withdrawn(owner, withdrawalAmount);

        vm.prank(owner);
        vault.withdraw(withdrawalAmount);
    }

    // ERRORS
    function test__Revert__NotOwnerWithdraws() public deposited {
        uint256 withdrawalAmount = 500 ether;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.withdraw(withdrawalAmount);
    }

    function test__Revert__InsufficientBalance() public deposited {
        uint256 withdrawalAmount = DEPOSIT_AMOUNT + 1;

        vm.expectRevert(EarnVault.EarnVault__InsufficientVaultBalance.selector);

        vm.prank(owner);
        vault.withdraw(withdrawalAmount);
    }

    /*//////////////////////////////////////////////////////////////
                      TEST WITHDRAW REFLECTIONS
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__WithdrawReflections() public deposited withReflections {
        uint256 reflections = vault.getTotalReflections();
        assertGt(reflections, 0);
        console.log("Reflections: ", uint256(reflections));

        uint256 startingBalance = token.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawReflections();

        assertEq(vault.getTotalReflections(), 0);
        assertEq(token.balanceOf(address(vault)), DEPOSIT_AMOUNT);
        assertEq(token.balanceOf(owner), startingBalance + reflections);
    }

    // EVENTS
    function test__Emit__WithdrawReflections() public deposited withReflections {
        uint256 reflections = vault.getTotalReflections();

        vm.expectEmit(true, true, true, true);
        emit ReflectionsWithdrawn(owner, reflections);

        vm.prank(owner);
        vault.withdrawReflections();
    }

    // ERRORS
    function test__Revert__NotOwnerWithdrawsReflections() public deposited {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.withdrawReflections();
    }

    /*//////////////////////////////////////////////////////////////
                             TEST WITHDRAW
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__WithdrawAll() public deposited {
        uint256 vaultBalance = token.balanceOf(address(vault));
        uint256 ownerBalance = token.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawAll();

        assertEq(vault.getTotalDeposits(), 0);
        assertEq(vault.getTotalReflections(), 0);
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(owner), ownerBalance + vaultBalance);
    }

    // EVENTS
    function test__Emit__WithdrawAll() public deposited withReflections {
        uint256 vaultBalance = token.balanceOf(address(vault));

        vm.expectEmit(true, true, true, true);
        emit Withdrawn(owner, vaultBalance);

        vm.prank(owner);
        vault.withdrawAll();
    }

    // ERRORS
    function test__Revert__NotOwnerWithdrawsAll() public deposited {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.withdrawAll();
    }

    /*//////////////////////////////////////////////////////////////
                             TEST WITHDRAW
    //////////////////////////////////////////////////////////////*/

    // SUCCESS
    function test__WithdrawTokens(uint256 amount) public deposited withReflections {
        ERC20Mock randToken = sendRandomTokenToVault();
        uint256 vaultBalance = randToken.balanceOf(address(vault));
        uint256 ownerBalance = randToken.balanceOf(owner);

        amount = bound(amount, 1, vaultBalance);

        vm.prank(owner);
        vault.withdrawTokens(address(randToken), amount);

        assertEq(randToken.balanceOf(address(vault)), vaultBalance - amount);
        assertEq(randToken.balanceOf(owner), ownerBalance + amount);
    }

    function test__WithdrawTokens__allTokens() public deposited withReflections {
        ERC20Mock randToken = sendRandomTokenToVault();
        uint256 vaultBalance = randToken.balanceOf(address(vault));
        uint256 ownerBalance = randToken.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawTokens(address(randToken), 0);

        assertEq(randToken.balanceOf(address(vault)), 0);
        assertEq(randToken.balanceOf(owner), ownerBalance + vaultBalance);
    }

    // ERRORS
    function test__Revert__NotOwnerWithdrawsTokens() public deposited withReflections {
        ERC20Mock randToken = sendRandomTokenToVault();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        vault.withdrawTokens(address(randToken), 100 ether);
    }
}
