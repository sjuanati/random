// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// info: proposals gets accepted when the % over the total shares is > 50.
// if proposal gets experied and didn't reach a 50%, it is rejected.

// TODO: insted of using IERC, add ERC20 to DAO and swap ETH by Gov tokens?
// TODO: enddate, and use OpenZeppelin time advance in tests
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO {
    enum Answer {Yes, No}
    enum Status {Open, Approved, Rejected}

    struct Proposal {
        string title;
        address author;
        uint256 proposalId;
        uint256 createdAt;
        uint256 votesYes;
        uint256 votesNo;
        Status status;
    }

    // next proposal identifier
    uint256 public nextProposalId;
    // total amount of shares in the DAO
    uint256 public totalShares;
    // minimum number of shares to create a proposal (100 governance tokens)
    uint256 public constant CREATE_PROPOSAL_MIN_SHARE = 100 * 10**18;
    // maximum number of days to vote
    uint256 public constant VOTING_PERIOD = 7 days;

    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal
    mapping(address => uint256) public shares; // participant => shares
    mapping(uint256 => mapping(address => bool)) public votes; // proposalId => participant => voted

    IERC20 public governanceToken;

    constructor(address _tokenAddress) {
        governanceToken = IERC20(_tokenAddress);
    }

    // deposit governance tokens
    function deposit(uint256 amount) external {
        require(amount > 0, "amount must be greater than 0");

        shares[msg.sender] += amount;
        totalShares += amount;
        governanceToken.transferFrom(msg.sender, address(this), amount);
    }

    // withdraw governance tokens
    // todo: reentrancy protection?
    function withdraw(uint256 amount) external {
        require(amount <= shares[msg.sender], "not enough shares");

        shares[msg.sender] -= amount;
        totalShares -= amount;
        governanceToken.transfer(msg.sender, amount);
    }

    function createProposal(string calldata title) external {
        require(
            shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE,
            "not enough shares to create proposal"
        );

        proposals[nextProposalId] = Proposal(
            title,
            msg.sender,
            nextProposalId,
            block.timestamp,
            0,
            0,
            Status.Open
        );
        nextProposalId += 1;
    }

    function vote(uint256 proposalId, Answer answer) external {
        require(shares[msg.sender] > 0, "not enough shares to vote");
        require(proposalId < nextProposalId, "proposal does not exist");

        Proposal storage proposal = proposals[proposalId];

        require(proposal.status == Status.Open, "proposal is closed");
        require(votes[proposalId][msg.sender] == false, "already voted");
        require(
            block.timestamp <= proposal.createdAt + VOTING_PERIOD,
            "voting period has ended"
        );

        if (answer == Answer.Yes) {
            proposal.votesYes += shares[msg.sender];
            if (((proposal.votesYes * 100) / totalShares) > 50) {
                proposal.status = Status.Approved;
            }
        } else {
            proposal.votesNo += shares[msg.sender];
            if (((proposal.votesNo * 100) / totalShares) > 50) {
                proposal.status = Status.Rejected;
            }
        }

        votes[proposalId][msg.sender] = true; 
    }
}
