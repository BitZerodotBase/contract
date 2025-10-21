// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BitStake is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    uint256 public rewardRate = 1;
    uint256 public totalStaked;

    struct Staker {
        uint256 amountStaked;
        uint256 rewardDebt;
        uint256 lastUpdated;
    }

    mapping(address => Staker) public stakers;

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0");

        Staker storage user = stakers[msg.sender];
        updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        user.amountStaked += _amount;
        user.lastUpdated = block.timestamp;
        totalStaked += _amount;
    }

    function stakeAll() external nonReentrant {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        uint256 allowance = stakingToken.allowance(msg.sender, address(this));
        uint256 amountToStake = balance < allowance ? balance : allowance;

        require(amountToStake > 0, "No tokens to stake");

        Staker storage user = stakers[msg.sender];
        updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), amountToStake);
        user.amountStaked += amountToStake;
        user.lastUpdated = block.timestamp;
        totalStaked += amountToStake;
    }

    function unstake(uint256 _amount) external nonReentrant {
        Staker storage user = stakers[msg.sender];
        require(_amount > 0 && _amount <= user.amountStaked, "Invalid amount");

        updateReward(msg.sender);

        user.amountStaked -= _amount;
        totalStaked -= _amount;

        stakingToken.transfer(msg.sender, _amount);
    }

    function unstakeAll() external nonReentrant {
        Staker storage user = stakers[msg.sender];
        uint256 amount = user.amountStaked;
        require(amount > 0, "Nothing staked");

        updateReward(msg.sender);

        user.amountStaked = 0;
        totalStaked -= amount;

        stakingToken.transfer(msg.sender, amount);
    }

    function claimReward() external nonReentrant {
        Staker storage user = stakers[msg.sender];
        updateReward(msg.sender);

        uint256 reward = user.rewardDebt;
        require(reward > 0, "No reward");

        user.rewardDebt = 0;
        stakingToken.transfer(msg.sender, reward);
    }

    function updateReward(address _user) internal {
        Staker storage user = stakers[_user];

        if (user.amountStaked > 0) {
            uint256 timeDiff = block.timestamp - user.lastUpdated;
            uint256 reward = (timeDiff * rewardRate * user.amountStaked) / 1e18;
            user.rewardDebt += reward;
        }

        user.lastUpdated = block.timestamp;
    }

    function pendingReward(address _user) external view returns (uint256) {
        Staker storage user = stakers[_user];

        if (user.amountStaked == 0) {
            return user.rewardDebt;
        }

        uint256 timeDiff = block.timestamp - user.lastUpdated;
        uint256 additionalReward = (timeDiff * rewardRate * user.amountStaked) / 1e18;

        return user.rewardDebt + additionalReward;
    }

    function getStaked(address _user) external view returns (uint256) {
        return stakers[_user].amountStaked;
    }

    function allowanceOf(address _user) external view returns (uint256) {
        return stakingToken.allowance(_user, address(this));
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    function emergencyWithdraw() external nonReentrant {
        Staker storage user = stakers[msg.sender];
        uint256 amount = user.amountStaked;
        require(amount > 0, "Nothing to withdraw");

        user.amountStaked = 0;
        user.rewardDebt = 0;
        totalStaked -= amount;

        stakingToken.transfer(msg.sender, amount);
    }
}
