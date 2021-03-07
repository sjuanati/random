// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/*
    Can create different proposals
    Each proposal has a target number of votes
    Once the target is reached, the winner is decided
*/

contract Ballot {
    enum Decision {NONE, TRUE, FALSE, DRAW}

    struct Proposal {
        string title;
        uint256 totalVotes;
        uint256 goalVotes;
        bool active;
        Decision decision;
    }

    struct Vote {
        uint256 proposal;
        bool answer;
    }

    Proposal[] public proposals;

    // Voter -> Vote
    mapping(address => Vote[]) public userVotes;

    // Proposal ID -> Answer
    mapping(uint256 => bool[]) public proposalVotes;

    function propose(string memory _title) external {
        //todo: check if proposal already exists
        proposals.push(Proposal(_title, 0, 5, true, Decision.NONE));
    }

    function vote(uint256 _proposal, bool _answer) external {
        Proposal storage proposal = proposals[_proposal];
        require(proposal.active == true, "ballot is not active");

        for (uint256 i = 0; i < userVotes[msg.sender].length; i++) {
            if (userVotes[msg.sender][i].proposal == _proposal) {
                revert("user already voted");
            }
        }

        userVotes[msg.sender].push(Vote(_proposal, _answer));
        proposal.totalVotes += 1;

        proposalVotes[_proposal].push(_answer);
    }

    function close(uint256 _proposal) external {
        Proposal storage proposal = proposals[_proposal];
        require(
            proposal.totalVotes >= proposal.goalVotes,
            "goal votes not reached yet"
        );

        uint256 countTrue = 0;
        uint256 countFalse = 0;
        for (uint256 i = 0; i < proposalVotes[_proposal].length; i++) {
            (proposalVotes[_proposal][i] == true)
                ? countTrue += 1
                : countFalse += 1;
        }

        if (countTrue > countFalse) {
            proposal.decision = Decision.TRUE;
        } else if (countTrue < countFalse) {
            proposal.decision = Decision.FALSE;
        } else {
            proposal.decision = Decision.DRAW;
        }

        proposal.active = false;
    }
}
