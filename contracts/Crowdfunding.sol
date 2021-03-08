// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract CrowdFunding {
    enum Status {ACTIVE, CLOSED}

    struct Funder {
        address funder;
        uint256 amount;
    }

    struct Campaign {
        address beneficiary;
        uint256 fundingGoal;
        uint256 numFunders;
        uint256 amount;
        Status status;
        mapping(uint256 => Funder) funders;
    }

    uint256 numCampaigns;
    mapping(uint256 => Campaign) public campaigns;

    function newCampaign(address _beneficiary, uint256 _fundingGoal) external {
        // mapping inside a struct can only be assigned in storage
        // Campaign(beneficiary, goal, 0, 0) creates a memory-struct
        Campaign storage c = campaigns[numCampaigns];
        c.beneficiary = _beneficiary;
        c.fundingGoal = _fundingGoal;
        c.status = Status.ACTIVE;
        numCampaigns += 1;
    }

    function contribute(uint256 numCampaign) external payable {
        require(msg.value > 0, "contribution must be higher than 0");
        Campaign storage c = campaigns[numCampaign];
        require(c.status == Status.ACTIVE, "campaign is not active");
        c.amount += msg.value;
        c.numFunders += 1;
        c.funders[c.numFunders] = Funder(msg.sender, msg.value);
    }

    function closeCampaign(uint256 numCampaign) external {
        Campaign storage c = campaigns[numCampaign];
        require(c.status == Status.ACTIVE, "campaign is already closed");
        if (c.amount >= c.fundingGoal) {
            c.status = Status.CLOSED;
            payable(c.beneficiary).transfer(c.amount);
        } else {
            revert("funding goal not reached yet");
        }
    }
}
