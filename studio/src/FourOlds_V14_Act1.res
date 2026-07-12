/* THE FOUR OLDS v14 — ACT 1 (scenes 01–13), engine-only, resumable.
   Run: CLAUDE_STUDIO_BUDGET=35 node src/FourOlds_V14_Act1.res.mjs
   Skips any scene whose output already verifies. */

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

let jobs: array<job> = [
  /* ---- v01 COLD OPEN ------------------------------------------------ */
  mk(
    "v14-01-cold-open",
    "sc01_cold_open.scene.txt",
    "INT. CABLE NEWS STUDIO - NIGHT",
    "Cold-open montage: a smiling revolution wins, apologizes, pays, and bans the fireworks — and one old man at a diner counter says 'Huh.' Ends CUT TO BLACK, title card THE FOUR OLDS.",
    [V14Cast.marwani, V14Cast.hale, V14Cast.buck, V14Cast.earlene],
    "an election-night montage of a new administration's first months",
    "everything taken in this montage shrinks in scale and grows in intimacy — from a hemisphere's defense money down to one town's fireworks — teaching the audience the machine's direction of travel without one word of commentary",
    [
      {
        who: "MARWANI",
        want: "open his presidency as a healing",
        wall: "none — the wall is the audience's",
        turn: "each triumph of repair lands as a quiet theft somewhere small",
        subtext: "the smile is the weapon",
      },
      {
        who: "BUCK",
        want: "drink his coffee",
        wall: "the radio, near zero volume, announcing the fireworks ban",
        turn: "he turns his cup a quarter turn and says 'Huh.' and drinks",
        subtext: "the first pressure reading on the gauge this movie keeps returning to",
      },
    ],
    [
      "REQUIRED sequence, regenerate in style: (1) election-night studio — the board flips, balloons on the news desk, a bedsheet in the crowd reading HISTORY IS HEALING, a silver-haired COMMENTATOR wet-eyed on camera about 'reconciliation with a world the last administration spent years insulting'; (2) inauguration — Marwani at the podium, UN flag beside the fifty stars at equal height: 'I do not stand here to celebrate a victory. I stand here to begin a repair. On behalf of the United States — to every nation we have wronged — we are sorry.' and 'This is not retreat. This is not surrender. This is repair.' — chyron: NOBEL COMMITTEE AWARDS PEACE PRIZE, CITING 'THE ANNOUNCED AGENDA.'; (3) a C-17 cargo bay — shrink-wrapped pallets of banded hundred-dollar bills, manifest stamped IRAN COMPENSATION FRAMEWORK — DISBURSEMENT 1 OF 12, a young State Department aide turning his back to the pallets to take a selfie, then a better one; (4) Brussels — the Treasury Secretary signs a phone-book-thick document, champagne, chyron U.S. COMMITS $200 BILLION TO EUROPEAN DEFENSE RENEWAL over an all-red stock ticker; (5) a phone screen — push alert: WHITE HOUSE UNVEILS 'STEWARDSHIP ACT' — PRIVATE ASSETS ABOVE $1B TO BE ADMINISTERED IN THE PUBLIC INTEREST — a thumb swipes it away, another lands; (6) Senate hearing — MAGNUS HALE alone at the witness table reading one prepared line in a dead voice: 'Frontier is proud to serve the goals of this administration, at home and beyond it.' — a SENATOR savoring the word 'Nationalization.' — Hale folds his page in half, and in half again, and says nothing; (7) Roy's Diner, morning — six regulars, muted TV cycling the montage's own images, and a radio at near-zero volume announcing the nationwide ban on private fireworks under the carbon framework — nobody moves to turn it up — Buck turns his cup a quarter turn: 'Huh.' — he drinks. CUT TO BLACK. Centered title: THE FOUR OLDS.",
      "Marwani's broadcast lines may use his TED-triad cadence — the quarantine permits rule-of-three ONLY inside his speeches, as satire. No other voice in the scene may.",
      "Broadcast texture (chyrons, tickers, signage) is quoted world-text — render in CAPS inserts. The montage must read fast: this is the one sequence in the film allowed to sprint.",
    ],
  ),
  /* ---- v02 BANK ------------------------------------------------------ */
  mk(
    "v14-02-bank",
    "sc02_bank.scene.txt",
    "INT. FIRST PLAINS BANK, BROKEN BOW, NEBRASKA - DAY",
    "Cricket, folder squared on his knees, comes about the county's reassessment; a decent young loan officer finds a fifty-year-old $0.00 quarterly deposit from NASA on the account — DAWES, E. — ASTRONAUT (ACTIVE) — and Cricket, too fast and too hard, tells him to leave it.",
    [
      V14Cast.cricket,
      {
        name: "OFFICER",
        who: "the loan officer, 30s, tie too new, decent under the branch script; ends the meeting quietly breaking a rule for an old man.",
        register: "customer-service plain fraying into human; reads his screen half to himself.",
        earnsEloquence: false,
        lexicon: "retail-banking plain.",
      },
    ],
    "an old farmer asks his bank for time; a clerk finds an odd payroll line; a small kindness with a date stamp",
    "the $0.00 line is the movie's loaded gun — a fifty-year clerical truth nobody ever closed — planted here as a joke so it can win the war at the climax; and the officer's stamp is the film's first quiet defection",
    [
      {
        who: "CRICKET",
        want: "sixty days on the assessment, obtained with his dignity intact",
        wall: "the hardship program is 'suspended pending alignment review' — federal now, no mechanism, no date",
        turn: "the officer finds the NASA line and offers to scrub it; Cricket's 'Leave it.' comes out too fast and too hard — the one crack in the visit",
        subtext: "the file is the last thing that still says what he is",
      },
      {
        who: "OFFICER",
        want: "get through a flooded-culvert week",
        wall: "a system with no mechanism and a customer with sixty-one years on the books",
        turn: "the scanner's 'been down' — he stamps the paperwork received next cycle, sixty days of air, 'Don't tell my branch manager.' — and after Cricket goes he looks at the screen: 'Every quarter, huh.'",
        subtext: "the country's people start choosing sides early, in stamps and stamps only",
      },
    ],
    [
      "REQUIRED beats: the culvert phone call he's finishing as Cricket sits ('That's the county's. Tell him to call Roads.'); Cricket's tabbed folder, fifty years of order; the county letter — four thousand two hundred six dollars, due the fifteenth, against two thousand one hundred; the suspended-program screen read half to himself ('It's paused. Not paused — there's no — there isn't a mechanism right now. Is what that means.'); ON HIS SCREEN: NASA — $0.00 QUARTERLY, account description DAWES, E. — ASTRONAUT (ACTIVE); the scrub offer; 'Leave it.' too fast, then level again: 'It's been there fifty years. It can stay.'; the date-stamp kindness and the carbon copy; 'What do I owe you?' / 'It's a bank, Mr. Dawes. You owe us four thousand dollars.'; Cricket's culvert advice at the door (Route 12 by the Hollen place, log chain and a tractor, hour of work) and the two-finger no-look wave; the officer watching him go: '...I'll pass that on. Every quarter, huh.'",
      "END: the parking lot — Cricket alone in the truck, the courthouse flag through the windshield; his shoulders come down half an inch, one long breath; dry, to himself: '\"Working for communities like yours.\"' — almost a laugh, not quite; he starts the truck.",
      "The Stewardship Act cardboard sign by the door (THE STEWARDSHIP ACT — WORKING FOR COMMUNITIES LIKE YOURS) plants the parking-lot line.",
    ],
  ),
  /* ---- v03 BARN NET --------------------------------------------------- */
  mk(
    "v14-03-barn-net",
    "sc03_barn_net.scene.txt",
    "INT. DAWES BARN - NIGHT",
    "The Tuesday net: four old men run lunar-descent rehearsal number 2,806 the way other men play cards — a fifty-year ritual that is equal parts checklist and argument, tangent and touchdown. The crew is the protagonist, and this is where the audience falls in with them.",
    [V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny],
    "four old friends run their weekly Moon-landing rehearsal by ham radio — a barn simulator, three far-off voices, fifty years of cross-talk",
    "the friendship and the procedure are one thing: four registers so worn into each other that they bicker THROUGH a lunar descent and go silent at the same instant without anyone asking — the audience must leave knowing these men could do this dead, have never once stopped, and would rather be on this net than anywhere on Earth",
    [
      {
        who: "GUNNY",
        want: "the net run to standard, as it has been for fifty years",
        wall: "Stitch exists",
        turn: "his roll call is delivered with FULL military ceremony — for a barn, on a Tuesday, to three old men — 'Apollo Eighteen. Lunar descent rehearsal. Number two thousand, eight hundred and six.' — and the solemnity at that scale IS the joke, and nobody laughs, which is the bigger joke; the men fall in behind it, to a point, never fully, which is also the standard",
        subtext: "reverence applied to a shed; the count lands as a laugh first and a lump after",
      },
      {
        who: "STITCH",
        want: "to tell the net something mundane AS LEGEND — pick ONE concrete tangent (a neighbor's estate auction, a funeral where the casket turned out to be veneer, somebody's new hip) and let him build it like it's the Iliad, numbers rounding up as he goes",
        wall: "checklist discipline, personified in Gunny — and Dutch, who has documentation",
        turn: "told to keep the net clean, he answers with some version of the truth that after fifty years of Tuesdays the Moon is not going to sneak up on anybody — in HIS drawl, not those words — and keeps right on building the legend while the descent runs underneath him; Dutch corrects a figure from an actual record and the argument escalates on facts nobody on Earth could care about, played dead straight by both",
        subtext: "wonder versus documentation, the oldest fight on the net; the tangents ARE the ritual",
      },
      {
        who: "DUTCH",
        want: "the Bus B fault taken seriously, and the record to show he called it",
        wall: "it is a forty-year-old relay, every man on the net has heard about it for years, and gloating is beneath the standard he holds himself to",
        turn: "the fault actually walks mid-descent — and his fix crosses three states by ear: kick it, low left corner; the kick lands, the needle climbs home — and Dutch's attempt NOT to gloat, and its failure by exactly one dry sentence, is the funniest beat in the scene",
        subtext: "he has waited years for this moment and must pretend he hasn't",
      },
      {
        who: "CRICKET",
        want: "fly the card, clean, through all of it",
        wall: "his crew's noise — which he would not trade for silence",
        turn: "he flies THROUGH the bedlam, deadpan readouts landing as the punctuation of other men's jokes — and at three hundred feet the net goes quiet on its own, nobody calls for it, fifty years of knowing when to shut up — CONTACT light — 'Contact light. Engine stop.' — one beat of real quiet, the scene's single earned spike — and then the comedy is back inside two lines: Stitch's throttle critique, Gunny's 'The man is on the ground, Colonel.'",
        subtext: "the landing matters because the talking stops for it — and the movie breathes laugh-spike-laugh",
      },
    ],
    [
      "FULL PLAYING — three to three and a half pages. The hangout is the content and the drill is the spine: calls and readouts must INTERLEAVE with the tangents line by line (an altitude call landing in the middle of an argument about a casket is the scene working). Do not park the chatter and then run the drill, or vice versa — braid them.",
      "OPEN on the trainer reveal per the calibration example in studio/SCREENPLAY_STYLE.md — the pull-cord CLICK, the APOLLO PROCEDURES TRAINER, hand-machined gauges, the crew couch in a welded cradle, the triangular window, the painted Moon on the barn wall, then ALONG THE BACK WALL -- the spiral notebooks floor to roof, every spine dated in the same block hand, the first shelf starting in 1972.",
      "CIVILIAN LEGIBILITY, once, plainly: Gunny's roll call names the mission and the count — Apollo Eighteen, lunar descent rehearsal, number two thousand eight hundred and six — so any viewer knows exactly what these men do every Tuesday and for how long. The number is the fifty years, said without saying it.",
      "THE TANGENTS: one main tangent (Stitch's — concrete, mundane, funny in its seriousness) plus at least one old grievance WITH A DATE on it (Dutch keeps logs — a missed net or an old repair gets cited by month and year, and the accused defends himself). Each tangent characterizes its speaker per his card: Stitch rounds and embroiders, Dutch corrects with logged data, Gunny polices, Cricket answers in readouts. The focus-demand beat lands off-center: focus is demanded; the fifty-years answer is given; the demand loses.",
      "REQUIRED kept beats: 'Net's open. Tuesday, nineteen-oh-two local.'; the Bus B relay history ('I'm allowed to say it.' energy); the mid-descent fault — needle walking, 'Steady or does it stutter?', 'Kick it, low left corner.', the kick, the needle home, no comment after; the silence arriving on its own from three hundred feet; contact light — 'Contact light. Engine stop.'; the beat of quiet; the throttle critique and 'The man is on the ground, Colonel.'; 'Net closed. Same time Tuesday.' / 'God willing.'; the two-click sign-off answered around the net; the fresh page in ballpoint block letters: T+2,806. BUS B CORRECTED. CONTACT 19:41. CREW PRESENT BY RADIO.; the thumb run down the dated spines; the padlock tested with one pull; the farmhouse beyond with no lights on inside.",
      "Bus B / relay / inverter jargon is legal here: the visible event (needle drops, kick, needle climbs) carries all the meaning; the words are texture of a fluent room and nothing rides on them.",
      "Nobody mentions Peg. The empty house says it.",
    ],
  ),
  /* ---- v04 DANNY'S CALL / ACCORD -------------------------------------- */
  mk(
    "v14-04-accord",
    "sc04_accord.scene.txt",
    "INT. DAWES FARMHOUSE, KITCHEN - NIGHT",
    "Danny calls: 'Maybe don't watch the news tonight.' Cricket watches it. Marwani announces the Lunar Heritage Neutralization Accord — the six Apollo flags to be retrieved and gifted to the nations America has wronged, live on the first Unity Day, July fourth. A pencil snaps in an empty parlor, and the Tuesday net becomes something else the same night.",
    [V14Cast.cricket, V14Cast.danny, V14Cast.marwani, V14Cast.dutch],
    "a son's warning call, a presidential broadcast, and two old men agreeing to meet early",
    "the regime's masterstroke is aimed at the one thing in Cricket's life that never lowered its flag — and his answer is not grief but scheduling",
    [
      {
        who: "DANNY",
        want: "soften a blow he can't name over the phone",
        wall: "his father answers feelings with courtesy",
        turn: "'Maybe don't watch the news tonight.' — 'Thank you for calling.' — and Cricket walks straight to the television",
        subtext: "the family's whole grammar in four lines",
      },
      {
        who: "CRICKET",
        want: "hear it all the way through, standing still",
        wall: "the announcement is built to be unanswerable — generous, warm, adored",
        turn: "the pencil snaps in his hand, one half, no sound but the small one, nobody there to see it; then he dials Dutch from memory: 'You watching this?' … 'Tuesday. Early.'",
        subtext: "rage filed as an appointment",
      },
    ],
    [
      "REQUIRED broadcast content (Marwani, on TV, triads permitted): the Accord named in full; 'Fifty-seven years ago, one nation planted its banner on ground that belongs to all mankind… it stayed through every apology we owed and never gave.'; the science claim that the flags are bleached white — over a graphic: the Aldrin-salute archive photo beside a boiled-white rendering captioned ARTIST'S RENDERING — CURRENT CONDITION; 'Some call those flags of surrender. I call them flags of peace.'; retrieval broadcast live this coming July fourth — 'Not Independence Day. This year, the first Unity Day.'; the gift plan — one flag to each nation America has wronged, the first to the people of Iran; the Harmony Banner, designed by a committee of forty-four nations.",
      "REQUIRED beats: Danny's call small-talk first (roads, the sale barn, Rachel says hi), the TV muted behind him; supper cleared for one; the pencil doing long division on the county letter before the phone rings; the anchor's button — '— being called the most generous act in the history of spaceflight.'; the remote set down square on the arm cover; the wall-phone dial from memory, seven digits then four more; Dutch: 'Both channels. They're running that white mock-up every ten minutes.'; neither man says anything for a moment; 'Tuesday. Early.' — the cradle hung gently.",
      "The kitchen and parlor play EMPTY around him — one plate in the rack, no second chair pulled out. Never stated.",
    ],
  ),
  /* ---- v05 CUT (Pell/Holloway dashboard) — pressure folded into v06 ---- */
  /* ---- v06 THE SEIZURE -------------------------------------------------- */
  mk(
    "v14-06-seizure",
    "sc06_seizure.scene.txt",
    "EXT. DAWES FARM - DAY",
    "Two black SUVs and a county flatbed. Pell executes the federal recovery of the simulator — polite, papered, smiling — while Wade, the deputy Cricket taught to drive a tractor, does the part of the job that needs a human being. Duel #1 between Pell and Cricket. The barn ends half empty and the net opens anyway.",
    [V14Cast.cricket, V14Cast.pell, V14Cast.wade, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny],
    "a federal asset recovery at a family farm, executed correctly in every particular",
    "two theories of ownership collide — care against paperwork — and paperwork wins the day while care wins the audience; Pell meets the man whose file will end his career and neither knows it",
    [
      {
        who: "PELL",
        want: "close the parcel clean and be liked while doing it",
        wall: "an old man standing square in a doorway, and a barn that is obviously a shrine",
        turn: "he wins — the dolly rolls past — but only by handing the human part to Wade; his exit line is a bumper sticker: 'Folks, I know change feels sudden. But as the Accord reminds us — harmony is a verb.'",
        subtext: "the enforcer needs to believe he is gentle",
      },
      {
        who: "CRICKET",
        want: "keep the trainer without giving them one visible inch of feeling",
        wall: "three separate systems that don't wait on each other, and the law is theirs",
        turn: "'You'll have to move me, Wade.' — and Wade does, with both hands, gently, and Cricket lets him, because it's Wade",
        subtext: "he chooses who is allowed to touch him",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "OPEN with PELL'S PRESSURE IN ONE BEAT (replaces the cut dashboard scene): Pell in the passenger seat of the lead SUV coming up the drive, finishing a call on speaker, phone in a dashboard mount — his boss's voice tinny and bored: one big verified recovery on the books by Saturday or Pell's office gets folded into Lincoln's. Pell, bright, to the phone: 'You'll have it.' — hangs up, checks his hair in the visor mirror, and steps out already smiling. Thirty seconds, civilian-clear, no dashboards, no quotas explained; the comedy is the mirror-check between the threat and the smile.",
      "REQUIRED exchanges, keep exact even where they brush the general bans (approved canon): Pell reading the inventory — 'one altitude indicator—' / CRICKET: 'Attitude.' / the pen correction / 'Noted.'; CRICKET: 'It was surplus. Nineteen seventy-five. Told it'd be scrapped otherwise.' / PELL, not looking up: 'Paperwork says otherwise.'; CRICKET, quiet and hard: 'Not one of you ever built a thing out here. Now it's all yours.' / PELL, finally looking at him, not reciting: 'You didn't build this either, Mr. Dawes. Nineteen seventy-five, it should've gone back to NASA and it never did, and nobody asked why for fifty years. That's not building. That's theft with enough of a head start to feel like inheritance.' — Cricket doesn't answer that; the orange sticker smoothed with a thumb (LUNAR HERITAGE NEUTRALIZATION ACCORD — EX-NASA ASSET RECOVERY); Pell at the logbook wall pulling one notebook, three pages of grid-ruled block printing: 'Personal papers.' … 'No salvage value. Leave them.' dropped back crooked; the doorway stand and 'You'll have to move me, Wade.'; WADE's low county-vs-federal explanation ('Federal list came down Tuesday… county don't see a dime. Nobody does.') and the warehouse answer ('Warehouse outside Lincoln, is what I hear. Same one as the rest of it.'); the appeal-window kindness ('It's open till four.'); Pell's harmony-is-a-verb exit.",
      "PELL PLAYS COMIC-FIRST: a man who needs to be LIKED by the people he is dispossessing — he compliments the barn's construction while inventorying it, thanks people for patience they haven't shown, and delivers 'harmony is a verb' like a gift. The menace is the after-taste, never the surface.",
      "REQUIRED small beats: the mover's barked knuckle and Cricket handing him the correct socket off the pegboard — the man can't look at him; the fresh-painted porch boards under the movers' boots; the dust rectangle with bolt holes where the trainer stood; Cricket alone at its edge — one hand pressed hard to the back of his neck, one breath, then straight again; the workbench radio they left; 'Net's open. Wednesday.' answered fast by all three; the work light pulled on.",
      "Wade's walk-him-aside must be gentle and wordless past 'Earl.' — the violence of the day is that there is no violence.",
    ],
  ),
  /* ---- v07 FIREWORKS PROTEST -------------------------------------------- */
  mk(
    "v14-07-fireworks",
    "sc07_fireworks.scene.txt",
    "INT. DAWES BARN - NIGHT",
    "The net wants to answer the seizure with a big loud middle finger: mortar shells over the compliance office's empty lot. Cricket says no — he has a grandson. Three old men do it anyway, get cited by Wade, plead guilty to Judge Benning, and get time served plus the cost of the gravel. Cricket is waiting at the bottom of the courthouse steps to drive them home.",
    [V14Cast.cricket, V14Cast.gunny, V14Cast.stitch, V14Cast.dutch, V14Cast.wade],
    "a protest, three arrests, a nine-minute court appearance, and a ride home",
    "the crew's first act of defiance is a firecracker where the country needs a cannon — and the town's institutions (a deputy, a judge) quietly refuse to treat their own as criminals; the release valve proves the pressure",
    [
      {
        who: "GUNNY",
        want: "answer the sticker gun with black powder",
        wall: "Cricket's flat no",
        turn: "'Rest of us, then. Friday.' — and Cricket: 'Do what you're going to do. Just don't tell me about it after.'",
        subtext: "the first crack in the crew — conscience pulling two directions",
      },
      {
        who: "CRICKET",
        want: "keep his people out of courtrooms",
        wall: "they went anyway, and part of him wishes he had",
        turn: "at the courthouse steps: 'Come to gloat?' / 'Came to drive you home.' … 'You could've come.' / 'I know it.'",
        subtext: "his no was real and so is his regret",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED net argument: Gunny's submarine credential in CIVILIAN language — 'I did two years on a missile submarine off Alaska, listening for Soviet propellers, so men like Earl could keep a barn a Russian couldn't touch. And a fella in a zip-up vest walks in with a sticker gun.'; his word for them — 'Commies. Don't care what flag they're flying over the building.'; Dutch's quiet history — the horse trailer to Houston in '75, the supply captain, 'if the truck showed up empty, that's what the truck would show. Fifty years I kept government property safe for the government. They sent a man to take it back like I stole it.'; the plan (compliance office closes at five, empty gravel lot, four cases of pre-ban mortar shells); CRICKET: 'That's a federal building.' / GUNNY: 'It's a strip mall with a flagpole, Earl.'; Cricket's refusal WITH the grandson: 'I've got a grandson who still thinks I hung the moon. Not explaining a courtroom to him. Count me out.'",
      "REQUIRED lot beats: the three of them unhurried; the first shell lighting the lot red then green then a long gold hang; Wade's arrival — hand nowhere near his holster, a look at the sky first: 'Y'all want to tell me whose idea this was, or should I guess?' / GUNNY: 'Mine.' / DUTCH: 'His, but I brought the truck.' / STITCH: 'I just held the lighter. Following orders.'",
      "REQUIRED courtroom: guilty on all counts, all three; nobody hurt, a scorched patch of gravel; JUDGE BENNING (70s, reading glasses low) — 'I was nine years old in my daddy's living room the night men from this state walked on the Moon. Watched it on a television the size of a bread box. Time served. Four hundred dollars each, plus the cost of the gravel. I've got real criminals on this morning's docket, gentlemen. Get on home.' — gavel before the prosecutor can object.",
      "END on the steps exchange and one hard clap on the shoulder. No music in the prose; let it be dry.",
    ],
  ),
  /* ---- v08 ROY'S DINER --------------------------------------------------- */
  mk(
    "v14-08-diner",
    "sc08_diner.scene.txt",
    "INT. ROY'S DINER - DAY",
    "Lunch at Roy's under the carbon meter: a Unity Day promo on the TV, a griddle quota letter by the register, Buck saying the quiet thing quietly, Wade's cup going unfilled — and the whole counter humming the anthem under a broadcast that replaced it, one verse, then back to forks.",
    [V14Cast.buck, V14Cast.earlene, V14Cast.cricket, V14Cast.wade],
    "a diner lunch scored by a compliance meter and a muted culture war",
    "the town's civic life is being metered, renamed, and re-scored — and its answer, this early, is sixty seconds of humming; the audience learns the town's temperature and the exact size of what defiance costs here",
    [
      {
        who: "BUCK",
        want: "say it out loud just once",
        wall: "Earlene's one-word police ('Buck.')",
        turn: "'Fifty years we kept commies off the Moon. All they had to do was win a primary.' / 'I said it quiet.'",
        subtext: "the barometer reads high and holding",
      },
      {
        who: "EARLENE",
        want: "run her counter her way",
        wall: "a deputy who cited three of their own this month",
        turn: "Wade's cup stays empty from three feet away; he leaves two dollars under the saucer and goes; later she quietly doesn't write Cricket's ticket — 'It's paid.'",
        subtext: "justice, administered in coffee",
      },
    ],
    [
      "REQUIRED texture: the gray county box zip-tied to the gas line, ticking up as the Cook works — COOK, to the box: 'Yeah, I see you.'; NEW escalation, small: a county letter taped by the register — the meter's WEEKLY ALLOWANCE line, and the Cook reading it once and going back to the flat-top without comment; the TV promo — a loft of matching UNITY DAY shirts cheering a countdown clock, crawl: 62 DAYS TO UNITY DAY — NATIONS OF HONOR ANNOUNCED FRIDAY; the panelist over the white rendering: '— this is a president finishing an argument America started losing in 1969—'.",
      "REQUIRED anthem beat: the Cook flips to the ball game; the PA on the broadcast introduces 'One World Rising' by a children's harmony choir; some of the crowd on screen stands, a lot doesn't; the Cook turns the sound down, not off; Buck starts humming into his coffee, four notes in it's the anthem; the spatula picks up the time against the grill edge, small, maybe not on purpose; Earlene hums the next bar counting a stranger's change; nobody stands, nobody looks at anybody; end of the verse, and the diner goes back to forks and plates.",
      "REQUIRED Wade beat: in uniform, eggs, hat crown-up; his cup empty a while; Earlene wiping the counter three feet from the pot; he doesn't look at the cup again, slides two dollars under the saucer, takes his hat, bell rings.",
      "REQUIRED Cricket close: end stool, coffee before he's square on the seat, no ticket written; Buck slides the sugar caddy within reach without looking up; 'It's paid.' / 'Obliged.' — cap on, bell, and through the window the courthouse flag across the square. The meter ticks. The Cook watches it a second and goes back to the grill.",
    ],
  ),
  /* ---- v09 PEG'S GRAVE ---------------------------------------------------- */
  mk(
    "v14-09-grave",
    "sc09_grave.scene.txt",
    "EXT. COUNTY CEMETERY - DAY",
    "Cricket sets zinnias on Peg's stone. Dutch, cap in both hands, asks his one factual question, and Cricket reports the one true thing: the kindest woman anybody knew watched Marwani on television for about a minute, said he was selling something, and never trusted him a day after.",
    [V14Cast.cricket, V14Cast.dutch],
    "two old friends at a grave; a few plain sentences about a late wife",
    "the family's resistance predates the war — Peg saw the salesman before the country did; everything the crew does for the rest of the film is the difference between what she recognized as fake and what real looks like, and nobody here says any of that",
    [
      {
        who: "CRICKET",
        want: "say the one true thing he came to say, then stop",
        wall: "fifty years of never discussing a feeling out loud",
        turn: "he reports it like an instrument reading: watched him maybe a minute, said he was selling something, never trusted him a day after — 'and you know she had a kind word for about everybody.'",
        subtext: "not a eulogy; a fact",
      },
      {
        who: "DUTCH",
        want: "be present without forcing grief into words",
        wall: "he owns no language for this",
        turn: "one small factual question — 'When'd she start in on Marwani.' — and later, 'Before he ever had the county, then.' — the whole of his comfort, and enough",
        subtext: "a spec question as an embrace",
      },
    ],
    [
      "CONTENT LOCKED from the approved engine scene — regenerate in v14 style without changing substance: the small county cemetery off a gravel lane, chain-link, mown grass going brown; zinnias in his fist ('Peg had these all down the fence line. Orange ones, mostly.'); the canning jar against the wind; grass clippings brushed off the stone with the side of a hand; 'First time the man was ever on the television. Watched him maybe a minute and said he was selling something.'; 'Long before. Made her mind up right there in the front room and never went back on it.'",
      "RUTHLESSLY SHORT — six to eight dialogue lines total. If a line sounds written for the occasion, cut it.",
    ],
  ),
  /* ---- v10 LEGION HALL ------------------------------------------------------ */
  mk(
    "v14-10-legion",
    "sc10_legion.scene.txt",
    "INT. AMERICAN LEGION POST 219, BACK ROOM - NIGHT",
    "Mack lays a federal cargo manifest on the table: six museum-grade containment units, riding up empty, to bring the flags down — and the procurement email recommending 'retired fabrication and aerospace personnel at heritage-labor rates.' The insult does the recruiting. Cricket walks out, comes back, and signs last: 'When's Monday.'",
    [V14Cast.mack, V14Cast.cricket, V14Cast.gunny, V14Cast.dutch, V14Cast.stitch],
    "a job offer in a Legion back room: build the boxes the flags come home in",
    "the regime outsources the coffin-making to the mourners to save money — and the mourners take the job because if the colors must come down, they will come down in boxes built by men who know how a flag is handled; nobody in the room knows yet what the boxes will become",
    [
      {
        who: "MACK",
        want: "four capable signatures on a legal contract",
        wall: "the job is an insult wearing a paycheck",
        turn: "he reads the email flat and lets the insult recruit them: 'Heritage-labor rates. That's you, gentlemen. That's this whole room.'",
        subtext: "he sells nothing; he shows them the door and they walk through it",
      },
      {
        who: "GUNNY",
        want: "refuse to let strangers touch the colors",
        wall: "somebody is going to build those boxes either way",
        turn: "'Somebody's going to fold those colors into them, on live television, with the whole world grading the job. I'd sooner it be men who know how a flag is handled than whoever else answers that email. We're the whoever-else, boys.' — and a short, hard, real laugh goes around",
        subtext: "honor rerouted through a loophole in his own fury",
      },
      {
        who: "CRICKET",
        want: "not be in this room",
        wall: "the room is right",
        turn: "he puts his cap on and walks out — the door bangs — then comes back in, reads the spec page standing, and signs last: 'When's Monday.'",
        subtext: "his yes must cost him the walk to the truck and back",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED artifacts: the manifest INSERT — LUNAR HERITAGE NEUTRALIZATION ACCORD — ARTIFACT RETRIEVAL. SIX (6) CONTAINMENT UNITS, CLASS-A ARCHIVAL. OUTBOUND CONFIGURATION: EMPTY.; the printed email read flat — 'Containment units are non-crew hardware. No certification pathway required. Recommend sourcing retired fabrication and aerospace personnel at heritage-labor rates.'; STITCH, quiet: 'Cheap old men. To box up the—' — he doesn't finish it, nobody finishes it; DUTCH off the spec page: 'This is my standard. The '98 archival spec. Word for word.' / MACK: 'Nobody's improved it.'; the confidentiality terms at the door — no phones, no pictures, nothing said outside the shop — STITCH: 'Confidential flag boxes.' / MACK: 'That's the job.'",
      "FORBIDDEN: no logbooks on the table, no readiness talk, no flying talk of any kind — this is a welding job being accepted by insulted men. Cricket's return beat is silent until 'When's Monday.'",
      "Room texture: wood stove, folding chairs squared by Gunny, a percolator, unit photos back to Korea; contract packets dealt like cards; only Dutch reads all of his.",
    ],
  ),
  /* ---- v11 BAY TWO CLOSES ---------------------------------------------------- */
  mk(
    "v14-11-baytwo",
    "sc11_baytwo.scene.txt",
    "INT. FRONTIER AEROSPACE, FABRICATION BAY 2 - DAY",
    "Vess closes Bay Two in front of the two hundred people it employs, takes the hate onto her own name on purpose, and Pell notes the 'posture of alignment' favorably. On his way out with his toolbox, Tito the welder gets three words from Mack that make no sense yet: keep your tools.",
    [V14Cast.vess, V14Cast.pell, V14Cast.tito, V14Cast.mack],
    "a layoff announcement on a factory floor, executed without a wasted word",
    "the regime thinks it is watching a company comply; it is actually watching the caper's labor pool being formed — every man walking out with a toolbox is a future pair of hands, and the only person who knows it is the one writing in a pocket notebook",
    [
      {
        who: "VESS",
        want: "close the bay in a way the Monitorship can't fault and her people can't mistake",
        wall: "two hundred faces that hate her",
        turn: "terms first, twelve months full rate, coverage, priority-rehire cards — 'I do not expect you to believe that means anything. Keep the card anyway.' — then: 'Whatever you need to think about today — put it on me.'",
        subtext: "she buys the regime's trust with her own reputation and pockets the receipt",
      },
      {
        who: "TITO",
        want: "leave with his dignity and his hood",
        wall: "his father's trade just ended in a memo",
        turn: "Mack, off the practice weld: 'Keep your tools.' / 'I just got fired, Mr. Boone.' / 'I know what happened. Keep your tools.' — and a line goes into the pocket notebook",
        subtext: "the first stone of the crew laid in plain sight",
      },
    ],
    [
      "REQUIRED beats: the ranks in company blues, hoods up, gloves off; WORKER: 'My father cut the first nozzle ring in this bay!' / VESS: 'I know he did. His name is on the wall of the visitor center.'; the tooling declared surplus for public auction, inventory palletized by an outside logistics contractor — Mack, at the back, unfolds his arms at that line; PELL leaning in with his tablet — 'the Monitorship views this as a — a meaningful posture of alignment. I'll be noting the, ah, expedited timeline favorably.' / VESS: 'Note whatever you like.' — her heels on concrete the only sound going out; LATER — toolboxes and milk crates past a news crew at the fence; Tito's practice weld on the bench, two plates joined by a bead like nothing else in the shot (describe plainly, no simile); the keep-your-tools exchange; Mack's one line into the pocket notebook.",
    ],
  ),
  /* ---- v12 PELL PROMOTED ------------------------------------------------------- */
  mk(
    "v14-12-promotion",
    "sc12_promotion.scene.txt",
    "INT. FEDERAL BUILDING, WASHINGTON - CONFERENCE ROOM - DAY",
    "Unity Day enforcement needs a face, and every senior person in the room has already made sure it won't be theirs. Holloway hands his most annoying subordinate the hot potato as a reward: Special Administrator, Lunar Heritage Recovery. Pell is the only man in the building who thinks he just won.",
    [V14Cast.pell, V14Cast.holloway],
    "a promotion meeting: a title conferred, hands shaken, a portfolio handed over",
    "dispose-by-promotion — the machine solves a personnel problem and a liability problem with one memo, and the man being disposed of experiences it as the proudest day of his career; nobody names any of this, ever",
    [
      {
        who: "HOLLOWAY",
        want: "the Unity Day enforcement portfolio off his desk and Pell out of his region",
        wall: "it has to look like a reward",
        turn: "he presents it as recognition — eleven years of clean closures, the Dawes recovery, a program that 'needs exactly this kind of rigor' — and the room's seniors study their notepads in unison",
        subtext: "generosity as waste disposal",
      },
      {
        who: "PELL",
        want: "to finally be seen",
        wall: "he is being seen with perfect clarity, just not the way he thinks",
        turn: "'I won't let the Accord down.' — nobody meets his eyes; somebody is already stacking the next agenda; he carries the portfolio out holding it with both hands",
        subtext: "the commendation photo from his field office, about to repeat at national scale",
      },
    ],
    [
      "The title, spoken once, in full: Special Administrator, Lunar Heritage Recovery — public-facing: press availabilities, the artifact program, certification authority over Unity Day cargo. One senior staffer, asked if her office wants to co-chair, has 'a scheduling conflict' before the sentence ends.",
      "Play the room's relief in physical behavior only — notepads, calendars, a door held a little too readily. No character may wink; Pell's pride must be real and a little touching. The audience does all the math.",
      "SHORT — a page and a half at most. End on Pell alone in the corridor with the portfolio, straightening his lanyard in the dark glass of a trophy case.",
    ],
  ),
  /* ---- v13 THE SHOP ----------------------------------------------------------- */
  mk(
    "v14-13-shop",
    "sc13_shop.scene.txt",
    "EXT. TRI-COUNTY AUCTION BARN - DAY",
    "The shop opens: a dead auction barn with good bones, drawings with a federal title block, two kids, a coffee can full of phones — and the moment the movie plants and refuses to water: the interior of a flag box is awful generous for cloth, a man could about fit in there, and the conversation just ends.",
    [V14Cast.mack, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.cricket, V14Cast.joss, V14Cast.tito],
    "first day in a rented shop: drawings unrolled, phones surrendered, stations assigned, one odd observation nobody follows",
    "the caper's engine is built here in front of the audience — the over-spec, the competence, the kids — and then deliberately NOT started; the plant must land as texture, not as foreshadowing with a spotlight on it",
    [
      {
        who: "DUTCH",
        want: "walk the crew through his drawings",
        wall: "a 24-year-old welder who improves them in front of him",
        turn: "Tito moves a purge line two inches with a pencil and Dutch looks at the fix, looks at the kid, and hands him the pencil",
        subtext: "the standard recognizing its heir",
      },
      {
        who: "JOSS",
        want: "figure out what this job actually is",
        wall: "everyone answers questions with work",
        turn: "his swap-theory ('we build fake ones and switch them, right? the flags never come down?') gets Mack's flattest answer: 'The play is we build six containment units to federal spec and deliver them on time. It's a job, son.' — and Joss drops it",
        subtext: "the audience's own theory, raised and parked",
      },
      {
        who: "TITO",
        want: "understand the interior mount he's building",
        wall: "the dimensions don't smell like cloth",
        turn: "DUTCH: 'Interior's awful generous for cloth.' / TITO, not looking up: 'Man could about fit in there.' / JOSS: 'How would a person even ride in a box.' / GUNNY, off the gauge he's checking: 'Most of it's already there. Air in, breath scrubbed back out. I kept ninety men breathing under the ice for two years.' — and MACK calls the next station, and the work resumes, and NOBODY returns to it",
        subtext: "the idea enters the room, is fully explained, and is left sitting on the table like a part nobody ordered",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED: the barn reveal (sodium lamps banging on row by row over an empty auction floor, gantry crane, scale pit, loading docks — Mack: 'Client's a federal contract and a county landlord. Cheaper than a real shop.'); the coffee can — GUNNY: 'Son. Phones.' / JOSS: 'It's a WATCH.' / 'Can, son.'; the drawings with the federal contract number in the title block; Tito's fillet-vs-full-penetration exchange and the purge-line fix ('Heat's going to cook your fitting. Move it here, come in under the frame rail, nobody ever sees it.'); Dutch handing the pencil.",
      "THE OVER-SPEC BEAT is the scene's reason to exist and must play EXACTLY as beat 3 specifies: four lines, then work. No lingering looks, no silence held a beat too long, no camera hanging on the crate. The scene's last image is the chalk outline of a crate on the concrete and the lights going off row by row — Mack with the phone can under his arm.",
      "Dutch's flag-preservation logic (vacuum-baked fabric, rides flat, nitrogen so the dye doesn't oxidize) may appear ONCE, plainly, as his real spec-thinking — it is true preservation science AND, later, his cover story; here it is only the former.",
    ],
  ),
]

/* ---- runner ---------------------------------------------------------- */
let runOne = async (j: job) => {
  let path = Cinema_Backends.Path(j.out)
  if existsSync(j.out) {
    switch Write.verify(path) {
    | Ok() => Js.log("SKIP " ++ j.seed.id ++ " (verified)")
    | Error(_) => Js.log("STALE " ++ j.seed.id ++ " (exists, fails verify — regenerating)")
    }
  }
  let done_ = existsSync(j.out) && Write.verify(path) == Ok()
  if !done_ {
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
    "ACT 1 DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
