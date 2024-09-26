// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmartGridManagement.sol";

interface IEnergyToken{
    function mint(address to, uint256 amount) external;
}

contract SmartMeterManagement is SmartGridManagement {

    IEnergyToken public energyToken;

    uint256 tokensPerKWh;

    struct SmartMeter {
        string meterId;
        uint startConsumptionTime;
        uint lastConsumptionTime;
        uint unitConsumed;
    }

    mapping(address => SmartMeter) public smartMeters;

    event setEnergyToken(IEnergyToken indexed energyTokencontract);
    event SmartMeterRegistered(address indexed smartMeterAddress, string meterId);
    event SmartMeterReadingSent(address indexed smartMeterAddress, uint indexed startConsumptionTime, uint indexed lastConsumptionTime, uint unitConsumed);
   
    constructor(uint _timeInSecond, uint _tokensPerKWh) SmartGridManagement(_timeInSecond) {
        setEnergyTokensPerKWh(_tokensPerKWh);
    }

    function setEnergyERC20Token(IEnergyToken _energyToken) public onlyOwner{
        energyToken = _energyToken;
        emit setEnergyToken(_energyToken);
    }

    function setEnergyTokensPerKWh(uint256 _tokensPerKWh) public onlyOwner{
        tokensPerKWh = _tokensPerKWh;
    }

    function registerSmartMeter(address _smartMeterAddress, string memory _meterId) external onlyOwner {
        require(bytes(_meterId).length > 0, "Meter ID cannot be empty");
        require(bytes(smartMeters[_smartMeterAddress].meterId).length == 0, "Smart meter already registered");

        smartMeters[_smartMeterAddress] = SmartMeter({
            meterId: _meterId,
            startConsumptionTime: 0, // Initialize to zero or set later
            lastConsumptionTime: 0,
            unitConsumed: 0
        });

        emit SmartMeterRegistered(_smartMeterAddress, _meterId);
    }

    function sendInitialReadingBySmartMeter(
        address _smartMeterAddress,
        string memory _meterId,
        uint _startConsumptionTime,
        uint _lastConsumptionTime,
        uint _unitConsumed
    ) external {
        SmartMeter storage sm = smartMeters[_smartMeterAddress];
        require(keccak256(abi.encodePacked(sm.meterId)) == keccak256(abi.encodePacked(_meterId)), "Meter ID does not match");
        require(totalElectricityAvailable >= _unitConsumed, "Can't consume more than total");
        require(sm.lastConsumptionTime == 0, "Called by Smart meter for the first time");

        sm.startConsumptionTime = _startConsumptionTime;
        sm.lastConsumptionTime = _lastConsumptionTime;
        sm.unitConsumed += _unitConsumed;
        totalElectricityAvailable -= _unitConsumed;

        uint tokensToMint = calculateTokens(_unitConsumed);

        energyToken.mint(_smartMeterAddress, tokensToMint);

        emit SmartMeterReadingSent(_smartMeterAddress, _startConsumptionTime, _lastConsumptionTime, _unitConsumed);
    }

    function sendReadingBySmartMeter(
        address _smartMeterAddress,
        string memory _meterId,
        uint _startConsumptionTime,
        uint _lastConsumptionTime,
        uint _unitConsumed
    ) external {
        SmartMeter storage sm = smartMeters[_smartMeterAddress];
        require(keccak256(abi.encodePacked(sm.meterId)) == keccak256(abi.encodePacked(_meterId)), "Meter ID does not match");
        require(_lastConsumptionTime >= sm.lastConsumptionTime + timeInterval, "Reading too soon");
        require(totalElectricityAvailable >= _unitConsumed, "Can't consume more than total");

        sm.unitConsumed += _unitConsumed;
        sm.lastConsumptionTime = _lastConsumptionTime;
        totalElectricityAvailable -= _unitConsumed;

        uint tokensToMint = calculateTokens(_unitConsumed);

        energyToken.mint(_smartMeterAddress, tokensToMint);

        emit SmartMeterReadingSent(_smartMeterAddress, _startConsumptionTime, _lastConsumptionTime, _unitConsumed);
    }

    function calculateTokens(uint256 _energyUsedInKWh) public view returns(uint256 tokensToMint){
        tokensToMint = _energyUsedInKWh * tokensPerKWh;
    }
}







