# Brehon walkthrough — narration script v2

Voice: ElevenLabs v3, US English (Eric). Expression tags are applied by the
performance pass at render time under the performance law — the register note
on each beat is the director's instruction to that pass, not spoken text.
"Brehon" keeps its real spelling; pronunciation (brih-HUN) is handled at the
TTS layer.

Structure: promise → problem (ordinary world) → the machine (one case, end to
end) → the frame returns. The viewer is cast as a judge in beat 5 and reads
the opening record fluently by beat 13.

---

## B0 · Cold open — the antagonist is the promise
*Screen:* pre-roll cards (built for capture, in the app's own type): the
title with the contested letter; "40,000 words · two months · one letter";
the r/Art headline
*Register:* storyteller, dry; the absurdity does the work

In December of 2012, somebody made the Wikipedia page for the next Star Trek
film and typed the title: Star Trek Into Darkness. And they ran into a
problem. Wikipedia's style rules say a small word like into stays lowercase,
unless it opens a subtitle. The studio, on purpose, had left the colon out of
the title. Capital I, or small i? Grown adults fought over that single letter
for two months. The argument ran past forty thousand words, the length of a
short novel. Nobody was paid to settle it, and nobody lost a thing by
refusing to quit. So nobody quit.

And when a forum does have a referee, it fails the other way. Not long ago, a
moderator on one of the internet's biggest art forums banned an artist over
one rule, in minutes, with no reasons on the record. The protest that
followed took down every moderator on the forum. Arguing costs nothing, so it
never ends. Judging pays nothing, so nobody does it well.

Over real things, we solved this a long time ago. A dispute about a fence or
a deposit doesn't run for two months. You bring a claim, it gets heard,
somebody rules, and it ends, on the record. What if a disagreement online
could end the same way?

## B1 · The record
*Screen:* `go('casedetail', {case:'AB12CD'})`
*Register:* quiet, letting the strangeness land

This is a court record from an app called Brehon. A community wrote a rule
for how its own conversation should run. A stranger broke it, refused to fix
it, and lost the ruling. Losing had consequences, the way it does over real
things. The verdict is one sentence: signed, permanent, citable by the next
case. The rules are yours. The court is your peers. A brehon is what early
Ireland called a judge. And it started in a game about describing movies
badly.

## B2 · Sign-in
*Screen:* `go('signin', {})`
*Register:* moving, unceremonious

You sign in, and instead of a tour, the app hands you a case.

## B3 · The rule
*Screen:* `go('onboarding', {step:'game'})` → `go('onboarding', {step:'game', phase:'rule'})`
*Register:* engaged, precise on rule two

A running game: describe a movie badly. Every thread here writes its own
rules and posts them at the top, numbered, like law. Rule two is the one that
matters today: never use the movie's title.

## B4 · Jaws
*Screen:* `go('onboarding', {step:'game', phase:'attempt'})`
*Register:* amused, then measured on the ruling

First case. Someone describes the movie Jaws, and writes the word jaws right
into the sentence, as plain English. Did that break the rule? A brehon
already ruled on it: merely bent. A title used as an ordinary word is not a
title used as a name. That one sentence is now precedent. The next case can
cite it, or fight it.

## B5 · Titanic — your call
*Screen:* `go('onboarding', {step:'game', phase:'rate'})`
*Register:* mischievous setup, then hand the wheel over

Second case, no precedent to lean on this time. Someone posts: Titanic, boat
sinks. Your call. Bent, or broken?

## B6 · The reveal
*Screen:* `go('onboarding', {step:'game', phase:'reveal', choice:'BROKEN'})`
*Register:* calm verdict, then a door opening

The brehon who judged this one said broken. The title is doing the naming.
And look at what stands behind that verdict: a demand, a refusal, two bonds,
a ruling. Every verdict here is the end of a process, and there is one
running live right now.

## B7 · Your name, and the gesture
*Screen:* `filled.onbName = true; go('onboarding', {step:'mark'})` → `go('onboarding', {step:'wand'})`
*Register:* warm, then light on the gesture

First, two small things. You sign your name, because rulings will cite you by
it, and losing a case never lowers your standing. Then the everyday gesture:
tap the rod and it bends, meaning clever, still legal. Hold it and it snaps.
Broken. Votes are reader interest. Rulings are the court's.

## B8 · A live thread
*Screen:* `go('thread', {thread:'pizza'})`
*Register:* at home now, then a hook at the end

Onboarding over. This is a live thread, a game about pizza, same shape as the
one you judged: law at the top, attempts below, and every attempt carries its
votes and its fate. One post down this page has a problem.

## B9 · The demand — free
*Screen:* `startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'demand'})`
*Register:* practical, exact on the prices

You think that post bent a rule too far, so you make the first move, and the
first move is free: a demand. The author can fix it, concede it, or refuse.
Most disputes end right here. Going further has costs, and the app shows them
before you choose. This author refuses.

## B10 · The bond
*Screen:* `startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'surety'})`
*Register:* serious; the one technical sentence stays plain

Refusal turns the disagreement into a case. And like any case over something
real, both sides put something behind their word: each posts a bond, from an
app balance they top up like any other. The bonds sit in escrow that neither
side, and not even the company, can touch. Nobody here ever sees a wallet.

## B11 · Deliberation
*Screen:* `go('transcript', {case:'QF83RN'})`
*Register:* tension held low

Now each side retains an advocate: a fellow brehon who argues the case for
them, on the record, under chess clocks. They can settle at any move. These
two deadlock. So the parties seat an adjudicator, a third brehon both sides
accept.

## B12 · The ruling
*Screen:* `go('casedetail', {case:'SB63KH'})`
*Register:* grave, then the mechanism explained with relish

Here is the mechanism that keeps everyone honest. The adjudicator cannot
split the difference. He must take one side's final offer, word for word, so
each side writes the most reasonable offer it can. The winner pays nothing.
The loser covers the cost of the case, and that is what pays the court.
Nobody gets rich off a verdict.

And none of this machinery is new. Bonds, advocates, and judges the parties
pick for themselves is how Ireland ran its law for a thousand years, without
police and without prisons. They called it brehon law. The app moves it
online.

## B13 · The record — the frame returns
*Screen:* `go('casedetail', {case:'AB12CD'})`
*Register:* plain warmth; end flat, no reach

And this is the record you saw at the start. You can read it now. The
verdict, the holding, the rule it enforced, the post that broke it, and the
trail of earlier cases it stands on. A stranger refused to follow a rule he
had agreed to play under, and for once the argument actually ended. The game
got its rule back, and the sentence that settled it stays citable for as long
as the record exists. The next case is somebody's post tonight.
