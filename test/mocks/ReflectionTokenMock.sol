// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
//////////////////////////////////////////////////////////////*/
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IReflectionToken} from "test/mocks/IReflectionToken.sol";

/**
 * @title ReflectionTokenMock
 * @author Nadina Oates
 * @notice This contract implements a token that automatically distributes rewards from fees to all holders based on their balance.
 */
contract ReflectionTokenMock is ERC20, IReflectionToken, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant PRECISION = 10000 * 1e18;
    uint256 private constant MAX = type(uint256).max;

    uint256 private immutable i_tTotalSupply;

    uint256 private s_rTotalSupply;

    address[] private s_excludedFromReward;

    uint256 private s_txFee; // 200 => 2%
    uint256 private s_totalFees;

    mapping(address => uint256) private s_rBalances; // balances in r-space
    mapping(address => uint256) private s_tBalances; // balances in t-space

    mapping(address => bool) private s_isExcludedFromFee;
    mapping(address => bool) private s_isExcludedFromReward;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ReflectionToken__ExcludedFromRewardListTooLong();
    error ReflectionToken__ValueAlreadySet();
    error ReflectionToken__TokenTransferFailed();
    error ReflectionToken__InvalidFee();
    error ReflectionToken__TransfersDisabled();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 initialTxFee,
        address initialOwner
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        i_tTotalSupply = totalSupply_ * 10 ** decimals();
        s_txFee = initialTxFee * 1e18;

        _excludeFromFee(initialOwner, true);
        _excludeFromFee(address(this), true);
        _mint(initialOwner, i_tTotalSupply);
        transferOwnership(initialOwner);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets transaction fee
     * @param newTxFee new transaction fee in basis points (1% = 100)
     */
    function setFee(uint256 newTxFee) external onlyOwner {
        if (newTxFee > 10000) {
            revert ReflectionToken__InvalidFee();
        }
        s_txFee = newTxFee * 1e18;
        emit SetFee(newTxFee);
    }

    /**
     * @notice Excludes address from transaction fee
     * @param account address
     * @param isExcluded whether the account is excluded or not
     */
    function excludeFromFee(address account, bool isExcluded) external onlyOwner {
        _excludeFromFee(account, isExcluded);
    }

    /**
     * @notice Excludes address from reflection reward
     * @param account address
     * @param isExcluded whether the account is excluded or not
     */
    function excludeFromReward(address account, bool isExcluded) external onlyOwner {
        _excludeFromReward(account, isExcluded);
    }

    /**
     * @notice Withdraws tokens from contract
     * @param tokenAddress token contract address
     * @param receiverAddress address to receive tokens
     */
    function withdrawTokens(address tokenAddress, address receiverAddress) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
        if (!success) revert ReflectionToken__TokenTransferFailed();
    }

    function getFee() external view returns (uint256) {
        return s_txFee;
    }

    function getTotalFees() external view returns (uint256) {
        return s_totalFees;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return s_isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return s_isExcludedFromReward[account];
    }

    function getNumberOfAccountsExcludedFromRewards() external view returns (uint256) {
        return s_excludedFromReward.length;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns total supply
     */
    function totalSupply() public view override returns (uint256) {
        return i_tTotalSupply;
    }

    /**
     * @notice Returns balance of account
     * @param account address
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (s_isExcludedFromReward[account]) return s_tBalances[account];
        uint256 rate = _getRate();
        return s_rBalances[account] / rate;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Overrides the transfer logic as recommended by Openzeppelin handling all the fee and reflection logic.
     * @param from address
     * @param to address
     * @param value transfer amount
     */
    function _update(address from, address to, uint256 value) internal override {
        // minting
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            s_rTotalSupply += (MAX - (MAX % value));
            unchecked {
                s_rBalances[to] += s_rTotalSupply;
            }

            emit Transfer(from, to, value);
        } else {
            // regular transfer
            uint256 txFee;
            if (s_isExcludedFromFee[from] || s_isExcludedFromFee[to]) {
                txFee = 0;
            } else {
                txFee = s_txFee;
                if (txFee == PRECISION) {
                    revert ReflectionToken__TransfersDisabled();
                }
            }

            // calc t-values
            uint256 tAmount = value;
            uint256 tTxFee = tAmount * txFee / PRECISION;
            uint256 tTransferAmount = tAmount - tTxFee;

            // calc r-values
            uint256 rate = _getRate();
            uint256 rTxFee = tTxFee * rate;
            uint256 rAmount = tAmount * rate;
            uint256 rTransferAmount = rAmount - rTxFee;

            // check balances
            uint256 rFromBalance = s_rBalances[from];
            uint256 tFromBalance = s_tBalances[from];

            if (s_isExcludedFromReward[from]) {
                if (tFromBalance < tAmount) {
                    revert ERC20InsufficientBalance(from, balanceOf(from), value);
                }
            } else {
                if (rFromBalance < rAmount) {
                    revert ERC20InsufficientBalance(from, balanceOf(from), value);
                }
            }

            // Overflow not possible: the sum of all balances is capped by
            // rTotalSupply and tTotalSupply, and the sum is preserved by
            // decrementing then incrementing.
            unchecked {
                // udpate balances in r-space
                s_rBalances[from] = rFromBalance - rAmount;
                s_rBalances[to] += rTransferAmount;

                // update balances in t-space
                if (s_isExcludedFromReward[from] && s_isExcludedFromReward[to]) {
                    s_tBalances[from] = tFromBalance - tAmount;
                    s_tBalances[to] += tTransferAmount;
                } else if (s_isExcludedFromReward[from] && !s_isExcludedFromReward[to]) {
                    // cannot overflow as tamount is a function of rAmount and _rTotalSupply is mapped to i_tTotalSupply
                    s_tBalances[from] = tFromBalance - tAmount;
                } else if (!s_isExcludedFromReward[from] && s_isExcludedFromReward[to]) {
                    // cannot overflow as tAmount is function of rAmount and _rTotalSupply is mapped to i_tTotalSupply
                    s_tBalances[to] += tTransferAmount;
                }

                // reflect fee
                // can never go below zero because rTxFee percentage of
                // current s_rTotalSupply
                s_rTotalSupply -= rTxFee;
                s_totalFees += tTxFee;

                emit Transfer(from, to, tTransferAmount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Excludes address from transaction fee
     * @param account address
     * @param isExcluded whether the account is excluded or not
     */
    function _excludeFromFee(address account, bool isExcluded) private {
        s_isExcludedFromFee[account] = isExcluded;
        emit ExcludedFromFee(account, isExcluded);
    }

    /**
     * @notice Excludes address from reflection reward
     * @param account address
     * @param isExcluded whether the account is excluded or not
     */
    function _excludeFromReward(address account, bool isExcluded) private {
        if (s_isExcludedFromReward[account] == isExcluded) {
            revert ReflectionToken__ValueAlreadySet();
        }

        if (s_excludedFromReward.length + 1 > 100) {
            revert ReflectionToken__ExcludedFromRewardListTooLong();
        }

        if (isExcluded) {
            if (s_rBalances[account] > 0) {
                uint256 rate = _getRate();
                s_tBalances[account] = s_rBalances[account] / rate;
            }
            s_isExcludedFromReward[account] = true;
            s_excludedFromReward.push(account);
        } else {
            uint256 nExcluded = s_excludedFromReward.length;
            for (uint256 i = 0; i < nExcluded; i++) {
                if (s_excludedFromReward[i] == account) {
                    s_excludedFromReward[i] = s_excludedFromReward[s_excludedFromReward.length - 1];
                    s_tBalances[account] = 0;
                    s_isExcludedFromReward[account] = false;
                    s_excludedFromReward.pop();
                    break;
                }
            }
        }
        emit ExcludedFromReward(account, isExcluded);
    }

    /**
     * @notice Returns the conversion rate between R (reflection) space and T (true) space. See docs for details.
     */
    function _getRate() private view returns (uint256) {
        uint256 rSupply = s_rTotalSupply;
        uint256 tSupply = i_tTotalSupply;

        uint256 nExcluded = s_excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded;) {
            unchecked {
                rSupply = rSupply - s_rBalances[s_excludedFromReward[i]];
                tSupply = tSupply - s_tBalances[s_excludedFromReward[i]];
                i++;
            }
        }

        // set lower bound of rSupply to avoid numerical issues (e.g. division by small values near zero)
        if (rSupply < s_rTotalSupply / i_tTotalSupply) {
            rSupply = s_rTotalSupply;
            tSupply = i_tTotalSupply;
        }
        // rSupply always >= tSupply (no precision loss)
        uint256 rate = rSupply / tSupply;
        return rate;
    }
}
