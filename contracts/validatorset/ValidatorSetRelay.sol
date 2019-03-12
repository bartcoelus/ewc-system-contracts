pragma solidity ^0.5.0;

import "../misc/Ownable.sol";
import "../interfaces/IValidatorSetRelay.sol";
import "../interfaces/IValidatorSet.sol";
import "../interfaces/IValidatorSetRelayed.sol";


contract ValidatorSetRelay is IValidatorSet, IValidatorSetRelay, Ownable {

    event NewRelayed(address indexed old, address indexed current);

    // System address, used by the block sealer
    // solhint-disable-next-line var-name-mixedcase
    address public SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    
    // Address of the inner validator set contract
    IValidatorSetRelayed public relayedSet;

    constructor(address _relayedSet)
        public
    {
        _setRelayed(_relayedSet);
    }

    modifier onlySystem() {
        require(msg.sender == SYSTEM_ADDRESS, "Sender is not SYSTEM");
        _;
    }

    modifier onlyRelayed() {
        require(msg.sender == address(relayedSet), "Sender is not the Relayed contract");
        _;
    }

    function callbackInitiateChange(bytes32 _parentHash, address[] calldata _newSet)
        external
        onlyRelayed
        returns (bool)
    {
        emit InitiateChange(_parentHash, _newSet);
        return true;
    }

    function finalizeChange()
        external
        onlySystem
    {
        relayedSet.finalizeChange();
    }

    function reportBenign(address _validator, uint256 _blockNumber)
        external
    {
        relayedSet.reportBenign(msg.sender, _validator, _blockNumber);
    }

    function reportMalicious(address _validator, uint256 _blockNumber, bytes calldata _proof)
        external
    {
        relayedSet.reportMalicious(
            msg.sender,
            _validator,
            _blockNumber,
            _proof
        );
    }

    function setRelayed(address _relayedSet)
        external
        onlyOwner
    {
        _setRelayed(_relayedSet);
    }

    function getValidators()
        external
        view
        returns (address[] memory)
    {
        return relayedSet.getValidators();
    }

    function _setRelayed(address _relayedSet)
        private
    {
        require(_relayedSet != address(0), "Relayed contract address cannot be 0.");
        require(_relayedSet != address(relayedSet),
            "New relayed contract address cannot be the same as the current one.");
        relayedSet = IValidatorSetRelayed(_relayedSet);
        emit NewRelayed(address(relayedSet), _relayedSet);
    }
}
