// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
//////////////////////////////////////////////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title EarnVault
 * @author Nadina Oates
 * @notice Vault for holding reflection tokens.
 * @dev The contract owner must be excluded from token rewards.
 */
contract EarnVault is Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 private immutable i_reflectionToken;

    uint256 private s_totalDeposits;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposited(address indexed sender, uint256 indexed amount);
    event Withdrawn(address indexed sender, uint256 indexed amount);
    event ReflectionsWithdrawn(address indexed sender, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error EarnVault__InsufficientVaultBalance();
    error EarnVault__InvalidDepositAmount();
    error EarnVault__CannotWithdrawReflectionToken();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address _owner, address _token) Ownable(_owner) {
        i_reflectionToken = IERC20(_token);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits token to the vault.
     * @param amount token amount to deposit
     */
    function deposit(uint256 amount) external onlyOwner {
        s_totalDeposits += amount;
        i_reflectionToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Registers token sent to the vault.
     * @param amount token amount deposited via transfer
     */
    function registerDeposit(uint256 amount) external onlyOwner {
        uint256 expectedDeposits = s_totalDeposits + amount;
        if (expectedDeposits > i_reflectionToken.balanceOf(address(this))) {
            revert EarnVault__InvalidDepositAmount();
        }
        s_totalDeposits = expectedDeposits;
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraws tokens from the vault, without any reflections accrued.
     * @param amount token amount to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = i_reflectionToken.balanceOf(address(this));
        if (amount > balance) revert EarnVault__InsufficientVaultBalance();
        if (amount > s_totalDeposits) {
            amount = s_totalDeposits;
        }
        s_totalDeposits -= amount;

        i_reflectionToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Withdraws reflections accrued from the vault.
     */
    function withdrawReflections() external onlyOwner {
        uint256 amount = _calcReflections();
        i_reflectionToken.safeTransfer(msg.sender, amount);

        emit ReflectionsWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Withdraws all tokens from the vault.
     */
    function withdrawAll() external onlyOwner {
        uint256 amount = i_reflectionToken.balanceOf(address(this));
        s_totalDeposits = 0;

        i_reflectionToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Withdraws other tokens in the vault.
     */
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(i_reflectionToken)) {
            revert EarnVault__CannotWithdrawReflectionToken();
        }
        if (amount == 0) {
            amount = IERC20(token).balanceOf(address(this));
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the total reflections in the vault.
     */
    function _calcReflections() private view returns (uint256) {
        return i_reflectionToken.balanceOf(address(this)) - s_totalDeposits;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns configured reflection token address.
     */
    function getTokenAddress() external view returns (address) {
        return address(i_reflectionToken);
    }

    /**
     * @notice Returns total deposits in the vault.
     */
    function getTotalDeposits() external view returns (uint256) {
        return s_totalDeposits;
    }

    /**
     * @notice Returns total reflections accrued in the vault.
     */
    function getTotalReflections() external view returns (uint256) {
        return _calcReflections();
    }
}
