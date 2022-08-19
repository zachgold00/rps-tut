'reach 0.1';

const [gameOutcome, A_WINS, B_WINS, DRAW] = makeEnum(3);

const winner = (playHandA, playHandB, gHandA, gHandB) => {

  if (gHandA == gHandB) {
    return DRAW;
  } else {
    if (gHandA == (playHandA + playHandB)) {
      return A_WINS;
    } else {
      if (gHandB == (playHandA + playHandB)) {
        return B_WINS;
        // else the outcome is a draw
      } else {
        return DRAW;
      }
    }
  }
};


assert(winner(0, 4, 0, 4) == B_WINS);
assert(winner(4, 0, 4, 0) == A_WINS);
assert(winner(0, 1, 0, 4) == DRAW);
assert(winner(5, 5, 5, 5) == DRAW);

forall(UInt, playHandA =>
  forall(UInt, playHandB =>
    forall(UInt, gHandA =>
      forall(UInt, gHandB =>
        assert(gameOutcome(winner(playHandA, playHandB, gHandA, gHandB)))))));

forall(UInt, playHandA =>
  forall(UInt, playHandB =>
    forall(UInt, sameGuess => 
      assert(winner(playHandA, playHandB, sameGuess, sameGuess) == DRAW))));

const Player = {
  ...hasRandom, 
  getHand: Fun([], UInt),
  getGuess: Fun([], UInt),
  seeActual: Fun([UInt], Null),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {

  const Alice = Participant('Alice', {
    ...Player, 
    wager: UInt, 
    deadline: UInt,
  });

  const Bob = Participant('Bob', {
    ...Player, 
    acceptWager: Fun([UInt], Null), 
  });

  init();

  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });

  Alice.publish(wager, deadline)
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager);
  });

  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

  var outcome = DRAW;

    invariant(balance() == 2 * wager && gameOutcome(outcome));

  while ( outcome == DRAW ) {
    commit();

    Alice.only(() => {
      const _handAlice = interact.getHand();
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
      const commitAlice = declassify(_commitAlice);
    });
    Alice.publish(commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice));
    Bob.only(() => {
      const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob)
      .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
    commit();
    
    Alice.only(() => {
        const gHandA = declassify(interact.getGuess());
    });
    Alice.publish(gHandA)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    commit();

    Bob.only(() => {
      const gHandB = declassify(interact.getGuess());
    });
    Bob.publish(gHandB)
      .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
    commit();

    Alice.only(() => {
      const saltAlice = declassify(_saltAlice);
      const handAlice = declassify(_handAlice);
    });
    Alice.publish(saltAlice, handAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    checkCommitment(commitAlice, saltAlice, handAlice);

    outcome = winner(handAlice, handBob, gHandA, gHandB);
    continue;
  }

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });

  assert(outcome == A_WINS || outcome == B_WINS);

  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
  exit();
});