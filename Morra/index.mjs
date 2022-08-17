import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const isAlice = await ask.ask(
  `Are you Alice?`,
  ask.yesno
);
const who = isAlice ? 'Alice' : 'Bob';

console.log(`You're playing Morra as ${who}`);

let acc = null;
const createAcc = await ask.ask(
  `Would you like to create an account? (only possible on devnet)`,
  ask.yesno
);
if (createAcc) {
  acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
} else {
  const secret = await ask.ask(
    `What is your account secret?`,
    (x => x)
  );
  acc = await stdlib.newAccountFromSecret(secret);
}

let ctc = null;
if (isAlice) {
  ctc = acc.contract(backend);
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`); });
} else {
  const info = await ask.ask(
    `Please paste the contract information:`,
    JSON.parse
  );
  ctc = acc.contract(backend, info);
}

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async () => fmt(await stdlib.balanceOf(acc));

const before = await getBalance();
console.log(`Your balance is ${before}`);

const interact = { ...stdlib.hasRandom };

interact.informTimeout = () => {
  console.log(`There was a timeout.`);
  process.exit(1);
};

const HAND = ['0','1', '2', '3', '4', '5'];
const HANDS = {
  '0': 0,
  '1': 1, 
  '2': 2, 
  '3': 3, 
  '4': 4, 
  '5': 5, 
};

const GUESS = ['0','1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
const GUESSS = {
  '0': 0,
  '1': 1, 
  '2': 2, 
  '3': 3, 
  '4': 4, 
  '5': 5,
  '6': 5,
  '7': 7,
  '8': 8,
  '9': 9,
  '10': 10 
};

interact.getHand = async () => {
  const hand = await ask.ask(`What hand will you play?`, (x) => {
    const hand = HANDS[x];
    if ( hand === undefined ) {
      throw Error(`Not a valid hand ${hand}`);
    }
    return hand;
  });
  console.log(`You played ${HAND[hand]}`);
  return hand;
};

interact.getGuess = async () => {
  const hTotal = await ask.ask(`What do you think the total is 0-10?`, (x) => {
    const hTotal = GUESSS[x];
    if ( GUESS === undefined ) {
      throw Error(`Not a valid guess ${GUESS}`);
    }
    return GUESS;
  });
  console.log(`You played ${GUESSS[GUESS]}`);
  return GUESS;
};

const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
interact.seeOutcome = async (outcome) => {
  console.log(`The outcome is: ${OUTCOME[outcome]}`);
};

interact.deadline = 5;
interact.wager= 500;


const part = isAlice ? ctc.p.Alice : ctc.p.Bob;
console.log(part)
await part(interact);

const after = await getBalance();
console.log(`Your balance is now ${after}`);

// await Promise.all([
//   backend.Alice(ctcAlice, {
//     ...stdlib.hasRandom,
//     wager: 500,
//     deadline: 5


//   }),
//   backend.Bob(ctcBob, {
//     ...stdlib.hasRandom

//   }),
// ]);

ask.done();