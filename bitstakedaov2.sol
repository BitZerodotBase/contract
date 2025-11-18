// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBitStake {
    function getStaked(address _user) external view returns (uint256);
}

contract BitStakeDao {
    enum VoteOption { Yes, No, Abstain, NoWithVeto }

    struct Proposal {
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 noWithVetoVotes;
        uint256 voteEnd;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    IBitStake public bitStake;
    Proposal[] public proposals;
    uint256 public proposalCount;
    
    uint256 public constant VOTING_PERIOD = 7 days;

    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 id, address voter, VoteOption voteOption, uint256 voteWeight);

    constructor(address _bitStakeAddress) {
        bitStake = IBitStake(_bitStakeAddress);
    }

    function createProposal(string memory _description) external {
        require(bitStake.getStaked(msg.sender) >= 100000 * 10**18, "Must have at least 100,000 BIT delegated");
        
        proposals.push();
        Proposal storage newProposal = proposals[proposals.length - 1];
        
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.voteEnd = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalCount, msg.sender, _description);
        proposalCount++;
    }

    function vote(uint256 _proposalId, VoteOption _voteOption) external {
        require(_proposalId < proposalCount, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.voteEnd, "Voting period has ended"); 
        require(!proposal.hasVoted[msg.sender], "Already voted");
        uint256 stakedAmount = bitStake.getStaked(msg.sender);
        require(stakedAmount > 0, "Must be a delegator to vote");

        if (_voteOption == VoteOption.Yes) {
            proposal.yesVotes += stakedAmount;
        } else if (_voteOption == VoteOption.No) {
            proposal.noVotes += stakedAmount;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal.abstainVotes += stakedAmount;
        } else if (_voteOption == VoteOption.NoWithVeto) {
            proposal.noWithVetoVotes += stakedAmount;
        }

        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _voteOption, stakedAmount);
    }

    function getProposal(uint256 _proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 abstainVotes,
        uint256 noWithVetoVotes,
        bool executed,
        uint256 voteEnd
    ) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.abstainVotes,
            proposal.noWithVetoVotes,
            proposal.executed,
            proposal.voteEnd
        );
    }

    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        return proposals[_proposalId].hasVoted[_voter];
    }
}