// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Interface of the Reflection Token as defined in ReflectionToken.sol.
 */
interface IReflectionToken {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event SetFee(uint256 indexed fee);
    event ExcludedFromReward(address indexed account, bool indexed isExcluded);
    event ExcludedFromFee(address indexed account, bool indexed isExcluded);

    /**
     * @dev Sets transfer fee for the token.
     *  Emits a {SetFee} event.
     */
    function setFee(uint256 newTxFee) external;

    /**
     * @dev Excludes address from transfer fee.
     *  Emits a {ExcludedFromFee} event.
     */
    function excludeFromFee(address account, bool isExcluded) external;

    /**
     * @dev Excludes address from rewards.
     *  Emits a {ExcludedFromReward} event.
     */
    function excludeFromReward(address account, bool isExcluded) external;

    /**
     * @dev Withdraws token stuck in contract
     */
    function withdrawTokens(address tokenAddress, address receiverAddress) external returns (bool);

    /**
     * @dev Returns transfer fee in basis points.
     */
    function getFee() external view returns (uint256);

    /**
     * @dev Returns total fees collected/distributed in the contract.
     */
    function getTotalFees() external view returns (uint256);

    /**
     * @dev Returns true if the account is excluded from transfer fee.
     */
    function isExcludedFromFee(address account) external view returns (bool);

    /**
     * @dev Returns true if the account is excluded from rewards.
     */
    function isExcludedFromReward(address account) external view returns (bool);

    /**
     * @dev Returns the number of accounts excluded from rewards.
     */
    function getNumberOfAccountsExcludedFromRewards() external view returns (uint256);
}
