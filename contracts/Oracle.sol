// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Oracle {
    struct Data {
        uint256 date;
        string value; // TODO: number, decimals, etc.
    }
    address public admin;
    mapping(address => bool) public reporters; // reporter address => isActive
    mapping(uint256 => Data) public data; // data id => Data

    constructor(address _admin) {
        admin = _admin;
    }

    // updates the status of a reporter to false (not valid) or true (valid)
    function updateReporter(address reporter, bool isReporter) external {
        require(msg.sender == admin, "only admin");
        reporters[reporter] = isReporter;
    }

    function updateData(uint256 id, string calldata value) external {
        require(reporters[msg.sender] == true, "only valid reporter");
        data[id] = Data(block.timestamp, value);
    }

    /**
     * @dev xxxx
     * @param id The data identifier
     * @return isValid True if there is valid result; false otherwise
     * @return date Last creation date
     * @return value
     */
    function getData(uint256 id)
        external
        view
        returns (
            bool isValid,
            uint256 date,
            string memory value
        )
    {
        if (data[id].date == 0) {
            return (false, 0, "");
        } else {
            return (true, data[id].date, data[id].value);
        }
    }
}

contract Consumer {
    Oracle oracle;

    constructor(address _oracle) {
        oracle = Oracle(_oracle);
    }

    function foo(uint256 _id) external view {
        (bool isValid, uint256 date, string memory value) = oracle.getData(_id);
        require(isValid == true, 'data not valid');
        require(date >= block.timestamp - 2 hours, 'data too old');
        // do stuff
    }
}
