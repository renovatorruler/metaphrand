# Brehon walkthrough — narration script

Voice: ElevenLabs v3, Eric (US English). Bracketed words are expression
tags for the TTS, not spoken. Pronunciation of "Brehon" (brih-HUN) is
handled by the account's `brehon-terms` pronunciation dictionary — the
script keeps the real spelling.

## 1. Sign-in
*Screen:* `go('signin', {})`

[warm] This is Brehon: the rule of law for online discourse. [confident] People post rules, other people try to outsmart them, and ordinary users, called brehons, rule on what stands: for real money. [inviting] Here's how a new user meets it.

## 2. Onboarding — premise card
*Screen:* `go('onboarding', {step:'game'})`

[calm] We don't explain the app up front. [inviting] We introduce an example case, so you learn what this is about by judging it yourself.

## 3. Onboarding — the rule
*Screen:* `go('onboarding', {step:'game', phase:'rule'})`

[engaged] Every thread sets its own rules. This one is a game of describing movies badly, and rule two is the one that matters here: [precise] never use the movie's title.

## 4. Onboarding — the Jaws attempt
*Screen:* `go('onboarding', {step:'game', phase:'attempt'})`

[amused] Someone describes the movie Jaws, and slips the word jaws right into the sentence: as plain English, not as a title. [curious] So: did that break the rule, or merely bend it? [measured] Brehons ruled it merely bent: a title used as an ordinary word is not a title used as a name. [thoughtful] And that ruling is now precedent. A future case can cite it, or overturn it.

## 5. Onboarding — your call
*Screen:* `go('onboarding', {step:'game', phase:'rate'})`

[mischievous] Then someone posts: Titanic, boat sinks. [curious] Now it's your call: bent, or broken?

## 6. Onboarding — the reveal
*Screen:* `go('onboarding', {step:'game', phase:'reveal', choice:'BROKEN'})`

[calm] Say you tap broken. [serious] The brehon who ruled this one agreed with you. A reader had demanded a fix, the author refused, both sides posted bonds, their advocates deadlocked, and an adjudicator ruled it broken. [emphatic] The ruling is one citable sentence, on the record.

## 7. Onboarding — your name
*Screen:* `filled.onbName = true; go('onboarding', {step:'mark'})`

[warm] Then you fill in your name. Rulings will cite you by it. [reassuring] And losing a case never lowers your standing.

## 8. Onboarding — the voting gesture
*Screen:* `go('onboarding', {step:'wand'})`

[light] Last, the voting gesture. Tap the rod and it bends: clever, still legal. [snappy] Hold it, and it snaps: broken. [matter-of-fact] Votes are reader interest, not rulings. [reassuring] And when a real dispute of your own comes up, there's a whole process for having your case argued: the app walks you through it when you need it, not before.

## 9. A live thread
*Screen:* `go('thread', {thread:'pizza'})`

[engaged] After onboarding, the threads. Rules sit at the top as numbered law, and every attempt below carries its votes and its fate, with a case number you can open. [thoughtful] Rulings accumulate into precedent other disputes cite.

## 10. The demand ($0)
*Screen:* `startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'demand'})`

[encouraging] When you think a post broke the rules, the first step costs nothing: a demand. Fix it, take it down, or refuse. [reassuring] Most disputes end right here, free. [precise] And the price of going further is printed exactly where you decide: settling costs six dollars, losing a ruling costs eleven.

## 11. The bond
*Screen:* `startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'surety'})`

[serious] If they refuse, money enters at exactly one gate: the twenty dollar bond, posted from a balance you top up like any app. [confident] Underneath, it's real USDC held in escrow on Solana by a program whose money rules are formally proven. [firm] The user never sees a wallet, and never touches gas.

## 12. Deliberation
*Screen:* `go('transcript', {case:'QF83RN'})`

[measured] The defender matches the bond, and each side retains an advocate: a fellow brehon, paid five dollars for the work. They deliberate on the record, under chess clocks. [tense] They can settle. Only if they deadlock do the parties seat an adjudicator: another brehon both sides accept.

## 13. The ruling
*Screen:* `go('casedetail', {case:'SB63KH'})`

[grave] The adjudicator must pick one side's final offer, word for word. No middle ground: that keeps both offers honest. [emphatic] The winner pays nothing. The loser pays eleven dollars, and that money is wages: the advocate, the adjudicator, the platform. Nobody profits from winning. [solemn] The ruling is sealed: signed, anchored on chain, verifiable by anyone without trusting us.

## 14. The record
*Screen:* `go('casedetail', {case:'AB12CD'})`

[warm] And every finished case reads like this: the verdict, the holding, the rule, the offending post, and the precedent trail. [proud] Case law, written by its own community, one dispute at a time. [closing] That's Brehon. Talk is free, losing costs, and the record is forever.
