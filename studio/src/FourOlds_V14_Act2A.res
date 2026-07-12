/* THE FOUR OLDS v14 — ACT 2A (scenes 14–24), engine-only, resumable.
   Run AFTER Act 1 completes: CLAUDE_STUDIO_BUDGET=35 node src/FourOlds_V14_Act2A.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/v14/"

type job = {seed: Seed.sceneSeed, out: string}

let mk = (id, file, slug, logline, cast, peshat, sod, beats, rules): job => {
  seed: {
    id,
    slug,
    logline,
    cast,
    layer: {peshat, sod},
    beats,
    rules: Belt.Array.concat(rules, V14Rules.common),
  },
  out: dir ++ file,
}

let facilitator: Seed.voiceCard = {
  name: "FACILITATOR",
  who: "30s, corporate trainer, all teeth, clicker in hand. Genuinely nice — that is the horror. Reads silence as engagement.",
  register: "chirpy corporate-positive; 'great question' energy; never cruel on the surface.",
  earnsEloquence: false,
  lexicon: "HR-training English: frameworks, journey, retire (as a verb for traditions).",
}

let bayTwoMan: Seed.voiceCard = {
  name: "BAY TWO MAN",
  who: "60s, laid-off machinist attending for rehire eligibility; sincerely wants to understand what he is being asked to give up.",
  register: "plain, slow, few words; asks like a man asking about a part number.",
  earnsEloquence: false,
  lexicon: "shop plain.",
}

let jobs: array<job> = [
  /* ---- v14 SEMINAR (take 3) ------------------------------------------- */
  mk(
    "v14-14-seminar",
    "sc14_seminar.scene.txt",
    "INT. FRONTIER AEROSPACE, TRAINING ROOM B - DAY",
    "Mandatory Module 7: the facilitator presents Mao's Four Olds as an early framework — and when a sincere machinist asks what actually counts as one, her examples are the things already coming down in the audience's own America, with the in-world fireworks ban cited as the framework working at national scale. Nobody hands you a list; you already know what yours are.",
    [facilitator, bayTwoMan, V14Cast.joss, V14Cast.mack, V14Cast.pell],
    "a corporate heritage-training session; a sincere question; an administrator drops in; homework is assigned",
    "the framework needs no aim because the last decade already did the aiming — her examples are real, recognizable, and already retired or falling, so the Mao slide plays as a continuation, not an import; and the homework outsources the last targeting to the targeted",
    [
      {
        who: "FACILITATOR",
        want: "deliver Module 7 with good engagement",
        wall: "a sincere question she wasn't scripted for",
        turn: "her examples come easily because the world already supplied them — team names, renamings, the Pledge, the beef and appliance conversations, cursive — and the fireworks ban this January as the same framework at national scale, 'and it went fine' — then the pivot: nobody has to hand you a list; you already know what yours are",
        subtext: "the machine's proof of concept is the recent past",
      },
      {
        who: "BAY TWO MAN",
        want: "understand what counts",
        wall: "it turns out everything counts",
        turn: "he lowers his hand and says nothing more",
        subtext: "the vagueness has examples now, and they are all of it",
      },
      {
        who: "JOSS",
        want: "poke it once",
        wall: "the sign-in clipboard feeds his compliance score",
        turn: "'What happened to the people who liked the old stuff?' — 'There were — implementation errors, in that era. Which is why the frameworks now, they really center on dialogue.'",
        subtext: "the teeth, glimpsed once",
      },
      {
        who: "PELL",
        want: "be seen blessing the good work",
        wall: "he knows nothing about the content",
        turn: "'Centuries of ancient Chinese wisdom in that slide.' / 'It's from 1966—' / 'Wonderful.' — and he stays",
        subtext: "alignment, not accuracy",
      },
    ],
    [
      "SCAFFOLD LOCKED from the approved take: lights down, the Mao slide (1966 — A BOLD QUESTION, WHAT DO WE OWE THE PAST), the four-categories slide on harmony blue, Mack copying the four names in block letters, the sincere question, the answer, the silence misread ('You can feel everybody kind of going inward with it. That's the work happening.'), Joss's Hanoi-adjacent question and the implementation-errors answer, Pell's drop-in, the homework slide (YOUR REFLECTION HOMEWORK — IDENTIFY ONE OLD HABIT YOU'RE READY TO RETIRE!), the chained sign-in clipboard, the corridor button: JOSS (whisper): 'My grandpa's old habit was getting shot at over Hanoi.' / MACK: 'Write coffee. Everybody writes coffee.'",
      "HER EXAMPLES — the payload, delivered warmly, citing things that already happened in the audience's real world and this film's world, choose four or five: the team names and mascots already retired ('and honestly the sky didn't fall'); the holidays and schools renamed, the statues down; the Pledge fading out district by district ('we've mostly moved past that one'); the beef conversation and the appliance conversation, her exact corporate euphemisms; cursive — schools stopped teaching it, nobody voted, one day the grandkids just couldn't read the letters; AND the in-world capstone, cited approvingly: the fireworks ban this January — 'that's this exact framework, applied at national scale — and it went fine.'",
      "HARD BANS unchanged: nothing that portraits a principal character (no fifty years, no Tuesdays, no test pilots, no flag-folding, no old signatures). The pivot line's substance is fixed: nobody has to hand you a list — you already know what yours are; each person decides what counts for them, and that is what the reflection piece walks you through.",
      "Nobody in the room connects anything to anyone. The room answers with silence.",
    ],
  ),
  /* ---- v15 RAGE LADDER I ------------------------------------------------ */
  mk(
    "v14-15-rage1",
    "sc15_rage1.scene.txt",
    "EXT. FIRST METHODIST CHURCH, BROKEN BOW - SUNDAY MORNING",
    "Three small takings in one county: the church bell silenced under the sound-carbon framework, the Legion post's flagpole permit served by Wade, and a fourth-grade worksheet on Danny's kitchen table asking his son to retire one family tradition. The boy's pencil answer: the cookout at grandpa's.",
    [V14Cast.wade, V14Cast.danny],
    "a work order, a permit denial, a homework sheet — one ordinary week of the new framework",
    "the insults descend from the national to the personal in three steps — steeple, post, kitchen table — and every one arrives on paper, smiling, signed by nobody; the grandson's pencil is the regime's deepest reach and no adult says one word about it",
    [
      {
        who: "WADE",
        want: "serve the Legion paper and get back in the cruiser",
        wall: "the men on the post steps knew his father",
        turn: "he serves it, hat in hand, eyes on the paper the whole time — and the pole's rope is already being unclipped behind him as he walks away",
        subtext: "the enforcer the town forgives is still the enforcer",
      },
      {
        who: "DANNY",
        want: "check his son's homework like any Tuesday",
        wall: "the worksheet is the seminar's, sized for fourth grade",
        turn: "the boy's answer, in pencil: the Fourth of July cookout at grandpa's — Danny reads it twice, sets it down flat, and says nothing at all",
        subtext: "the machine runs the same slide on children",
      },
    ],
    [
      "THREE BEATS, three sluglines, no connective prose: (1) EXT. FIRST METHODIST — a county van; a WORK ORDER on the door (the sound framework, decibel allowance); two workers with a ladder wrapping the bell or unbolting the clapper; the organ heard faintly through the wall, mid-hymn, and the bell NOT ringing at the hour — hold on the silent steeple one beat; (2) EXT. AMERICAN LEGION POST 219 — Wade serves the permit paper (annual flag-display permit: DENIED — PENDING HERITAGE REVIEW stamped where a fee stamp used to go); three vets on the steps; nobody argues; the halyard unclipped; (3) INT. DANNY'S KITCHEN, KEARNEY - NIGHT — the worksheet header: MY HERITAGE JOURNEY — ONE FAMILY TRADITION I'M READY TO RETIRE; the boy's pencil block letters: THE 4TH OF JULY COOKOUT AT GRANDPAS; milk glass; Danny reads it twice and sets it down flat.",
      "NO dialogue in beats 1 and 3 beyond incidental; beat 2 at most three short lines. The paper does the talking in all three. Total: under two pages.",
      "The church is the one where Peg played organ — show a small brass plaque by the door (IN MEMORY — ORGAN FUND) without a name readable. Never referenced in dialogue.",
    ],
  ),
  /* ---- v16 BUILD + REPAINT ----------------------------------------------- */
  mk(
    "v14-16-build-repaint",
    "sc16_build_repaint.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - DAY",
    "The legal build in full swing — and on every screen in the country, painters roll white primer over the fifty-foot flag on Frontier's booster while the anchor stops talking. Vess owns the order in one press-room minute. At Roy's, the sugar caddy stays where it is when Cricket sits down.",
    [V14Cast.vess, V14Cast.tito, V14Cast.gunny, V14Cast.dutch, V14Cast.cricket, V14Cast.buck, V14Cast.earlene],
    "a work montage, a repaint on live news, a one-minute press conference, and a cold cup of coffee",
    "the town starts billing Cricket for a collaboration it can't see the inside of — the audience holds both truths at once and can't warn anybody; and the erasure of the flag from the rocket is the regime's aesthetic thesis, painted in primer, on camera",
    [
      {
        who: "VESS",
        want: "own the repaint before anyone can pin it on Hale",
        wall: "a press row smelling blood",
        turn: "'Mine. I ordered the repainting. The Accord specifies neutral mission livery. Paint is cheaper than a receiver. That math is my job.' — and off the follow-up about Hale: 'The board meets Thursday. Bring it.'",
        subtext: "she takes the hate on purpose and files the receipt",
      },
      {
        who: "CRICKET",
        want: "his usual coffee at his usual stool",
        wall: "word is around that he signed onto the federal flag-box contract",
        turn: "no sugar slid down, the coffee slow, and a ticket written where no ticket used to be — he pays it, puts his cap on, and goes without a word",
        subtext: "the cost of a secret is being billed for the cover story",
      },
    ],
    [
      "REQUIRED: the shop working — crate one in the welding jig, purge lines run neat along the frame rail where nobody will ever see them; Bay Two men at stations, day labor, cash rates; the pressure-test knock ritual (two knocks — pause — two knocks, answered from inside; Tito wedged by the gauge with a wind-up watch, bored).",
      "REQUIRED news footage: steady helicopter frame — the booster long as a grain elevator on its transporter, fifty feet of painted stars and stripes; the cherry-picker; two painters rolling primer top to bottom, one pass at a time; the footage does not cut away; the anchor has stopped talking. Then the diner: the Cook reaching up and turning the set OFF — black screen — and going back to the grill.",
      "REQUIRED Vess presser lines as in the logline beat. Keep the whole presser under ten lines.",
      "The cold-shoulder beat plays in service only: sugar not slid, coffee slow, the ticket written. NO dialogue about it. Buck watches the ball game.",
    ],
  ),
  /* ---- v17 SKY KING -------------------------------------------------------- */
  mk(
    "v14-17-sky-king",
    "sc17_sky_king.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN, LOADING DOCK - DAY",
    "A water break on the dock. Stitch, out of nowhere: 'You ever heard of Sky King?' Cricket hasn't. So Stitch tells it — the baggage handler who taught himself to fly at a kitchen table, took an empty airliner one morning, rolled it over the mountains, and waved at the fighter jets they scrambled to box him in.",
    [V14Cast.stitch, V14Cast.cricket],
    "two old men on a break; one story, told straight through",
    "the movie hands its own thesis to its storyteller — an unqualified man, a stolen machine, one perfect act nobody can take back — and neither teller nor listener names what the story is for; it ends unresolved on the wave",
    [
      {
        who: "STITCH",
        want: "tell it right",
        wall: "none — the wall is what the story costs him to believe",
        turn: "he tells it plain: loaded bags at the airport, never flew a day, years of a kitchen-table computer sim, then one morning walked out and took an empty airliner — got it up over the mountains and rolled it the whole way around — and when the fighters came up to box him in, 'He just waved at 'em.'",
        subtext: "the myth-keeper feeding the commander exactly the story he'll need, without knowing it",
      },
      {
        who: "CRICKET",
        want: "drink his water",
        wall: "the story lands somewhere he doesn't show",
        turn: "'What happened to him?' — 'Never flew again, of course.' — and Stitch drinks, and the break ends",
        subtext: "one flight, then never again: a sentence Cricket has lived from the other side",
      },
    ],
    [
      "OPENING LINE FIXED: STITCH: 'You ever heard of Sky King?' / CRICKET: 'Can't say I have.' — then the story, told in Stitch's rounds-everything drawl, no interruptions except one or two of Cricket's plain prompts ('Then what happened.').",
      "The telling must be PLAIN — no craft, no punchlines except the wave itself. End the scene within three lines after 'He just waved at 'em.' — the fate stated flat ('Never flew again, of course.') and back to work. Do NOT resolve what the story means to either man.",
      "Under a page and a half. Two men, water, a dock. Nothing else moves.",
    ],
  ),
  /* ---- v18 ANTHEM NIGHT ------------------------------------------------------ */
  mk(
    "v14-18-anthem",
    "sc18_anthem.scene.txt",
    "EXT. PIONEER FIELD, MINOR-LEAGUE BALLPARK - NIGHT",
    "Nine thousand people at a sold-out park are given 'One World Rising' and a children's choir — and Buck, alone, off-key, too loud, starts the anthem instead. By the last line it's the whole park with no melody to speak of. The four olds stand bare-headed and don't sing. Danny sings.",
    [V14Cast.buck, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny, V14Cast.danny],
    "a minor-league ballgame's opening ceremony goes off-script",
    "the country's first spontaneous NO — nine thousand voices out of time with each other and dead on time with each other; the olds' silence is discipline, not absence: you hold the colors, you don't perform them; and a compliance kid decides, alone, to put his tablet away",
    [
      {
        who: "BUCK",
        want: "sing the song that belongs to the flag he's looking at",
        wall: "nine thousand people's silence and a PA playing something else",
        turn: "four full bars alone, off-key, too loud — then the row behind him joins, then the section, then the far bleachers, ragged, out of time, gaining — the choir director drops her hands and turns around to face the flag pole",
        subtext: "somebody has to be first, and first costs the most",
      },
      {
        who: "CRICKET",
        want: "stand correctly",
        wall: "everything",
        turn: "hats off, on their feet, none of the four sings — Gunny at attention, thumb along his trouser seam; Dutch's cap over the exact center of his chest; Cricket watching row after row find the words — and beside them Danny sings",
        subtext: "the men who served hold still; the son carries the sound",
      },
    ],
    [
      "REQUIRED: the PA introduction ('One World Rising,' the Tri-Cities Children's Harmony Choir); the crowd getting up slow, hands in pockets; the backing track (synthesizer, chimes) buried under voices but never stopping; the COMPLIANCE KID at the concourse rail with his tablet half-raised — he looks from the tablet to the stands and back, lowers it, puts it away; the note dying off across the parking lots; the crowd sitting; the game just starting, first pitch a called strike; the scoreboard (TONIGHT'S POST-GAME LIGHT SHOW BROUGHT TO YOU BY THE UNITY FUND) and the BOY two rows down: 'Is the light show the one with the booms?' / FATHER: 'Not anymore, bud.'; the olds looking down the row at each other and putting their caps back on, one by one.",
      "A full row of empty seats flanks the olds in a sold-out park — shown once, no comment.",
      "No character comments on the singing afterward. The scene ends on caps going back on.",
    ],
  ),
  /* ---- v19 LIGHTS-OUT ---------------------------------------------------------- */
  mk(
    "v14-19-lights-out",
    "sc19_lights_out.scene.txt",
    "INT. ROY'S DINER - DAY",
    "The anthem night comes back as content: reaction clips, boomer-diner-check videos, a kid filming the regulars while a courier hands his burrito past Earlene's register. On the TV, the gift list grows — the museum suits, one per flag. That night the Tuesday net opens, and for the first time in fifty years nobody has anything to say.",
    [V14Cast.joss, V14Cast.tito, V14Cast.buck, V14Cast.earlene, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny],
    "the morning after the anthem went viral, and the shortest radio net ever logged",
    "the regime insulting them was war; the grandchildren laughing is defeat — the men conclude the country is already gone, and the film records the conclusion in the only grammar they have: a net with nothing to say. Joss and Tito, in the shop, are the counter-evidence, and nobody looks at them",
    [
      {
        who: "JOSS",
        want: "not show the olds his phone",
        wall: "Tito's already seen it and the shop TV runs the morning show anyway",
        turn: "the mockery arrives on its own — the morning-show smirk ('a charming, if off-key, moment'), the duet clips doing bits over the off-key old voices — and the olds watch one full clip in silence and go back to work",
        subtext: "the kid is ashamed of his own generation and can't say so",
      },
      {
        who: "EARLENE",
        want: "run her counter",
        wall: "a kid filming 'boomer diner check' content at booth three, complaining to his phone about rent",
        turn: "a COURIER walks a delivery burrito past her register and hands it to the kid at the booth — in a diner — and Earlene watches it happen and refills Buck's cup without a word",
        subtext: "the new country ordering out from inside the old one",
      },
      {
        who: "CRICKET",
        want: "run the Tuesday net like every Tuesday",
        wall: "there is nothing left to say into it",
        turn: "'Net's open. Tuesday, nineteen-oh-two local.' — static — a long time — 'Same time Tuesday.' — and he pulls the light cord",
        subtext: "lights out; the vow continues on momentum alone",
      },
    ],
    [
      "REQUIRED TV beat, placed mid-scene: the gift list GROWS — an anchor over a graphic of a suit on a mannequin: the Accord adds the Apollo suits to the gift program, one museum suit to accompany each flag; the first, with its flag, to the people of Iran. The olds hear this one standing still.",
      "The burrito-courier beat exactly as staged in the Earlene turn — no adult comments on it; the comedy must be dry and awful. The kid never notices anyone.",
      "The net beat is the scene's last: barn, rig glow, the shortest net ever, the light cord. NOBODY says anything resembling 'the country's gone.' The audience assembles it.",
      "Keep the whole scene under three pages; three locations (diner, shop TV corner, barn).",
    ],
  ),
  /* ---- v20 THE DECISION ----------------------------------------------------------- */
  mk(
    "v14-20-decision",
    "sc20_decision.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT",
    "The last pressure test passes. Six perfect boxes stand in a row, the trucks come in the morning, and the job that made staying near the flags honorable is over. Cricket looks at the crates a long moment, sits down on the edge of one, and starts unlacing his boots: 'Somebody time me getting in. We'll want a number.'",
    [V14Cast.cricket, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.tito, V14Cast.joss, V14Cast.mack],
    "a finished contract: final test, final signature, a shop with nothing left to build",
    "the midpoint: the decision is made without one word of decision-talk — a man lying down in the box he built, and three men answering with work; they go not to win but because it's true and somebody should stand there; the film never says any of that",
    [
      {
        who: "DUTCH",
        want: "close out the contract to his own standard",
        wall: "the standard is met — that's the problem",
        turn: "the gauge holds, he signs the federal completion sheet, squares it — and then stands looking at six boxes with nowhere to put his pencil",
        subtext: "the honor of the job expiring in real time",
      },
      {
        who: "CRICKET",
        want: "not go home",
        wall: "tomorrow the boxes leave and the men go back to being retired while their own handiwork carries the flags down",
        turn: "he crosses to crate D, sits on the edge, unlaces his boots: 'Somebody time me getting in. We'll want a number.' — Tito raps the crate wall twice: 'She'll hold.'",
        subtext: "the commander volunteers the only way he knows: procedurally",
      },
      {
        who: "GUNNY",
        want: "an order worth following",
        wall: "nobody gives it in words",
        turn: "he crosses to the parts shelf and starts counting scrubber cartridges into ranks of four, marking the shelf edge with a grease pencil; Stitch climbs into another crate, lies back, sets his hat on his chest: 'Snug.'; Dutch opens the binder to a fresh page",
        subtext: "assent, filed as logistics",
      },
    ],
    [
      "NO speeches, NO decision-talk, NO stakes named aloud. The entire commitment plays in actions after Cricket's line. Mack watches from the dark by the door and writes one line in the pocket notebook — we never see what.",
      "REQUIRED order: the final pressure test (two knocks — pause — two knocks answered from inside; the gauge holding; Tito climbing out with the wind-up watch); Dutch signing the federal completion paperwork; the hauling schedule chalked on the board — TRUCKS 7 AM; a long quiet with six crates in a row under the sodium lamps; then the bootlaces.",
      "The scene must be SHORT — two pages, the midpoint of the film, and the quietest scene in it. 'I'm current' must not appear (banned verbatim); nothing about readiness, rosters, or flying is said at all.",
    ],
  ),
  /* ---- v21 THE CONVERSION ------------------------------------------------------------ */
  mk(
    "v14-21-conversion",
    "sc21_conversion.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT (DAYS COMPRESSED)",
    "The crime, built like a barn project: Dutch redraws his own spec into a second set of drawings that live in the binder; Gunny buys drums of soda lime at a veterinary supply counter with cash; the oxygen was on the job's invoices all along, because it's a welding shop; Tito machines canisters; couches get upholstered; a grease-pencil air budget goes up a shelf edge.",
    [V14Cast.dutch, V14Cast.gunny, V14Cast.tito, V14Cast.joss, V14Cast.cricket, V14Cast.stitch],
    "a conversion montage: four flag crates quietly become four one-man ships",
    "minimum planning on a grand scale — a life-support system assembled from farm-store chemistry, welding-rig oxygen, and upholstery, by the four trades already standing in the room; the audience watches every piece bought and built so that later they believe every breath",
    [
      {
        who: "DUTCH",
        want: "engineer it to the same standard he'd sign for the government",
        wall: "the government must never see this drawing",
        turn: "two sets now: the federal sheet on the plywood table for inspectors, and his own revision living in the binder — couch, cartridge rack, four spares per unit",
        subtext: "the spec author forging his own spec, to a higher standard",
      },
      {
        who: "GUNNY",
        want: "the air problem solved the way the Navy taught him",
        wall: "you can't order life support without a paper trail",
        turn: "a veterinary supply counter, drums of soda-lime granules, cash — 'Y'all got surgery coming up?' / 'Something like it.' — and back at the shop, the grease-pencil math on the plywood: what a sleeping man burns in a day, swap every fifteen hours or so, ranks of four cartridges marked on the shelf edge",
        subtext: "two years under the ice, finally useful",
      },
      {
        who: "TITO",
        want: "machine canisters that cannot fail",
        wall: "no drawing he's allowed to show anyone",
        turn: "he works from Dutch's binder page and checks each canister twice with two knuckles; Joss runs the upholstery stations and stops asking questions",
        subtext: "the kids all the way in, never announced",
      },
    ],
    [
      "TEACH THE AIR ONCE, PLAINLY (this is the audience's life-support lesson, delivered as Gunny's shop math, not exposition): the granules soak up the breath a man puts out; a sleeping man burns about so much a day; swap the canister on a schedule; oxygen comes from the welding bottles already on the invoices. One grease-pencil beat carries all of it. No other technical explanation anywhere in the scene.",
      "REQUIRED beats: the vet-supply counter exchange (two lines maximum); the welding-oxygen pallet arriving on a legitimate invoice, nobody looking twice; the upholstered couch taking a man's shape; purge lines still run where nobody will ever see them; Dutch's two-drawings beat played as one INSERT each — the federal sheet on the table, the revision in the binder.",
      "Montage discipline: mini-slugs, short beats, the work loud and the men quiet. Maximum two and a half pages.",
    ],
  ),
  /* ---- v22 MACK FINDS OUT + TRADECRAFT --------------------------------------------------- */
  mk(
    "v14-22-mack",
    "parked_sc22_fused.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT",
    "Mack, who books the freight, knows what six empty archival boxes should weigh — and his own scale disagrees by thirty kilos, four times. He walks the shop at night, lifts one tarp, and calls the room to the plywood table: 'Nothing on this manifest breathes, gentlemen.' By midnight he's in, and the operation goes paper-and-airwaves: letters, the ham schedule, a book cipher, and cover stories for July.",
    [V14Cast.mack, V14Cast.cricket, V14Cast.gunny, V14Cast.dutch, V14Cast.stitch, V14Cast.joss, V14Cast.tito, V14Cast.danny],
    "the fixer catches the caper by arithmetic, joins it by choice, and then teaches it to move like 1775",
    "the man of paper discovers the one thing paper can't explain and chooses the country over the contract; then the whole conspiracy drops off the grid — handwritten, scheduled, enciphered — because the one playbook the surveillance state can't model is the Revolutionary one",
    [
      {
        who: "MACK",
        want: "an explanation for thirty kilos, four times",
        wall: "he already knows; he wants to hear them say it",
        turn: "the tarp comes up off a couch shaped like a man — at the table: 'Nothing on this manifest breathes, gentlemen.' — Cricket answers in checklist grammar, plain, complete — Mack: 'You understand there's no backing out once you're up there. Bad heart at four g's, your age, no doctor closer than a quarter million miles.' / GUNNY, not unkindly: 'Boone, I've buried better men than me for worse reasons than this. Sit down or go home. Either's fine. Quit standing there doing arithmetic on our behalf.' — a beat — Mack sits, and takes out his pen",
        subtext: "his signature is the most expensive one in the room and he spends it",
      },
      {
        who: "JOSS",
        want: "to be told what he's part of",
        wall: "he's known for days",
        turn: "'You're all insane. What do you need from me?' — and Tito raps the crate wall twice",
        subtext: "the kids choose in, out loud, once",
      },
      {
        who: "DANNY",
        want: "carry his share without ceremony",
        wall: "the cipher is homework and the cover story is a lie he'll tell the whole county",
        turn: "the kitchen-table cipher drill ('Fourteen. Two. Nine.' … 'That's a grocery list.' / 'This week it is.') and the cover-story round — Gunny: his sister's, Montgomery; Stitch: airplane parts, Wichita, 'true enough'; Dutch: the archival-standards conference in Dayton — beat — 'There is one.'; Danny, assigned his father's: 'Fishing.'",
        subtext: "the family absorbs the operation the way it absorbs everything: practically",
      },
    ],
    [
      "REQUIRED tradecraft beats after Mack joins: 'From tonight, everything changes how it moves. Nothing electronic. No phones, no email, no cloud. Nothing with a battery you didn't build yourself.'; JOSS: 'Then how do two hundred guys and four states coordinate a—' / DUTCH: 'Handwritten letters. The ham net, on schedule, in code. A book cipher.'; the swollen 1971 Reader's Digest on the table; JOSS: 'That's insane. That's — that's Revolutionary War stuff.' / GUNNY: 'They've got every algorithm ever written. We've got Valley Forge.'; envelopes addressed TRI-COUNTY FEED COOPERATIVE, RE: PARTS going into rural mailboxes, little red flags up; Tito's film camera — two frames of the finished couch, the canister into a Folgers can half-full of them, the can into the bottom of his toolbox.",
      "Mack's discovery must be shown as ARITHMETIC first (freight booking sheet, his own scale, the four heavy lines) then the tarp — no dialogue until the table.",
      "Cricket's answer to 'nothing on this manifest breathes' must be a plain, complete statement of the plan in under four sentences — no oratory, no theme, the way he'd read a checklist. This is the one place the plan is said out loud in the whole film.",
    ],
  ),
  /* ---- v23 PHYSICALS ------------------------------------------------------------------ */
  mk(
    "v14-23-physicals",
    "sc23_physicals.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - DAY",
    "Dutch's condition, self-imposed now that they're going: 'NASA wrote a physical in 1968. It is the last standard that ever mattered, and it is the one in this binder. We do all of it or none of it.' Step box, eye chart, waivers page nine, and a man in a sealed crate with a wind-up timer and four twenty-dollar bills under a socket wrench.",
    [V14Cast.dutch, V14Cast.cricket, V14Cast.stitch, V14Cast.gunny, V14Cast.joss, V14Cast.tito],
    "four old men administer themselves a fifty-eight-year-old flight physical",
    "seriousness as self-respect: nobody requires this of them — that is exactly why it must be done to the letter; the comedy and the discipline are the same thing wearing two faces",
    [
      {
        who: "DUTCH",
        want: "the 1968 standard, complete, documented",
        wall: "the examinees are 71 to 79 years old",
        turn: "waiver, page nine — 'There were waivers in '68 too. Compensating technique documented.' — and at the end, four carbon forms filed in the rings: 'Same result as 1968. All four.' … 'Slower on the step box. All four of you. I wrote it down.' / STITCH: 'Best year there ever was.'",
        subtext: "the standard bends where it always bent and holds where it always held",
      },
      {
        who: "CRICKET",
        want: "pass",
        wall: "a four-hundred-dollar smartwatch",
        turn: "steady the whole count; JOSS: 'Two minutes post-exercise… fifty-four. Resting fifty-one. Old dude's resting heart rate embarrassed my watch. My watch cost four hundred dollars.' — none of the old men react at all; Joss walks the watch to the coffee can and drops it in",
        subtext: "the body kept the vow too",
      },
      {
        who: "GUNNY",
        want: "win the crate test",
        wall: "an hour sealed in the dark with a timer",
        turn: "the timer rings, the lid lifts, he sits up unhurried and looks at the money under the wrench: 'Whose twenty is on top?' / JOSS: 'Mine.' / 'It's mine now, son.'",
        subtext: "the Navy trained him for exactly this and he knows it",
      },
    ],
    [
      "REQUIRED: the fresh-printed carbon forms matching a fifty-eight-year-old original — FLIGHT CREW MEDICAL EXAMINATION — STANDARDS OF 1968; the eye chart all the way across the warehouse (STITCH: 'Bottom line's got a print date on it. You want that too?' / DUTCH, writing: 'Line eleven. Nobody reads line eleven.'); Stitch's knee cracking loud on the fourth step, cadence unchanged — nobody says anything about it; the crate test with the lid down and the timer ticking; Cricket whittling a pine peg to fit a knothole while they wait.",
      "The scene is post-decision: everyone knows why the physicals matter, so NOBODY asks why they're doing them. Joss's energy is horrified-committed, not confused.",
    ],
  ),
  /* ---- v24 PROOF OF CONCEPT ------------------------------------------------------------ */
  mk(
    "v14-24-proof",
    "sc24_proof.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT",
    "Mack won't bet four men on a paperwork trick nobody's tested: 'Before I trust that warehouse with y'all, I want to watch it lose something small.' The test article comes home on a flatbed a week later, stenciled SCRAP — LOT 44-C, sold as non-functional to the Tri-County Feed Cooperative: Cricket's simulator, gauges unbroken, labels facing the sky.",
    [V14Cast.mack, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny],
    "a dry run: pull one seized item through the federal disposal channel and see if the warehouse leaks",
    "the trick that will later free the suits is proven here on the most sentimental object in the film — and played entirely as logistics; the country's machinery works for them the moment the paperwork says scrap, and the commander gets his church back as a side effect nobody names",
    [
      {
        who: "MACK",
        want: "proof the disposal channel leaks on demand",
        wall: "one wrong line on a lot sheet and a federal warehouse learns his name",
        turn: "he says the plan in two sentences ('Before I trust that warehouse with y'all, I want to watch it lose something small.') and picks the test article off the seizure inventory — item one, the trainer",
        subtext: "recon disguised as a gift; the gift is real anyway",
      },
      {
        who: "CRICKET",
        want: "sign for a delivery like any delivery",
        wall: "it's his simulator on the flatbed",
        turn: "the DRIVER's clipboard — 'Sign for lot 44-C. Scrap conveyance, buyer's copy. Somebody paid the freight to here, don't ask me who, I drive.' — INSERT the buyer line: SOLD TO: TRI-COUNTY FEED COOPERATIVE — Cricket reads the line items (HOMEBUILT TRAINER COMPONENTS. DISPOSITION: SOLD AS SCRAP — NON-FUNCTIONAL.), looks at the intact panels: 'Says non-functional.' / DRIVER: 'It does say that.' — he signs",
        subtext: "the state's own paperwork declaring his life worthless is the mechanism that returns it",
      },
      {
        who: "DUTCH",
        want: "the Tuesday net back to full strength",
        wall: "none",
        turn: "the trainer bolted down through the same four holes, the orange SCRAP stencil left on the couch rail on purpose; 'Net's open. Tuesday.' / 'There he is.' / 'Bus B. What's it read.' / 'Twenty-eight point four. Better than it left.' / GUNNY: 'Run your card, Commander.' — and above the panel, taped where a mission patch would go, the folded pink county seizure sheet",
        subtext: "the congregation rebuilt; the vow resumes mid-sentence",
      },
    ],
    [
      "The test's PURPOSE is stated once, plainly, by Mack, BEFORE the delivery — the audience must understand this is the warehouse trick's dry run, so the suit heist later needs no explanation. No other explanation of the mechanism anywhere.",
      "REQUIRED: the flatbed with VALLEY SALVAGE & SURPLUS on the door; every piece wearing fresh orange SCRAP — LOT 44-C stencils; the driver's two-o'clock-in-Ogallala impatience; 'Barn's where it was.'; the reassembly quick — breakers in the practiced order, the amber bus light steadying; keep the net exchange to six lines.",
      "The scene ends on Cricket's hand on the throttle and 'Guidance internal.' — the drill resuming, now with a destination nobody names.",
    ],
  ),
]

/* ---- runner ---------------------------------------------------------- */
let runOne = async (j: job) => {
  let path = Cinema_Backends.Path(j.out)
  let done_ = existsSync(j.out) && Write.verify(path) == Ok()
  if done_ {
    Js.log("SKIP " ++ j.seed.id ++ " (verified)")
  } else {
    let sc = await Write.writeScene(~seed=j.seed, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    let sc2 = await Write.liftDialogue(~path, ~maxTries=3)
    let _ = Write.emit(sc2, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("OK   " ++ j.seed.id)
    | Error(m) => Js.log("BAD  " ++ j.seed.id ++ " — " ++ m)
    }
  }
}

let main = async () => {
  let failed = []
  let n = Belt.Array.length(jobs)
  let rec go = async i =>
    if i < n {
      let j = jobs[i]
      switch await (async () => await runOne(j))() {
      | _ => ()
      | exception Write.WriteError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (gate): " ++ m)
        }
      | exception Session.SessionError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (session): " ++ m)
        }
      }
      await go(i + 1)
    }
  await go(0)
  Js.log(
    "ACT 2A DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
