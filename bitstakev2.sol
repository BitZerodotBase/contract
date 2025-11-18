// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IValidatorRegistry {
    function isValidator(address _operator) external view returns (bool);
    function getValidatorInfo(address _operator) external view returns (
        string memory name,
        uint256 commissionRate,
        bool exists
    );
    function autoRemoveValidator(address _operator) external;
}

contract BitStake is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    IValidatorRegistry public validatorRegistry;

    uint256 public rewardRate = 1000000000;
    uint256 public totalStaked;

    struct Delegator {
        uint256 amountStaked;
        uint256 rewardDebt;
        uint256 lastUpdated;
        address validator;
    }

    struct ValidatorData {
        uint256 totalDelegated;
        uint256 pendingCommission;
    }

    mapping(address => Delegator) public delegators;
    mapping(address => ValidatorData) public validators;

    event Delegated(address indexed user, address indexed validator, uint256 amount);
    event UndelegatedAll(address indexed user, address indexed validator, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event CommissionClaimed(address indexed validator, uint256 amount);

    constructor(address _stakingToken, address _registryAddress) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        validatorRegistry = IValidatorRegistry(_registryAddress);
    }

    function delegate(address _validator, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot delegate 0");
        if (_validator != msg.sender) {
            require(validatorRegistry.isValidator(_validator), "Not a valid validator");
        }

        Delegator storage user = delegators[msg.sender];
        if (user.amountStaked > 0) {
            require(user.validator == _validator, "Must undelegate to change validator");
        } else {
            user.validator = _validator;
        }

        updateReward(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        user.amountStaked += _amount;
        user.lastUpdated = block.timestamp;
        validators[_validator].totalDelegated += _amount;
        totalStaked += _amount;

        emit Delegated(msg.sender, _validator, _amount);
    }

    function undelegate(uint256 _amount) external nonReentrant {
    Delegator storage user = delegators[msg.sender];
    require(user.amountStaked > 0, "Nothing staked");
    require(_amount > 0 && _amount <= user.amountStaked, "Invalid amount");

    address validator = user.validator;
    updateReward(msg.sender);

    user.amountStaked -= _amount;
    if (validators[validator].totalDelegated >= _amount) {
        validators[validator].totalDelegated -= _amount;
    } else {
        validators[validator].totalDelegated = 0;
    }

    if (totalStaked >= _amount) {
        totalStaked -= _amount;
    } else {
        totalStaked = 0;
    }

    if (validator == msg.sender && validatorRegistry.isValidator(msg.sender)) {
        try validatorRegistry.autoRemoveValidator(msg.sender) {} catch {}
    }

    stakingToken.transfer(msg.sender, _amount);
    emit UndelegatedAll(msg.sender, validator, _amount);
}

    function undelegateAll() external nonReentrant {
        Delegator storage user = delegators[msg.sender];
        uint256 amount = user.amountStaked;
        require(amount > 0, "Nothing staked");

        address validator = user.validator;
        updateReward(msg.sender);

        user.amountStaked = 0;
        user.validator = address(0);

        if (validators[validator].totalDelegated >= amount) {
            validators[validator].totalDelegated -= amount;
        } else {
            validators[validator].totalDelegated = 0;
        }

        if (totalStaked >= amount) {
            totalStaked -= amount;
        } else {
            totalStaked = 0;
        }

        if (validator == msg.sender && validatorRegistry.isValidator(msg.sender)) {
            try validatorRegistry.autoRemoveValidator(msg.sender) {
            } catch {
            }
        }

        stakingToken.transfer(msg.sender, amount);
        emit UndelegatedAll(msg.sender, validator, amount);
    }

    function claimReward() external nonReentrant {
        Delegator storage user = delegators[msg.sender];
        updateReward(msg.sender);

        uint256 reward = user.rewardDebt;
        require(reward > 0, "No reward to claim");

        user.rewardDebt = 0;
        stakingToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function claimCommission() external nonReentrant {
        address validator = msg.sender;
        uint256 commission = validators[validator].pendingCommission;
        require(commission > 0, "No commission to claim");

        validators[validator].pendingCommission = 0;
        stakingToken.transfer(validator, commission);
        emit CommissionClaimed(validator, commission);
    }

    function updateReward(address _user) internal {
        Delegator storage user = delegators[_user];
        if (user.amountStaked == 0) {
            user.lastUpdated = block.timestamp;
            return;
        }

        uint256 timeDiff = block.timestamp - user.lastUpdated;
        if (timeDiff == 0) return;
        address validator = user.validator;

        (, uint256 commissionRate, bool exists) = validatorRegistry.getValidatorInfo(validator);
        uint256 totalReward = (timeDiff * rewardRate * user.amountStaked) / 1e18;
        uint256 commission = 0;

        if (exists) {
            commission = (totalReward * commissionRate) / 10000;
        }

        uint256 userReward = totalReward - commission;
        user.rewardDebt += userReward;

        if (exists) {
            validators[validator].pendingCommission += commission;
        }

        user.lastUpdated = block.timestamp;
    }

    function pendingReward(address _user) external view returns (uint256) {
        Delegator storage user = delegators[_user];
        if (user.amountStaked == 0) return user.rewardDebt;

        uint256 timeDiff = block.timestamp - user.lastUpdated;
        uint256 totalReward = (timeDiff * rewardRate * user.amountStaked) / 1e18;

        (, uint256 commissionRate, bool exists) = validatorRegistry.getValidatorInfo(user.validator);
        uint256 commission = exists ? (totalReward * commissionRate) / 10000 : 0;
        uint256 userReward = totalReward - commission;

        return user.rewardDebt + userReward;
    }

    function getStaked(address _user) external view returns (uint256) {
        return delegators[_user].amountStaked;
    }

    function getDelegation(address _user) external view returns (address validator, uint256 amount) {
        Delegator storage user = delegators[_user];
        return (user.validator, user.amountStaked);
    }

    function getTotalDelegated(address _validator) external view returns (uint256) {
        return validators[_validator].totalDelegated;
    }

    function getPendingCommission(address _validator) external view returns (uint256) {
        return validators[_validator].pendingCommission;
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    function setRegistryAddress(address _newRegistry) external onlyOwner {
        validatorRegistry = IValidatorRegistry(_newRegistry);
    }

    function emergencyWithdraw() external nonReentrant {
        Delegator storage user = delegators[msg.sender];
        uint256 amount = user.amountStaked;
        require(amount > 0, "Nothing to withdraw");

        address validator = user.validator;
        user.amountStaked = 0;
        user.rewardDebt = 0;
        user.validator = address(0);

        if (validators[validator].totalDelegated >= amount) {
            validators[validator].totalDelegated -= amount;
        } else {
            validators[validator].totalDelegated = 0;
        }

        if (totalStaked >= amount) {
            totalStaked -= amount;
        } else {
            totalStaked = 0;
        }

        if (validator == msg.sender && validatorRegistry.isValidator(msg.sender)) {
            try validatorRegistry.autoRemoveValidator(msg.sender) {} catch {}
        }

        stakingToken.transfer(msg.sender, amount);
        emit UndelegatedAll(msg.sender, validator, amount);
    }
}
