/* KUKU aur AKSHAR — Episode 2 "जिस दिन म ग़ायब हुआ" (letter म) — ADVENTURE MODE batch
   write driver. Structure from stories/kuku/EP2_M_PLOT_v3.md + SERIES_ADVENTURE_MODE.md.
   Enriched cast (tics sparingly), तुम register, letter-hero adventure with मिटासुर.
   I author STRUCTURE only; the engine writes the sentences; emit leaves a receipt.

   Run from studio/:
     npm run build && CLAUDE_STUDIO_BUDGET=24 node src/Kuku_WriteEp2.res.mjs
   Smoke: CLAUDE_STUDIO_BIN="$(pwd)/scripts/fake-claude.mjs" CLAUDE_STUDIO_BUDGET=25 node src/Kuku_WriteEp2.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep2"

/* ---- cast (enriched voice cards; VOICE_CARDS.md) ---- */

let kuku: Seed.voiceCard = {
  name: "KUKU",
  who: "the littlest dragon and the team's power: the only one who can FORGE letters (breathe them into being). Warm, brave under pressure, remembers when he too couldn't make his own fire",
  register: "simple eager Hindi, complete sentences, all heart on the surface; steadies himself when it matters",
  earnsEloquence: false,
  lexicon: "making, trying, friends: बनाना, साँस, दोस्त, मदद",
}

let furia: Seed.voiceCard = {
  name: "FURIA",
  who: "a big-hearted dragon-girl leader whose racing is generosity in a hurry: first to help, first to protect; the group's emotional radar; brave outside, brave enough to admit fear inside",
  register: "fast, bright, warm, COMPLETE sentences; notices when someone is sad; her signature मैं पहले! is used rarely, only when earned, not every scene",
  earnsEloquence: false,
  lexicon: "helping and feeling words; fast things; she is proudest when she helped someone ELSE",
}

let vesper: Seed.voiceCard = {
  name: "VESPER",
  who: "Furia's younger brother: a tender seer and little inventor who sees clearest by wandering; notices beauty and hidden things others miss; offers the sideways idea; snaps into focus when it truly matters",
  register: "soft, unhurried, but COMPLETE and quietly insightful, never vacant; his English-drift-then-हिंदी-में-वैस्पर is used at most once, as charm not a gag",
  earnsEloquence: false,
  lexicon: "noticing, imagining, building: देखो, ऊपर से, अगर, जैसे",
}

let dadi: Seed.voiceCard = {
  name: "DADI MAYA",
  who: "the grandmother dragon, the team's mentor-handler and letter-lesson host; also, quietly, Papa's own mother",
  register: "short, clear, warm Hindi; gentle imperatives; leads call-and-response; states the day's rule plainly",
  earnsEloquence: false,
  lexicon: "teaching + rallying: बोलो मेरे साथ, अक्षर, टोपी, म, बनाना, मिटाना",
}

let papa: Seed.voiceCard = {
  name: "PAPA",
  who: "Kuku's father, a big warm dragon; arrives near the end; Dadi Maya is his mother",
  register: "short, warm, plain; тuम to the children",
  earnsEloquence: false,
  lexicon: "family warmth: बेटा, माँ, घर",
}

let mitasur: Seed.voiceCard = {
  name: "MITASUR",
  who: "a roly-poly purple goblin with sponge-hands who can only ERASE letters, never make one; steals them because his hoard is the only thing he has ever owned; lonely under the mischief; not scary; melts when he makes his very first letter",
  register: "whiny, grabby, comic; a real wound under the bluster (I can never make anything, only erase); turns tender and amazed at the end; complete simple sentences",
  earnsEloquence: false,
  lexicon: "taking and lack: मेरा, मिटा, कुछ नहीं, अकेला",
}

let morni: Seed.voiceCard = {
  name: "MORNI",
  who: "a peahen, the lost chick's frantic then grateful mother",
  register: "urgent, tender; very few lines; calls for help and then for her child",
  earnsEloquence: false,
}

/* ---- shared rules ---- */

