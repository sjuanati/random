// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Escrow {
    // Enum to handle all possible states
    enum Status {ORDER, COMPLETE, COMPLAIN}
    
    // Struct to handle Order fields
    struct Order {
        address buyer;
        uint256 ordered;
        Status status;
    }
    
    // Struct to handle Item fields
    struct Item {
        address seller;
        uint256 price;
        uint256 amount;
        Order[] orders;
    }

    // Mapping between item name and its data
    mapping(string => Item) public items;
    
    /**
     * @notice  Offer items for sale
     * @param   _name The name of the item
     * @param   _price The price of the item
     * @param   _amount The amount of items to be sold
     */
    function offer(string memory _name, uint256 _price, uint256 _amount) external {
        require(_amount > 0 && _price > 0, 'amount & price must be higher than 0');
        if (items[_name].seller == address(0)) {
            // Item does not exist
            items[_name].seller = msg.sender;
            items[_name].price = _price;
            items[_name].amount = _amount;
            //items[_name] = Item(msg.sender, _price, _amount, new Order[](0));
        } else {
            // Item exists
            items[_name].price = _price;
            items[_name].amount += _amount;
        }
    }
    
    /**
     * @notice  Order items offered by Sellers
     *          The Buyer places a payment into escrow for that item amount
     * @dev     Reverts if the item does not exist, amount is not available 
     *          or the status is different than <OFFER>
     * @param   _name The name of the item
     * @param   _amount The amount of the item to be ordered
     */
    function order(string memory _name, uint256 _amount) payable external {
        Item storage item = items[_name];
        require(item.seller != address(0), 'Item does not exist');
        require(item.amount >= _amount, 'Amount not available');
        require(_amount * item.price == msg.value, 'Price sent is not equal to product price');
        item.orders.push(Order(msg.sender, _amount, Status.ORDER));
        item.amount -= _amount;
    }
    
    /**
     * @notice  Complete orders once they have received their purchase
     *          The payment is paid from escrow to the Seller
     * @dev     Reverts if the item does not exist, is not ordered by this buyer
     *          or the status is different than <Offer>
     * @param   _name The name of the item
     */
    function complete(string memory _name) external {
        Item storage item = items[_name];
        bool found = false;
        for (uint256 i=0; i<item.orders.length; i++) {
            if (item.orders[i].buyer == msg.sender && item.orders[i].status == Status.ORDER) {
                item.orders[i].status = Status.COMPLETE;
                payable(item.seller).transfer(item.orders[i].ordered * item.price);
                found = true;
                break;
            }
        }
        if (!found) revert('Item not ordered or in different status than ORDER');
    }
    
    /**
     * @notice  Complain about orders if they never receive their purchase
     *          The payment is refunded from escrow to the Buyer
     * @dev     Reverts if the item is not ordered by this buyer
     *          or the status is different than <Offer>
     * @param   _name Tne name of the item
     */
    function complain(string memory _name) external {
        Item storage item = items[_name];
        bool found = false;
        for (uint256 i=0; i<item.orders.length; i++) {
            if (item.orders[i].buyer == msg.sender && item.orders[i].status == Status.ORDER) {
                item.orders[i].status = Status.COMPLAIN;
                payable(item.orders[i].buyer).transfer(item.orders[i].ordered * item.price);
                found = true;
                break;
            }
        }
        if (!found) revert('Item not ordered or in different status than ORDER');
    }
    
    /**
     * @notice  Get the order amount & status
     * @param   _name Tne name of the item
     * @return  _ordered The order amount
     *          _status The order status
     */
    function getOrder(string memory _name) external view returns (uint256 _ordered, Status _status) {
        for (uint256 i=0; i<items[_name].orders.length; i++) {
            if (items[_name].orders[i].buyer == msg.sender) {
                _ordered = items[_name].orders[i].ordered;
                _status = items[_name].orders[i].status;
                break;
            }
        }
    }
    
    /**
     * @param   _buyer The User address to be checked
     * @return  Total User's balance
     */
    function getBuyerBalance(address _buyer) external view returns(uint256) {
        return address(_buyer).balance;
    }
    
    /**
     * @notice  Retrieve escrow balance
     * @return  Total amount held in escrow
     */
    function getContractBalance() external view returns(uint256) {
        return address(this).balance;
    }
}