// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract SmartGridManagement is Ownable {
    struct SmartGrid {
        string gridId;
        uint startGenerationTime;
        uint lastGenerationTime;
        uint unitGenerated;
    }

    mapping(address => SmartGrid) public smartGrids;

    uint256 public timeInterval;
    uint256 public totalElectricityAvailable;

    event SmartGridRegistered(address indexed smartGridAddress, string gridId);
    event smartGridReadingSent(address indexed smartGridAddress, uint indexed startGenerationTime, uint indexed endGenerationTime, uint unitGenerated);
    

    constructor(uint _timeInSecond) {
        timeInterval = _timeInSecond;
    }

    function setTimeInterval(uint256 _timeInSeconds) public onlyOwner {
        timeInterval = _timeInSeconds;
    }

    function registerSmartGrid(address _smartGridAddress, string memory _gridId) external onlyOwner {
        require(bytes(_gridId).length > 0, "Grid ID cannot be empty");
        require(bytes(smartGrids[_smartGridAddress].gridId).length == 0, "Smart grid already registered");

        smartGrids[_smartGridAddress] = SmartGrid({
            gridId: _gridId,
            startGenerationTime: 0,
            lastGenerationTime: 0,
            unitGenerated: 0
        });

        emit SmartGridRegistered(_smartGridAddress, _gridId);
    }

    function sendInitialReadingBySmartGrid(
        address _smartGridAddress,
        string memory _gridId,
        uint _startGenerationTime,
        uint _lastGenerationTime,
        uint _unitGenerated
    ) external {
        SmartGrid storage sg = smartGrids[_smartGridAddress];
        require(keccak256(abi.encodePacked(sg.gridId)) == keccak256(abi.encodePacked(_gridId)), "Grid ID does not match");
        require(sg.lastGenerationTime == 0, "Called by Smart Grid for first time");

        sg.startGenerationTime = _startGenerationTime;
        sg.lastGenerationTime = _lastGenerationTime;
        sg.unitGenerated = _unitGenerated;
        totalElectricityAvailable += _unitGenerated;

        emit smartGridReadingSent(_smartGridAddress, _startGenerationTime,_lastGenerationTime, _unitGenerated);
    }

    function sendReadingBySmartGrid(
        address _smartGridAddress,
        string memory _gridId,
        uint _startGenerationTime,
        uint _lastGenerationTime,
        uint _unitGenerated
    ) external {
        SmartGrid storage sg = smartGrids[_smartGridAddress];
        require(keccak256(abi.encodePacked(sg.gridId)) == keccak256(abi.encodePacked(_gridId)), "Grid ID does not match");
        require(_lastGenerationTime >= sg.lastGenerationTime + timeInterval, "Reading too soon");

        sg.startGenerationTime = _startGenerationTime;
        sg.lastGenerationTime = _lastGenerationTime;
        sg.unitGenerated = _unitGenerated;
        totalElectricityAvailable += _unitGenerated;

        emit smartGridReadingSent(_smartGridAddress, _startGenerationTime,_lastGenerationTime, _unitGenerated);
    }
}