let shared = [
  "AUDIENCE: kids about four to seven learning Hindi, in the ADVENTURE spirit of Miniforce, Go-Go Dino, Super Kitties: a team of heroes, a mission, real (kid-scale) stakes, a comic villain, a power-up. Livelier than toddler TV, but the Hindi stays short, simple, and learnable.",
  "This is a LETTER-HERO episode. The team (Kuku, Furia, Vesper, the dog Kalu) are the अक्षर वीर. Their call-up is अक्षर वीर, तैयार! and their power-up chant is साँस, टोपी, अक्षर!",
  "English sluglines and English action lines; ALL dialogue in Devanagari Hindi, standard characters only.",
  "INTENTIONAL repetition of the letter म and this episode's म words (माँ, मेला, मिठाई, मोर, मछली, मदद, माया) is REQUIRED pedagogy.",
  "PROPER HINDI LAW: every dialogue line is a COMPLETE, grammatically correct Hindi sentence, short and simple, never a chopped fragment.",
  "PRONOUN LAW: children say आप to elders (Dadi, Papa); among the kids and to the dog Kalu they say तुम / तुम्हारा (NEVER तू/तेरा); elders say तुम to the children.",
  "CHARACTER RICHNESS LAW: tics are seasoning, not the meal. Furia's मैं पहले! and Vesper's English-drift/name-calls/sleepiness may each appear AT MOST ONCE in the whole episode, only at a beat that earns it. Every other line carries the scene through the character's real want and feeling (Furia = big-hearted helper-leader; Vesper = tender seer-inventor).",
  "ONLY VESPER may drift into English, at most once; then someone says हिंदी में, वैस्पर! and he repeats it in Hindi.",
  "The villain मिटासुर is COMIC and SYMPATHETIC, never frightening: no menace that would scare a small child.",
  "One line per paragraph. No em-dashes and no emoji anywhere.",
  "The buried theme (everyone is someone's child; and the one who only took was never shown he could make) is NEVER stated. EXCEPTION: the gameplay rule IS said aloud once, as the mechanic: जो बनाया जाता है, उसे कोई मिटा नहीं सकता (what is made cannot be un-made).",
]
let rules = extra => Belt.Array.concat(shared, extra)

