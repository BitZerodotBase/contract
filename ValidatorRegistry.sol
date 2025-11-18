// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBitStake {
    function getStaked(address _user) external view returns (uint256);
}

interface IBitZeroNodes {
    function activateValidatorNode(address _validatorOwner) external;
    function deactivateValidatorNode(address _validatorOwner) external;
}

contract ValidatorRegistry is Ownable {
    struct Validator {
        string name;
        uint256 commissionRate;
        bool exists;
    }

    mapping(address => Validator) public validators;
    address[] public validatorList;
    
    address public bitStakeAddress;
    
    address public bitZeroNodesAddress;

    event ValidatorRegistered(address indexed operator, string name, uint256 commissionRate);
    event ValidatorRemoved(address indexed operator);
    event CommissionUpdated(address indexed operator, uint256 newRate);

    constructor() Ownable(msg.sender) {}
    
    function setBitStakeAddress(address _address) external onlyOwner {
        bitStakeAddress = _address;
    }

    function setBitZeroNodesAddress(address _address) external onlyOwner {
        bitZeroNodesAddress = _address;
    }

    function registerValidator(string memory _name, uint256 _commissionRate) external {
        address _operator = msg.sender;
        require(_operator != address(0), "Invalid operator address"); 
        require(_commissionRate <= 10000, "Commission cannot exceed 100%"); 
        require(bitStakeAddress != address(0), "Stake contract address not set"); 
        
        uint256 userStake = IBitStake(bitStakeAddress).getStaked(_operator);
        require(
            _operator == owner() || userStake >= 10000 * 10**18, 
            "Must be owner or have at least 10,000 BIT staked"
        ); 
        
        Validator storage validator = validators[_operator];
        if (!validator.exists) {
            validator.exists = true;
            validatorList.push(_operator); 
        }

        validator.name = _name;
        validator.commissionRate = _commissionRate;

        if (bitZeroNodesAddress != address(0)) {
            IBitZeroNodes(bitZeroNodesAddress).activateValidatorNode(_operator);
        }

        emit ValidatorRegistered(_operator, _name, _commissionRate);
    }

    function removeValidator(address _operator) external onlyOwner {
        require(validators[_operator].exists, "Validator not found"); 
        validators[_operator].exists = false;

        if (bitZeroNodesAddress != address(0)) {
            IBitZeroNodes(bitZeroNodesAddress).deactivateValidatorNode(_operator);
        }

        emit ValidatorRemoved(_operator);
    }
    
    function autoRemoveValidator(address _operator) external {
        require(msg.sender == bitStakeAddress, "Only callable by stake contract"); 
        require(validators[_operator].exists, "Validator not found"); 
        
        validators[_operator].exists = false;

        if (bitZeroNodesAddress != address(0)) {
            IBitZeroNodes(bitZeroNodesAddress).deactivateValidatorNode(_operator);
        }

        emit ValidatorRemoved(_operator);
    }

    function updateCommission(address _operator, uint256 _newRate) external onlyOwner {
        require(validators[_operator].exists, "Validator not found");
        require(_newRate <= 10000, "Commission cannot exceed 100%"); 
        
        validators[_operator].commissionRate = _newRate;
        emit CommissionUpdated(_operator, _newRate);
    }

    function getValidatorInfo(address _operator) external view returns (string memory name, uint256 commissionRate, bool exists) {
        Validator storage v = validators[_operator];
        return (v.name, v.commissionRate, v.exists); 
    }

    function getValidators() external view returns (address[] memory) {
        return validatorList;
    }

    function isValidator(address _operator) external view returns (bool) {
        return validators[_operator].exists;
    }
}