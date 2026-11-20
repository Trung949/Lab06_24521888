// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24521888. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract SavingsClub_1888 {
    address public owner;
    mapping(address => uint256) public balances;
    bool private locked;
    mapping(address => uint256) public escrowed;
    uint256 public constant feeBps = 250;
    uint256 public nextRelease;

    event Deposited(address indexed who, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    modifier guarded() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function contribute() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function flush(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "flush failed");
    }

    function transferControl(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function depositSafe() external payable guarded {
        escrowed[msg.sender] += msg.value;
    }

    function claimSafe() external guarded {
        uint256 a = escrowed[msg.sender];
        escrowed[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }

    function previewFee(uint256 amount) public pure returns (uint256) {
        return amount * feeBps / 10000;
    }

    function vestStep() external onlyOwner {
        require(block.timestamp >= nextRelease, "locked");
        nextRelease = block.timestamp + 1 days;
        (bool ok, ) = payable(owner).call{value: address(this).balance / 10}("");
        require(ok, "release failed");
    }
}