let seeds: array<Seed.sceneSeed> = [
  {
    id: "ep2-s0-mela",
    slug: "EXT. AKSHAR GHAATI - THE FAIRGROUND - MORNING",
    logline: "A postcard from Masha announces her city fair; the valley's own मेला is today, bright with मिठाई, a मछली pond, and a मोर family, and the team tumbles in happy.",
    cast: [furia, kuku, vesper, dadi],
    layer: {
      peshat: "children get a postcard and run to a village fair full of sweets, a fish pond, and parading peacocks",
      sod: "a day so full of म that its loss will be felt in every corner",
    },
    beats: [
      {who: "FURIA", want: "to share the exciting postcard from her friend Masha", wall: "everyone is busy", turn: "the news lands: Masha went to a big मेला, and OUR मेला is today"},
      {who: "KUKU", want: "to drink in the whole fair at once", wall: "there is too much to see", turn: "they tour Dadi's मिठाई stall, the मछली pond bright with darting fish, and a मोर family whose chicks trail their माँ"},
      {who: "VESPER", want: "to notice one quiet beautiful thing in the noise", wall: "the fair is loud", turn: "he watches the little मोर chick stay close to its माँ, and smiles"},
    ],
    rules: rules([
      "Ordinary-life opening; warm and full; about one minute.",
      "PLANT for later breakage: show the मछली pond with fish visibly darting and bright; show the मोर family and one small chick beside its माँ; show Dadi's मिठाई being sweet.",
      "Masha appears ONLY as a postcard the children read aloud; she is not present.",
      "Work in naturally and happily: मेला, मिठाई, मछली, मोर, माँ.",
      "End on the fair at its happiest, the chick tucked beside its mother.",
    ]),
  },
  {
    id: "ep2-s1-chori",
    slug: "EXT. AKSHAR GHAATI - ABOVE THE FAIR - CONTINUOUS",
    logline: "Lonely मिटासुर, who owns nothing of his own, erases the letter म from the whole valley; the sweets go flavourless, the fish freeze colourless, the peacock cannot fan, and a chick loses the word for its mother.",
    cast: [mitasur, morni],
    layer: {
      peshat: "a goblin rubs a letter out of the world and everything that letter began stops working",
      sod: "he takes because taking is the only making he has ever known",
    },
    beats: [
      {who: "MITASUR", want: "to not feel so alone watching a fair he has no place in", wall: "he has no मेला, no friends, nothing of his own", turn: "he does the only thing he can do, the thing he is good at: he erases the letter म", subtext: "his stealing is a wound, not a cruelty"},
      {who: "MITASUR", want: "to keep the glowing letters he has taken", wall: "they are not really his", turn: "he sweeps the stolen म into his sack, the only things he has ever owned, and slips away"},
      {who: "MORNI", want: "to find her little one in the sudden wrongness", wall: "the word for what she is to the chick has vanished", turn: "she cannot even call the name माँ, and cries out in fear"},
    ],
    rules: rules([
      "The theft is the hook. Show, in the ACTION, each breakage clearly and visibly: the मिठाई turns dull and flavourless, the मछली in the pond freeze still and lose their colour, the मोर cannot fan its feathers, and the tiny chick opens its mouth to call माँ but no word comes.",
      "मिटासुर is comic and a little sad, never scary; he cackles but it is lonely.",
      "Establish plainly (in his lines) that the stolen letters are the only things he has ever had.",
      "Morni's fear is brief and real; keep it gentle, not distressing.",
      "Work in: म, माँ, मिठाई, मछली, मोर.",
      "End on मिटासुर waddling off with his sack, the fair frozen wrong behind him.",
    ]),
  },
  {
    id: "ep2-s2-akshar",
    slug: "EXT. AKSHAR GHAATI - DADI MAYA'S ROCK - CONTINUOUS",
    logline: "The peahen's cry for help rallies the team; to fight back they must learn म, and Dadi reveals it — hat and all, English M corrected by Vesper — and the अक्षर वीर vow to help.",
    cast: [morni, dadi, vesper, furia, kuku],
    layer: {
      peshat: "a grandmother teaches a letter so the children can use it to set things right",
      sod: "you learn the thing to become able to give",
    },
    beats: [
      {who: "MORNI", want: "anyone to help her find her child", wall: "she cannot name what she has lost", turn: "her cry मदद reaches the children and turns them into rescuers"},
      {who: "DADI MAYA", want: "to arm the team with the letter itself", wall: "they do not know म yet", turn: "she reveals the golden म with its टोपी and says the only way to bring it back is to learn it"},
      {who: "VESPER", want: "to name the shining letter", wall: "he reaches for the wrong language", turn: "he says it is M, is reminded हिंदी में वैस्पर, and finds it: म; Dadi notes English M wears no टोपी but म does; माया too has म"},
      {who: "FURIA", want: "to turn the lesson into a promise to the frightened mother", wall: "learning can feel like standing still while someone suffers", turn: "she rallies the team: हम मदद करेंगे"},
    ],
    rules: rules([
      "मदद is spoken IN THE ACTION here, load-bearing: Morni cries मदद, and the team answers हम मदद करेंगे.",
      "Sesame-forward reveal: the big golden म with its टोपी on Dadi's rock; sound म; call-and-response बोलो मेरे साथ, म.",
      "The hat rule generalises past Furia's Ф: English M टोपी नहीं पहनता, म पहनता है. Hero-hook: माया में म है.",
      "This is Vesper's ONE English-drift for the episode; do not repeat the device later.",
      "Work in: म, माँ, माया, मदद, टोपी.",
      "End on the team charged up: अक्षर वीर, तैयार, and the vow हम मदद करेंगे.",
    ]),
  },
  {
    id: "ep2-s3-peecha",
    slug: "EXT. AKSHAR GHAATI - THROUGH THE FROZEN FAIR - DAY",
    logline: "The team tracks मिटासुर through the un-spelled fair and corners him; clutching his sack, he blurts his wound: he can never make anything, only erase.",
    cast: [kuku, furia, vesper, mitasur],
    layer: {
      peshat: "children chase a thief across a broken fair and catch him, and he tells them why he steals",
      sod: "the wound named out loud is the door the ending will walk through",
    },
    beats: [
      {who: "KUKU", want: "to find where मिटासुर hid the stolen म", wall: "the thief has a head start across a fair gone wrong", turn: "the team splits their gifts: Kalu tracks the chalky scent, Furia runs the search, Vesper sees where others do not"},
      {who: "VESPER", want: "to spot the one wrong thing", wall: "everyone is shouting and rushing", turn: "calm inside the noise, he sees मिटासुर's hiding place and quietly points it out"},
      {who: "MITASUR", want: "to keep his sack of stolen letters", wall: "the children have cornered him", turn: "he hugs the sack and blurts his wound: he can never make anything, he can only erase, these letters are all he has", subtext: "this is the hinge the whole ending turns on"},
    ],
    rules: rules([
      "A team set-piece: each hero's gift is load-bearing. Kalu tracks (barks, no speech). Furia's speed. Vesper's sight is the one that finds मिटासुर.",
      "Show the fair still broken around them (dull मिठाई, still मछली) as they run.",
      "मिटासुर's wound must be said PLAINLY in his own words: he can only मिटा (erase), never बना (make); the stolen letters are all he has ever owned.",
      "Keep him comic and pitiable, never threatening.",
      "Furia may help WITHOUT her catchphrase here; let her lead by heart, not by मैं पहले.",
      "Work in: म, मिटा, बनाना, मेला.",
      "End cornered, the wound hanging in the air, the crisis not yet solved.",
    ]),
  },
  {
    id: "ep2-s4-shakti",
    slug: "EXT. AKSHAR GHAATI - THE STREAM - GOLDEN HOUR",
    logline: "The chick teeters at the water; Kuku forges one new म, and because a made letter cannot be un-made, its very creation shatters मिटासुर's hoard and restores the valley, while its loop becomes the boat that carries the chick to its माँ.",
    cast: [kuku, furia, vesper, dadi],
    layer: {
      peshat: "a boy makes a letter; the making itself fixes everything and carries a lost child home",
      sod: "creation overpowers erasure; the same made thing that defeats the taker saves the small",
    },
    beats: [
      {who: "KUKU", want: "to save the chick stranded across the stream from its searching mother", wall: "there is no time to pry the stolen letters back, and he is afraid", turn: "the team calls अक्षर वीर तैयार and he forges: साँस, टोपी, अक्षर, and a brand-new म blazes into being"},
      {who: "DADI MAYA", want: "to name why this works so the children (and the villain) understand", wall: "the moment is fast and frightening", turn: "she says the law aloud: मिटासुर सिर्फ मिटा सकता है, पर जो बनाया जाता है उसे कोई मिटा नहीं सकता"},
      {who: "KUKU", want: "the one made म to do two things at once", wall: "one letter, two needs", turn: "the very existence of the made म shatters the hoard and heals the valley, and the same म's loop unfolds into a cradle-boat that carries the chick across to its माँ"},
    ],
    rules: rules([
      "THE CLIMAX and the FUSED MECHANIC. It must be ONE move: Kuku forges a single म; that creation, being un-erasable, both breaks मिटासुर's hold AND becomes the boat that saves the chick.",
      "Dadi says the mechanic aloud, clearly: जो बनाया जाता है, उसे कोई मिटा नहीं सकता.",
      "Show the healing in the ACTION at the instant the म is made: the मछली swim again in full colour, the मोर fans its feathers, the मिठाई turns sweet, and माँ and बच्चा can name each other again.",
      "The power-up chant is exactly: साँस, टोपी, अक्षर. Keep the hatless-ball-then-टोपी-snaps beat.",
      "Real but gentle stakes; the reunion nuzzle of chick and माँ is the emotional peak.",
      "Work in: म, माँ, मछली, मोर, मिठाई, बनाना, मिटाना.",
      "End on the chick safe with its माँ, मिटासुर's sack empty, everyone soaked and cheering.",
    ]),
  },
  {
    id: "ep2-s5-pehla-akshar",
    slug: "EXT. AKSHAR GHAATI - THE FAIRGROUND - EVENING",
    logline: "Instead of gloating, Kuku teaches मिटासुर to make his own म; the goblin forges a lopsided little letter and lights up; and Kuku learns that Dadi Maya is Papa's own mother.",
    cast: [kuku, mitasur, dadi, papa, furia],
    layer: {
      peshat: "the boy teaches the thief to make instead of take, and the thief makes his first thing; a grandmother turns out to be a father's mother",
      sod: "everyone is someone's child, even the one who thought he had no one",
    },
    beats: [
      {who: "MITASUR", want: "to understand how the children made what he could only steal", wall: "he has only ever erased; he believes he cannot make", turn: "Kuku, who once could not make his own fire, teaches him the chant instead of gloating"},
      {who: "MITASUR", want: "to try, though he is sure he will fail", wall: "a lifetime of only erasing", turn: "he breathes and out wobbles a lopsided little म with a crooked टोपी, his first made thing ever, and he lights up and cups it in both hands"},
      {who: "KUKU", want: "to understand the peacock family and मिटासुर's tiny new letter", wall: "a child's simple question", turn: "he asks Dadi if she too has a माँ, and learns that Dadi Maya is Papa's mother; Papa arrives and kisses her head"},
    ],
    rules: rules([
      "The earned turn: मिटासुर MAKES his first म on the page (lopsided, crooked टोपी), and lights up. Do not resolve his arc with only a promise; show the making.",
      "Kuku teaches without gloating; the chant साँस, टोपी, अक्षर is the gift.",
      "The heart reveal: दादी माया, पापा की माँ हैं. Papa arrives and says हाँ, ये मेरी माँ हैं and kisses Dadi's head.",
      "मिटासुर is welcomed in and handed a मिठाई; he is now a friend, not a foe.",
      "Work in: म, माँ, माया, मिठाई, बनाना.",
      "End warm: the whole group together, मिटासुर holding his crooked little म.",
    ]),
  },
  {
    id: "ep2-s6-topi",
    slug: "EXT. AKSHAR GHAATI - DADI MAYA'S ROCK - NIGHT",
    logline: "Under the stars the team counts the म-words they saved; Fyuria writes म in her book; and the camera finds Vesper asleep in the empty मिठाई basket and मिटासुर snoring with a sweet in one hand and his crooked म in the other.",
    cast: [dadi, kuku, furia],
    layer: {
      peshat: "a grandmother and children count the day's letter words under the stars and everyone falls asleep",
      sod: "a letter saved inside a day you fought for is yours forever",
    },
    beats: [
      {who: "DADI MAYA", want: "to gather the whole rescue into the one letter म", wall: "the children are tired and glowing", turn: "call-and-response harvest of the म words they lived: माँ, मेला, मिठाई, मोर, मछली, मदद, माया"},
      {who: "DADI MAYA", want: "to seal the hat rule one more time", wall: "none", turn: "हिंदी का हर अक्षर टोपी पहनता है, English M नहीं; the children trace the टोपी in the air"},
      {who: "FURIA", want: "to write today's letter in her book", wall: "none", turn: "she writes म, हैट and all, and shows it proudly; this is where her one मैं पहले may land, if it lands anywhere"},
      {who: "DADI MAYA", want: "to say goodnight to everyone", wall: "some are already asleep", turn: "the camera finds Vesper asleep in the empty मिठाई basket and मिटासुर snoring with a मिठाई in one hand and his crooked little म in the other; soft शुभ रात्रि"},
    ],
    rules: rules([
      "Recap and goodnight; cozy, starlit.",
      "Call-and-response is central: म से, answered with the day's actual words (माँ, मेला, मिठाई, मोर, मछली, मदद, माया) — only words that were LIVED this episode.",
      "The hat rule lands once more: हिंदी का हर अक्षर टोपी पहनता है.",
      "The final image is FIXED: Vesper asleep in the empty मिठाई basket, and मिटासुर asleep holding a मिठाई and his own crooked little म. Dadi's last line is a soft शुभ रात्रि.",
      "Work in: म and the day's म words in the response; किताब.",
    ]),
  },
]

let writeOne = async (seed: Seed.sceneSeed) => {
  let out = Cinema_Backends.Path(dir ++ "/" ++ seed.id ++ ".scene.txt")
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("== WROTE " ++ seed.id ++ " (calls: " ++ Belt.Int.toString(Session.callsMade()) ++ ")")
    true
  } catch {
  | Write.WriteError(m) => { Js.log("== FAILED " ++ seed.id ++ " (gate): " ++ m); false }
  | Session.SessionError(m) => { Js.log("== FAILED " ++ seed.id ++ " (session): " ++ m); false }
  }
}

let rec run = async (i, ok) =>
  switch Belt.Array.get(seeds, i) {
  | None => ok
  | Some(seed) => { let r = await writeOne(seed); await run(i + 1, r ? ok + 1 : ok) }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log("\n=== EP2 WRITE: " ++ Belt.Int.toString(ok) ++ "/" ++ Belt.Int.toString(Belt.Array.length(seeds)) ++ " scenes, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
