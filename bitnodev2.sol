// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBitStake {
    function getStaked(address _user) external view returns (uint256);
    function claimCommission() external;
    function getTotalDelegated(address _validator) external view returns (uint256);
}

contract BitZeroNodes is Ownable, ReentrancyGuard {

    IERC20 public immutable bitToken;
    IBitStake public bitStake;
    
    address public validatorRegistryAddress;
    uint256 public constant NODE_STAKE_AMOUNT = 10000 * 1e18;
    uint256 public constant INITIAL_REWARD_RATE_PER_MINUTE = 60 * 1e18;
    uint256 public constant HALVING_INTERVAL = 210_000 * 1e18;
    
    uint256 public totalRewardsDistributed;
    uint256 public totalNodes;
    
    struct Node {
        address owner;
        uint256 activationTime;
        uint256 lastClaimTime;
        bool exists;
    }

    mapping(address => Node) public nodes;
    
    event NodeActivated(address indexed user, uint256 time);
    event NodeDeactivated(address indexed user, uint256 time);
    event RewardsClaimed(address indexed user, uint256 amount);
    event HalvingOccurred(uint256 newEra);
    event CommissionClaimAttempted(address indexed user, bool success);

    constructor(
        address _bitTokenAddress, 
        address _bitStakeAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        require(_bitTokenAddress != address(0), "Invalid token address");
        require(_bitStakeAddress != address(0), "Invalid BitStake address");

        bitToken = IERC20(_bitTokenAddress);
        bitStake = IBitStake(_bitStakeAddress);
    }

    function claimRewards() external nonReentrant {
        Node storage node = nodes[msg.sender];
        require(node.exists, "No active node"); 

        uint256 pendingRewards = calculatePendingRewards(msg.sender);
        
        bool commissionClaimed = false;
        try bitStake.claimCommission() {
            commissionClaimed = true;
            emit CommissionClaimAttempted(msg.sender, true);
        } catch {
            emit CommissionClaimAttempted(msg.sender, false);
        }

        require(pendingRewards > 0 || commissionClaimed, "No rewards or commission to claim");
        
        if (pendingRewards > 0) {
            node.lastClaimTime = block.timestamp;
            uint256 eraBefore = getHalvingEra(); 
            totalRewardsDistributed += pendingRewards;
            uint256 eraAfter = getHalvingEra();

            _safeTransfer(msg.sender, pendingRewards, "Reward transfer failed");

            emit RewardsClaimed(msg.sender, pendingRewards);
            if (eraAfter > eraBefore) { 
                emit HalvingOccurred(eraAfter);
            }
        }
    }

    function activateValidatorNode(address _validatorOwner) external nonReentrant {
        require(msg.sender == validatorRegistryAddress, "Only Validator Registry");
        require(!nodes[_validatorOwner].exists, "Node already active");

        nodes[_validatorOwner] = Node({
            owner: _validatorOwner,
            activationTime: block.timestamp,
            lastClaimTime: block.timestamp,
            exists: true
        });
        
        totalNodes++;
        emit NodeActivated(_validatorOwner, block.timestamp);
    }

    function deactivateValidatorNode(address _validatorOwner) external nonReentrant {
        require(msg.sender == validatorRegistryAddress, "Only Validator Registry");
        Node storage node = nodes[_validatorOwner];
        require(node.exists, "No active node");

        uint256 pendingRewards = calculatePendingRewards(_validatorOwner);

        delete nodes[_validatorOwner];
        totalNodes--;
        
        if (pendingRewards > 0) { 
            uint256 eraBefore = getHalvingEra();
            totalRewardsDistributed += pendingRewards; 
            uint256 eraAfter = getHalvingEra();
            _safeTransfer(_validatorOwner, pendingRewards, "Reward reward failed");
            
            if (eraAfter > eraBefore) { 
                emit HalvingOccurred(eraAfter);
            }
        }

        emit NodeDeactivated(_validatorOwner, block.timestamp);
    }
    
    function setValidatorRegistryAddress(address _address) external onlyOwner {
        validatorRegistryAddress = _address;
    }

    function getHalvingEra() public view returns (uint256) {
        return totalRewardsDistributed / HALVING_INTERVAL;
    }
    
    function getCurrentRewardRatePerMinute() public view returns (uint256) {
        uint256 halvingEra = getHalvingEra();
        if (halvingEra >= 64) { return 0; } 
        return INITIAL_REWARD_RATE_PER_MINUTE >> halvingEra;
    }
    
    function calculatePendingRewards(address _user) public view returns (uint256) {
        Node memory node = nodes[_user];
        if (!node.exists) { return 0; } 

        uint256 totalDelegated = bitStake.getTotalDelegated(_user);
        uint256 validatorOwnStake = bitStake.getStaked(_user);

        if (totalDelegated <= validatorOwnStake) {
            return 0; 
        }

        uint256 timeElapsedInSeconds = block.timestamp - node.lastClaimTime;
        uint256 timeElapsedInMinutes = timeElapsedInSeconds / 60; 
        uint256 currentRatePerMinute = getCurrentRewardRatePerMinute();
        
        return timeElapsedInMinutes * currentRatePerMinute;
    }
    
    function fundRewardPool(uint256 _amount) external onlyOwner {
        bool success = bitToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Funding failed"); 
    }
    
    function rescueMistakenERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(bitToken), "Cannot withdraw $BIT token");
        IERC20(_tokenAddress).transfer(owner(), _amount); 
    }
    
    function _safeTransfer(address _to, uint256 _amount, string memory _errorMessage) internal {
        uint256 balance = bitToken.balanceOf(address(this));
        require(balance >= _amount, "Insufficient contract balance"); 
        bool success = bitToken.transfer(_to, _amount);
        require(success, _errorMessage);
    }
}