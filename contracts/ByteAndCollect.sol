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
contract ByteAndCollect is Context, Ownable {
    using SafeMath for uint256;
    mapping(uint16 => mapping(uint16 => address)) public cellOwner;
    // [x][y]
    mapping(uint16 => mapping(uint16 => uint256)) public cellPrice;
    mapping(address => uint256) private ownerInfo;
    mapping(bytes => bool) private mutexInfo;
    uint256 private balance; // It is where the cell balances are located.
    uint256 private balanceFee; // It is the commission balances that the contract receives from the transactions made.
    uint256 private minCellCost; // ...
    uint16 private maxCellSize; // ...
    uint8 private cellPurchaseFeePercent; // It is the rate that shows how much the new owner of the cell will pay compared to the previous owner of the cell.
    uint8 private contractFeePercent; // It is the commission rate that the contract receives from the transactions made. It can be used for development and financing.
    bool private emergency; // It is used for the safety of users when an unexpected situation occurs.

    event CellConquered(
        uint16 indexed x,
        uint16 indexed y,
        address indexed newOwner,
        uint256 attackPrice
    );
    event CellUnderAttack(
        uint16 indexed x,
        uint16 indexed y,
        address indexed newOwner,
        address oldOwner
    );

    struct CellInfo {
        uint16 x;
        uint16 y;
        uint256 price;
        uint256 newPrice;
    }

    constructor() {
        minCellCost = 0;
        maxCellSize = 0;
        cellPurchaseFeePercent = 10;
        contractFeePercent = 10;
    }

    /// @notice     Bu metod ile seçilen hücreyi kullanıcı satın alır(saldırır)
    /// @param  _x  Horizontal position
    /// @param  _y  Vertical position
    function attackCell(uint16 _x, uint16 _y)
        public
        payable
        checkLock(_x, _y)
        returns (uint256)
    {
        require(emergency == false, "Operations canceled due to an emergency.");
        require(
            _x >= 0 && _y >= 0 && _x <= maxCellSize && _y <= maxCellSize,
            "Selected cell is not valid."
        );
        require(
            cellOwner[_x][_y] != _msgSender(),
            "You cannot attack your own cell."
        );
        require(doAttackMoreCell(), "You cannot attack anymore");
        require(
            minCellCost > 0 && msg.value >= minCellCost,
            "Amount must be bigger than cell price"
        );
        uint256 calculatedCellPrice = calculateNewCellPrice(
            cellPrice[_x][_y],
            cellPurchaseFeePercent
        );
        require(
            msg.value >= calculatedCellPrice,
            "Amout must be bigger than cell purchase price"
        );

        emit CellUnderAttack(_x, _y, _msgSender(), cellOwner[_x][_y]);
        // ..:: Gaming Fee ::..
        uint256 calculatedContractFee = calculateContractFee(
            calculatedCellPrice,
            contractFeePercent
        );
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

        emit CellConquered(_x, _y, _msgSender(), calculatedCellPrice);
        return calculatedCellPrice;
    }

    /// @notice                 Calculates the commission share for the development of the contract and the investments it will make.
    /// @param  _cellLastPrice  Purchased last price by user
    /// @param  _feePercent     New cell attack fee
    function calculateNewCellPrice(uint256 _cellLastPrice, uint8 _feePercent)
        private
        pure
        returns (uint256)
    {
        uint256 comission = _cellLastPrice.mul(_feePercent).div(100);
        return comission + _cellLastPrice;
    }

    /// @notice
    /// @param  _cellPrice      Calculated cell purchase price
    /// @param  _feePercent     Playing Fee percent
    function calculateContractFee(uint256 _cellPrice, uint8 _feePercent)
        private
        pure
        returns (uint256)
    {
        require(_feePercent > 0, "Game fee must be bigger than zero");
        return _cellPrice.mul(_feePercent).div(100);
    }

    /// @notice ...
    function doAttackMoreCell() public view returns (bool) {
        return true;
    }

    /// @notice ...
    function resetCellBalances() public onlyOwner {
        for (uint16 i = 0; i < maxCellSize; i++) {
            for (uint16 j = 0; j < maxCellSize; j++) {
                cellOwner[i][j] = address(this);
                cellPrice[i][j] = minCellCost;
            }
        }
    }

    /// @notice             Updates empty(non-owner) cell price
    /// @param  _newPrice    New price of empty(non-owner) cell
    function updateMinCellPrice(uint256 _newPrice) public onlyOwner {
        minCellCost = _newPrice;
    }

    /// @notice Shows empty(non-owner) cell price
    function getMinCellPrice() public view returns (uint256) {
        return minCellCost;
    }

    /// @notice         Shows purchase(attack) cost of the selected cell
    /// @param  _x      Horizontal position
    /// @param  _y      Vertical position
    function getCellNewPrice(uint16 _x, uint16 _y)
        public
        view
        returns (uint256)
    {
        return calculateNewCellPrice(cellPrice[_x][_y], cellPurchaseFeePercent);
    }

    /// @notice         Shows selected cell's last purchased(attacked) price
    /// @param  _x      Horizontal position
    /// @param  _y      Vertical position
    function getCellLastPrice(uint16 _x, uint16 _y)
        public
        view
        returns (uint256)
    {
        return cellPrice[_x][_y];
    }

    function getCellBatch() public view returns (CellInfo[][] memory response) {
        response = new CellInfo[][](maxCellSize);

        for (uint16 _x = 0; _x < maxCellSize; _x++) {
            CellInfo[] memory cellData = new CellInfo[](maxCellSize);
            for (uint16 _y = 0; _y < maxCellSize; _y++) {
                cellData[_y] = CellInfo({
                    x: _x,
                    y: _y,
                    price: cellPrice[_x][_y],
                    newPrice: getCellNewPrice(_x, _y)
                });
                /*response[_x][_y] = CellInfo({
                    x: _x,
                    y: _y,
                    price: cellPrice[_x][_y],
                    newPrice: getCellNewPrice(_x, _y)
                });
                */
                // cellOwner[i][j] = address(this);
                // cellPrice[i][j] = minCellCost;
            }
            response[_x] = cellData;
        }
    }

    /// @notice         The size of the playground is updated here.
    /// @param _value   New maximum cell size.
    function updateMaxCellSize(uint16 _value) public onlyOwner {
        maxCellSize = _value;
    }

    /// @notice Maximum cell size. E.g.: 10x10
    function getMaxCellSize() public view returns (uint16) {
        return maxCellSize;
    }

    /// @notice Shows contract deposit balance
    function getDepositBalance() public view returns (uint256) {
        return balance;
    }

    /// @notice It is used for administrators to load balance.
    function deposit() public payable onlyOwner {
        require(msg.value > 0, "There is balance zero");
        balance = balance.add(msg.value);
    }

    /// @notice It is used for managers to withdraw the project balance.
    function withdraw() public onlyOwner {
        require(_msgSender() != address(0), "Withdraw address not specified!");
        require(balance > 0, "There is balance zero");
        uint256 amount = balance;
        balance = 0;
        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "Withdraw failed");
    }

    /// @notice ...
    function hashCell(uint16 _x, uint16 _y)
        private
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), _x)
            mstore(add(b, 16), _y)
            mstore(b, 32)
        }
    }

    //TODO Will calculate gas fee
    modifier checkLock(uint16 _x, uint16 _y) {
        bytes memory hashed = hashCell(_x, _y);
        require(
            mutexInfo[hashed] == false,
            "The cell is already under attack. Please wait."
        );
        mutexInfo[hashed] = true;
        _;
        mutexInfo[hashed] = false;
    }
}
