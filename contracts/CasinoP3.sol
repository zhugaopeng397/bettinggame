//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CasinoP3 {

  struct ProposedBet {
    address sideA;
    uint value;
    uint placedAt;
    bool accepted;  
    uint randomA; 
    bool sideARevealed;
    uint sideARevealedAt;
  }    // struct ProposedBet


  struct AcceptedBet {
    address sideB;
    uint acceptedAt;
    uint hashB;
  }   // struct AcceptedBet

  // Proposed bets, keyed by the commitment value
  mapping(uint => ProposedBet) public proposedBet;

  // Accepted bets, also keyed by commitment value
  mapping(uint => AcceptedBet) public acceptedBet;

  event BetProposed (
    uint indexed _commitment,
    uint value
  );

  event BetAccepted (
    uint indexed _commitment,
    address indexed _sideA
  );

  event BetSideARevealed (
    uint indexed _commitment,
    uint sideARevealedAt
  );

  event BetSettled (
    uint indexed _commitment,
    address winner,
    address loser,
    uint value    
  );


  // Called by sideA to start the process
  function proposeBet(uint _commitment) external payable {
    require(proposedBet[_commitment].value == 0,
      "there is already a bet on that commitment");
    require(msg.value > 0,
      "you need to actually bet something");

    proposedBet[_commitment].sideA = msg.sender;
    proposedBet[_commitment].value = msg.value;
    proposedBet[_commitment].placedAt = block.timestamp;
    // accepted is false by default

    emit BetProposed(_commitment, msg.value);
  }  // function proposeBet


  // Called by sideB to continue
  function acceptBet(uint _commitment, uint _hashB) external payable {

    require(!proposedBet[_commitment].accepted,
      "Bet has already been accepted");
    require(proposedBet[_commitment].sideA != address(0),
      "Nobody made that bet");
    require(msg.value == proposedBet[_commitment].value,
      "Need to bet the same amount as sideA");

    acceptedBet[_commitment].sideB = msg.sender;
    acceptedBet[_commitment].acceptedAt = block.timestamp;
    acceptedBet[_commitment].hashB = _hashB;
    proposedBet[_commitment].accepted = true;

    emit BetAccepted(_commitment, proposedBet[_commitment].sideA);
  }   // function acceptBet

  // Called by sideA to reveal randomA
  function revealA(uint _randomA) external {
    uint256 _commitment = uint256(keccak256(abi.encodePacked(_randomA)));

    require(proposedBet[_commitment].sideA == msg.sender,
      "Not a bet you placed or wrong value");
    require(proposedBet[_commitment].accepted,
      "Bet has not been accepted yet");

    proposedBet[_commitment].sideARevealed = true;
    proposedBet[_commitment].sideARevealedAt = block.timestamp;
    proposedBet[_commitment].randomA = _randomA;

    emit BetSideARevealed(_commitment, proposedBet[_commitment].sideARevealedAt);
  }

  // Called by sideB to reveal randomB and conclude the bet
  function revealB(uint _commitment, uint _randomB) external {
    uint _commitmentB = uint256(keccak256(abi.encodePacked(_randomB)));

    require(proposedBet[_commitment].accepted && proposedBet[_commitment].sideARevealed,
      "Bet has not been accepted or revealed yet");
    require(acceptedBet[_commitment].sideB == msg.sender && acceptedBet[_commitment].hashB == _commitmentB,
      "Not a bet you placed or wrong value");

    address payable _sideB = payable(msg.sender);
    address payable _sideA = payable(proposedBet[_commitment].sideA);
    uint256 _agreedRandom = _randomB ^ proposedBet[_commitment].randomA;
    uint256 _value = proposedBet[_commitment].value;

    // Pay and emit an event
    if (_agreedRandom % 2 == 0) {
      // sideA wins
      _sideA.transfer(2*_value);
      emit BetSettled(_commitment, _sideA, _sideB, _value);
    } else {
      // sideB wins
      _sideB.transfer(2*_value);
      emit BetSettled(_commitment, _sideB, _sideA, _value);      
    }

    // Cleanup
    delete proposedBet[_commitment];
    delete acceptedBet[_commitment];

  }  // function reveal

}   // contract Casino
