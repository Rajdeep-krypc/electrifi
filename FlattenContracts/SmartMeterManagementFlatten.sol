// Sources flattened with hardhat v2.22.11 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/Context.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/Ownable.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/SmartGridManagement.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

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


// File contracts/SmartMeterManagement.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

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
