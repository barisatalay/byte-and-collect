// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * @title BARIS ATALAY
 * @dev Set & change owner 
 *
 * Note: Code that should be in the first line of methods that normal users access. require(emergency==false,"Operations canceled due to an emergency.");
 */
 contract ByteAndCollect is Context, Ownable{
    mapping(uint16 => mapping(uint16 => address)) public cellOwner;
    mapping(uint16 => mapping(uint16 => uint256)) public cellPrice;
    mapping(address => uint) private ownerInfo;
    uint256 private balance;                // It is where the cell balances are located.
    uint256 private balanceFee;             // It is the commission balances that the contract receives from the transactions made.
    uint256 private minCellCost;            // ...
    uint16 private maxCellSize;             // ...
    uint8 private cellPurchaseFeePercent;   // It is the rate that shows how much the new owner of the cell will pay compared to the previous owner of the cell.
    uint8 private contractFeePercent;       // It is the commission rate that the contract receives from the transactions made. It can be used for development and financing.
    bool private emergency;                 // It is used for the safety of users when an unexpected situation occurs.

    using SafeMath for uint;

    constructor(){
        minCellCost = 0;
        maxCellSize = 0;
        cellPurchaseFeePercent = 10;
        contractFeePercent = 10;
    }
    /// @notice     ...
    /// @param  _x  ...
    /// @param  _y  ...
    function attackCell(uint16 _x, uint16 _y) payable public{
        require(emergency==false,"Operations canceled due to an emergency.");
        require(_x>0&& _y>0 && _x <=maxCellSize && _y<=maxCellSize, "Selected cell is not valid.");
        require(cellOwner[_x][_y]!=_msgSender(),"You cannot attack your own cell.");
        require(doAttackMoreCell(), "You cannot attack anymore");
        require(minCellCost>0 && msg.value>=minCellCost, "Amount must be bigger than cell price");
        uint256 calculatedCellPrice = calculateNewCellPrice(cellPrice[_x][_y], cellPurchaseFeePercent);
        require(msg.value>=calculatedCellPrice, "Amout must be bigger than cell purchase price");

        // ..:: Gaming Fee ::..
        uint256 calculatedContractFee = calculateContractFee(calculatedCellPrice, contractFeePercent);
        balanceFee = balanceFee.add(calculatedContractFee);
        // ..:: Gaming Fee ::..

        // ..:: Decrease older owner's and increase new owner's cell count ::..
        if (ownerInfo[cellOwner[_x][_y]] > 0)
            ownerInfo[cellOwner[_x][_y]] = ownerInfo[cellOwner[_x][_y]].sub(1);
        ownerInfo[_msgSender()] = ownerInfo[_msgSender()].add(1);
        // ..:: Decrease older owner's and increase new owner's cell count ::..

        // ..:: Updating cell information ::..
        cellOwner[_x][_y] = _msgSender();
        cellPrice[_x][_y] = calculatedCellPrice;
        // ..:: Updating cell information ::..
    }
    /// @notice                 ...
    /// @param  _cellLastPrice  Purchased last price by user
    /// @param  _feePercent     New cell attack fee
    function calculateNewCellPrice(uint _cellLastPrice, uint8 _feePercent)private pure returns(uint){
        uint comission = _cellLastPrice.mul(_feePercent).div(100);
        return comission + _cellLastPrice;
    }
    /// @notice                 ...
    /// @param  _cellPrice      Calculated cell purchase price
    /// @param  _feePercent     Playing Fee percent
    function calculateContractFee(uint256 _cellPrice, uint8 _feePercent)private pure returns(uint256){
        require(_feePercent>0, "Game fee must be bigger than zero");
        return _cellPrice.mul(_feePercent).div(100);
    }
    /// @notice ...
    function doAttackMoreCell()public view returns(bool){
        return true;
    }
    /// @notice ...
    function resetCellBalances() onlyOwner public{
        for (uint16 i=1; i<maxCellSize; i++){
            for (uint16 j=1; j<maxCellSize; j++) {
                cellOwner[i][j] = address(this);
                cellPrice[i][j] = minCellCost;
            }
        }
    }
    /// @notice             ...
    /// @param  newPrice    ...
    function updateMinCellPrice(uint256 newPrice) onlyOwner public{
        minCellCost = newPrice;
    }
    /// @notice ...
    function getMinCellPrice() public view returns(uint256){
        return minCellCost;
    }
    /// @notice         ...
    /// @param  _x      ...
    /// @param  _y      ...
    function getCellNewPrice(uint16 _x, uint16 _y) public view returns(uint256){
        return calculateNewCellPrice(cellPrice[_x][_y], cellPurchaseFeePercent);
    }
    /// @notice         ...
    /// @param  _x      ...
    /// @param  _y      ...
    function getCellLastPrice(uint16 _x, uint16 _y) public view returns(uint256){
        return cellPrice[_x][_y];
    }
    /// @notice ...
    function updateMaxCellSize(uint16 value) onlyOwner public {
        maxCellSize = value;
    }
    /// @notice ...
    function getMaxCellSize() public view returns(uint16) {
        return maxCellSize;
    }
    /// @notice ...
    function getDepositBalance() public view returns(uint256){
        return balance;
    }

    /// @notice It is used for administrators to load balance.
    function deposit() onlyOwner public payable {
        require(msg.value>0,"There is balance zero");
        balance = balance.add(msg.value);
    }
    /// @notice It is used for managers to withdraw the project balance.
    function withdraw() onlyOwner public {
        require(_msgSender() != address(0), "Withdraw address not specified!");
        require(balance>0, "There is balance zero");
        uint256 amount = balance;
        balance = 0;
        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "Withdraw failed");
    }
 }