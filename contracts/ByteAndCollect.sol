// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * @title BARIS ATALAY
 * @dev Set & change owner 
 */
 contract ByteAndCollect is Context, Ownable{
    mapping(uint16 => mapping(uint16 => address)) public cellOwner;
    mapping(uint16 => mapping(uint16 => uint256)) public cellPrice;
    mapping(address => uint) private ownerInfo;
    uint256 collectedFee;
    uint256 minCellCost;
    uint16 private maxCellSize;
    uint8 cellPurchaseFeePercent;
    uint8 contractFeePercent;
    
    using SafeMath for uint;

    constructor(){
        minCellCost = 0;
        maxCellSize = 10;
        cellPurchaseFeePercent = 10;
        contractFeePercent = 10;
    }
    /// @notice     ...
    /// @param  _x  ...
    /// @param  _y  ...
    function attackCell(uint16 _x, uint16 _y) payable public{
        require(_x>0&& _y>0 && _x <=maxCellSize && _y<=maxCellSize, "Selected cell is not valid.");
        require(cellOwner[_x][_y]!=_msgSender(),"You cannot attack your own cell.");
        require(doAttackMoreCell(), "You cannot attack anymore");
        require(minCellCost>0 && msg.value>=minCellCost, "Amount must be bigger than cell price");
        uint256 calculatedCellPrice = calculateNewCellPrice(cellPrice[_x][_y], cellPurchaseFeePercent);
        require(msg.value>=calculatedCellPrice, "Amout must be bigger than cell purchase price");

        // ..:: Gaming Fee ::..
        uint256 calculatedContractFee = calculateContractFee(calculatedCellPrice, contractFeePercent);
        collectedFee = collectedFee.add(calculatedContractFee);
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

    function doAttackMoreCell()public view returns(bool){
        return true;
    }

    function resetCellBalances() onlyOwner public{
        for (uint16 i=1; i<maxCellSize; i++){
            for (uint16 j=1; j<maxCellSize; j++) {
                cellOwner[i][j] = address(this);
                cellPrice[i][j] = minCellCost;
            }
        }
    }

    function updateMinCellPrice(uint256 newPrice) onlyOwner public{
        minCellCost = newPrice;
    }

    function getCellNewPrice(uint16 _x, uint16 _y) public view returns(uint256){
        return calculateNewCellPrice(cellPrice[_x][_y], cellPurchaseFeePercent);
    }

    function getCellLastPrice(uint16 _x, uint16 _y) public view returns(uint256){
        return cellPrice[_x][_y];
    }

    function updateMaxCellSize(uint16 value) onlyOwner public {
        maxCellSize = value;
    }

    function getMaxCellSize() public view returns(uint16) {
        return maxCellSize;
    }
 }