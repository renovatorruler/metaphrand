# DIVIDE & CONQUER — the kids' detective series that teaches computation (opened 2026-07-30)

Hardy Boys register: preteens, chapter-novel length, mystery form. Kids' detective agency named "Divide & Conquer" — adults read it as a motto, readers learn it is a method.

## The three series laws (from the founding conversation)

1. THE ADULT FAILURE IS LEGIBLE AND UNMAGICAL. Adults are never stupid — they are constrained (overtime costs money, nobody will watch 40 hours of tape, the inspector comes Monday). The kids win because they are the only ones willing to think about HOW to look.
2. EVERY BOOK IS A MYSTERY, never an adventure. Algorithms are methods of detection; mysteries are stories about finding things out. The marriage is load-bearing.
3. THE CONCEPT IS NEVER NAMED BEFORE IT IS USED. The kids invent it under pressure; afterwards a recurring adult (the recognizer — librarian/uncle/retired engineer) mentions it has a name and that grown people are paid to do it. Discovery first, christening second.

## Idea bank (approved conversation, 2026-07-30)

FOUNDING TWO (the author's):
- THE STOLEN BIKE — binary search / heuristics / map-reduce over a 40-hour CCTV tape the police cannot afford to watch.
- THE INDEX — a database the kids maintain (library or better), search made fast by building an index.

THE LIST:
- The money nobody stole — race condition / lost updates in the fundraiser ledger; the crime dissolves; the fix is a lock.
- The digit that changed — checksums; the check digit identifies WHICH link in the chain broke; twist: the "error" was deliberate.
- The coat check — hashing; the S-bin collision in a Punjabi neighbourhood; redesign under a queue of angry parents.
- The flooded library — merge sort / parallelism; twenty volunteers make it slower until the work splits and rejoins.
- The lost dog — heuristic search; probability map beats the adults' grid; real SAR practice.
- The one long line — queueing theory; provable with a stopwatch.
- Counting what can't be counted — sampling / mark-recapture; the estimate CONTRADICTS an adult's official number.
- The parade float — dependency ordering / critical path; the sabotage lands on the critical task.
- The full shelf — caching and eviction; what do you throw out?
- The stopped clock — state machines; the mapped behaviour reveals a state that shouldn't exist.

NEW (2026-07-30, second round):
- The two padlocks — key exchange; a parcel sent locked, the receiver adds their lock, the sender removes theirs; secret notes past a snooping class.
- The three Rams — namespaces; a village with three men of one name and the disambiguation system the kids must formalize to deliver a telegram.
- The milkman's ledger — compression; run-length and abbreviation; the ledger's compressed form EXPOSES the fraud a verbose one hid.
- The class newspaper — version control; many editors, one master copy, who-changed-what, and the first merge conflict in fiction.
- The nested tiffins — recursion with a base case; instructions that refer to themselves and the box at the bottom that just opens.

## ⚑ AUDIENCE LAW (author, 2026-07-30): THIS IS AN AMERICAN STORY

Not Indian. American setting, American kids, American audience. The mechanisms are culture-neutral; the VEHICLES below were drawn from the wrong shelf and are re-pointed:
- letter-writer outside the post office → THE SMALL-TOWN JOB PRINTER (see below)
- «आधा» gloss dropped; the nickname HALF stands on its own in English
- the three Rams → the three Bill Millers (a town of Andersons; one misdelivered summons)
- the coat check's Punjabi S-bin → the church-supper/school-dance coat pile, collision on Smith and Johnson
- the milkman's ledger → the paper-route collection book (or a diner's tab board)
- the mela headcount → the county fair gate count
- knitting/loom cards → QUILT BLOCKS (alternate: square-dance calls, which nest natively)
Open: era and region. A four-officer department with no overtime budget is the engine of law #1, so the town must be small and genuinely broke.

## THE LAMBDA CALCULUS BOOK — «The Printer's Devil»
(superseded title: «The Letter-Writer's Apprentice»)

Vehicle: the professional letter-writer outside the post office (the real Indian institution) with his tin box of TEMPLATE letters — each a letter with named holes. A kid becomes his apprentice.

Staged concepts, each physical:
1. ABSTRACTION — a template is a letter with holes: «आदरणीय ___, आपका ___ …». A rule with a blank IS a function.
2. APPLICATION — filling a hole. Order matters.
3. CURRYING — filling ONE hole of a two-hole template yields a HALF-LETTER, itself a reusable template; the writer pins half-filled slips on his board for repeat customers. Partial application as shop practice.
4. VARIABLE CAPTURE + ALPHA CONVERSION — two templates both use the label «नाम» meaning different people; a love letter goes out addressed to the moneylender. The fix — rename the label before combining — is alpha conversion as farce.
5. COMPOSITION / HIGHER-ORDER — templates that call templates: the condolence-opener slot that any letter can take as its head.
6. THE MYSTERY — an extortion letter surfaces, assembled unmistakably from the old writer's own templates; he is accused. The apprentice runs the reduction BACKWARDS: which sequence of template applications produces exactly this letter? The culprit is convicted by a half-filled slip — a curried template with the victim's name already bound — that only three people ever held. Beta reduction as forensics.
7. THE DEEP-END GAG — the chain letter: a template that instructs its reader to copy and send itself. Self-application, the infinite loop every child has already met; the "stop after five" line as the base case. (Ω and the flavor of Y, never named.)

The recognizer's closing line names none of the Greek: "There's a whole mathematics of fill-in-the-blanks. A man named Church built it before computers existed — computers are built out of it."

## Church numerals (second λ-adjacent book, or a B-plot)

«The Pattern Cards» — the grandmother's knitting/loom cards where a NUMBER is not a symbol but a card meaning "do this N times"; cards that take cards («repeat [k2, p1] ×3»). Addition = stacking, multiplication = feeding one card to another. The shawl border encodes a message readable only by someone who understands cards-that-take-cards.

## Open decisions

- One concept per book vs one case forcing 3–4 concepts in sequence (author leaning unstated).
- Setting/anchor town + the agency's kids (cast design conversation pending).
- Language/market: English with Indian setting (Hardy Boys register suggests English; the letter-writer book is deeply Indian either way).
