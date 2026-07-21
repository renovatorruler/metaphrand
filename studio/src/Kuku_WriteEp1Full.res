/* KUKU aur AKSHAR — Episode 1 "कुकु और काला कुत्ता" (letter क) — FULL EPISODE batch
   write driver. Seven scenes, one warm session. I author STRUCTURE only (seeds per
   stories/kuku/EP1_K_PLOT_v1.md); the engine writes every sentence; emit leaves a
   receipt per scene. Continue-on-error: one failed scene does not kill the batch.

   Run from inside studio/:
     npm run build && CLAUDE_STUDIO_BUDGET=24 node src/Kuku_WriteEp1Full.res.mjs
   Zero-spend structural smoke:
     CLAUDE_STUDIO_BIN="$(pwd)/scripts/fake-claude.mjs" CLAUDE_STUDIO_BUDGET=25 \
       node src/Kuku_WriteEp1Full.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

/* ---- the cast (voice cards; from stories/kuku/VOICE_CARDS.md) ---- */

let kuku: Seed.voiceCard = {
  name: "KUKU",
  who: "the littlest dragon, the hero; breathes glowing letters instead of fire; wants a dog more than anything",
  register: "simple eager preschool-plus Hindi, short present-tense sentences, all heart on the surface; braver under pressure than he believes",
  earnsEloquence: false,
  lexicon: "a small child's world: कुत्ता, दोस्त, देखो, मेरा, फिर से",
}

let furia: Seed.voiceCard = {
  name: "FURIA",
  who: "a dragon girl, Kuku's best friend and Vesper's big sister; first at everything, kind but fiercely competitive with her brother; instantly mothers anything small; dreams of a shiny red car",
  register: "fast, bright, exclamatory; races to answer first; catchphrase मैं पहले!; announces her victories; competitive but never mean; goes suddenly gentle with babies and animals",
  earnsEloquence: false,
  lexicon: "racing and winning words: पहले, जल्दी, मैं, सबसे तेज़; her dream red कार",
}

let vesper: Seed.voiceCard = {
  name: "VESPER",
  who: "a dragon boy, Furia's little brother; very kind and sweet; lost in his own imagination, must be called four or five times before he answers; notices what everyone else misses",
  register: "slow, soft, dreamy, delayed; answers questions from three lines ago; THE ONLY character who may drift into English mid-line, and when he does someone says हिंदी में, वैस्पर! and he repeats it in Hindi",
  earnsEloquence: false,
  lexicon: "clouds, butterflies, quiet noticing; half-finished dreamy thoughts",
}

let dadi: Seed.voiceCard = {
  name: "DADI MAYA",
  who: "the grandmother dragon, warm host of the letter lesson; guides without lecturing",
  register: "short, clear, warm Hindi; gentle imperatives; leads call-and-response; repeats a child's answer back to reward it; never stern",
  earnsEloquence: false,
  lexicon: "teaching warmth: शाबाश, बोलो मेरे साथ, अक्षर, आवाज़, टोपी",
}

let papa: Seed.voiceCard = {
  name: "PAPA",
  who: "Kuku's father, a big busy dragon; kind but firm; says no from care, not meanness; capable of being wrong and saying so",
  register: "short, warm, decisive; a father's plain no that never feels cold; softens visibly when moved",
  earnsEloquence: false,
  lexicon: "work and care: काम, बेटा, घर",
}

let cheeku: Seed.voiceCard = {
  name: "CHEEKU",
  who: "the toddler dragon that Furia and Vesper look after; tiny, giggly",
  register: "one or two words only, repeated; toddler babble",
  earnsEloquence: false,
}

/* ---- shared hard rules (every scene) ---- */

let shared = [
  "AUDIENCE: kids about four to seven learning Hindi from scratch, in the energetic spirit of Super Kitties: real stakes, humor, teamwork, heart. Livelier than toddler TV, but the Hindi stays short, simple, and learnable.",
  "English sluglines and English action lines; ALL dialogue in Devanagari Hindi, standard characters only, straight quotes only if quoting.",
  "Heavy INTENTIONAL repetition of the letter क and this episode's क words is REQUIRED pedagogy, not a flaw.",
  "ONLY VESPER may drift into English mid-line; when he does, another character says हिंदी में, वैस्पर! and he repeats the line simply in Hindi. No other character ever speaks English.",
  "PROPER HINDI LAW: every dialogue line is a COMPLETE, grammatically correct Hindi sentence, short and simple but never a chopped fragment; model line: पापा, पापा, देखो वो काला कुत्ता. आप एक कुत्ता मेरे लिए घर ले आओ ना. Exceptions: toddler babble, and the single letter क in call-response.",
  "PRONOUN LAW: children say आप to elders (Papa, Dadi), never तुम or तू; elders say तू/तुम to children; kids among themselves and to the puppy say तू. Everyone is warm; Papa is firm but never cold; nobody is a villain.",
  "One line per paragraph. No em-dashes and no emoji anywhere.",
  "Never state the buried theme; no one says different, gift, special, brave, or responsibility; it lives only in what happens.",
]

let rules = extra => Belt.Array.concat(shared, extra)

/* ---- the seven scenes (structure from EP1_K_PLOT_v1.md, Sesame-forward) ---- */

let seeds: array<Seed.sceneSeed> = [
  {
    id: "ep1-s0-teaser",
    slug: "EXT. AKSHAR GHAATI - KUKU'S GARDEN - MORNING",
    logline: "Kuku plays at being a dog and begs Papa for a real one; Papa says no, a dog is too much work, and Kuku deflates.",
    cast: [kuku, papa],
    layer: {
      peshat: "a little dragon with paper ears strapped on plays dog, shows his father a crayon drawing of a black dog, and is told no",
      sod: "the weird thing about Kuku, letters instead of fire, is exactly what will prove him big enough; difference is a gift",
    },
    beats: [
      {
        who: "KUKU",
        want: "to be a dog for a minute and to own one forever",
        wall: "he is playing alone with paper ears and a stick",
        turn: "he decides to ask Papa properly, armed with his crayon drawing of a black dog",
      },
      {
        who: "KUKU",
        want: "Papa's yes",
        wall: "Papa is busy and firm: a dog is a lot of work, Kuku is still small",
        turn: "the no lands; Kuku's paper ears droop with him",
        subtext: "Papa is not being cruel; he does not yet see what Kuku can carry",
      },
    ],
    rules: rules([
      "This is a FAST teaser, about fifteen seconds of screen time: a handful of lines only.",
      "Kuku wears paper dog ears and says भौं भौं while playing.",
      "Work in naturally: कुत्ता, काला (his dream dog is black), कान (the paper ears), काम (Papa's reason).",
      "Papa's no is loving and plain, something like: नहीं कुकु, कुत्ता बहुत काम है, तुम अभी छोटे हो.",
      "End on Kuku deflating, ears drooping; do not resolve anything.",
    ]),
  },
  {
    id: "ep1-s1-akshar",
    slug: "EXT. AKSHAR GHAATI - DADI MAYA'S ROCK - CONTINUOUS",
    logline: "Dadi Maya introduces today's letter क; Furia races in first, mistakes it for her letter Ф, and learns क wears a hat; the letter hunt is primed.",
    cast: [dadi, furia, kuku, vesper],
    layer: {
      peshat: "a grandmother shows children a big golden letter; a girl claims it is hers, learns the difference, and a letter hunt begins",
      sod: "a letter you can tell apart is a letter you own; small differences are how you know who you are",
    },
    beats: [
      {
        who: "DADI MAYA",
        want: "to introduce today's letter क with its sound so the day becomes a treasure hunt",
        wall: "the children's attention runs everywhere",
        turn: "she unveils the big golden क and calls out आज का अक्षर है क",
      },
      {
        who: "FURIA",
        want: "to be FIRST to answer, before her brother, before everyone",
        wall: "she is sure she knows this letter already, it looks exactly like her own letter",
        turn: "her triumphant claim, ये तो मेरा letter है, meets Dadi's smile: look closer, क wears a hat",
        subtext: "being first matters less than looking twice, but she will never admit that",
      },
      {
        who: "DADI MAYA",
        want: "to plant the hat rule so it sticks forever",
        wall: "an abstract rule bores children",
        turn: "she makes it physical: every Hindi letter wears a टोपी; her ball-on-a-stick letter does not; the kids trace the hat in the air",
      },
      {
        who: "VESPER",
        want: "to stay inside his daydream about the clouds",
        wall: "Dadi asks him what today's letter is and everyone waits; his name is called three times",
        turn: "he surfaces a beat late with the right answer, क, and everyone laughs warmly",
      },
      {
        who: "DADI MAYA",
        want: "to send them off hunting",
        wall: "none",
        turn: "the charge: कान खोलो, आज क ढूँढो; Furia vows to find the most क words first",
      },
    ],
    rules: rules([
      "Dadi speaks to camera as well as to the children, Sesame Street style.",
      "The big written क with its hat is physically present, golden, on Dadi's rock.",
      "Furia's mistaken letter is the Russian letter Ф; on the page write it as the character Ф; she calls it मेरा letter; do NOT explain Russian or say the word Russian.",
      "The hat is called टोपी; the rule lands as: हिंदी का हर अक्षर टोपी पहनता है.",
      "Call-and-response is REQUIRED: बोलो मेरे साथ, क; the children answer.",
      "Vesper must be called by name at least three times before he answers.",
      "Work in naturally: कान (open your ears), the sound क repeated alone.",
      "End on the hunt being launched, energy up.",
    ]),
  },
  {
    id: "ep1-s2-pilla",
    slug: "EXT. AKSHAR GHAATI - THE OLD WELL - DAY",
    logline: "Dreamy Vesper is the only one who hears a whimper; the trio finds a muddy black puppy stuck by the old well; Kuku frees it, names it Kalu, and a banana is refused.",
    cast: [kuku, furia, vesper],
    layer: {
      peshat: "three children follow a faint sound and pull a scared muddy puppy free; the smallest child calms it and gives it a name",
      sod: "the one who seems absent is the one who hears; every gift looks like a flaw first",
    },
    beats: [
      {
        who: "VESPER",
        want: "to watch the clouds in peace while the others hunt letters",
        wall: "a tiny sound keeps tugging at the edge of his dream and no one else hears it",
        turn: "called three times, he does not answer the question asked; he points: वहाँ, कोई रो रहा है",
      },
      {
        who: "FURIA",
        want: "to get there FIRST",
        wall: "the mud by the well is slippery and the thing in it is small and terrified",
        turn: "she arrives first, skids, and all the race drains out of her; she goes soft and gentle at the sight of the puppy",
        subtext: "winning stops mattering the instant something small needs her",
      },
      {
        who: "KUKU",
        want: "to free the stuck, shivering black puppy without scaring it more",
        wall: "it is wedged in the mud, ears down, trembling at every move",
        turn: "slow and soft, he talks it calm and works it free; it licks his face; he names it कालू",
      },
      {
        who: "KUKU",
        want: "to feed his new friend the best thing he has, a banana",
        wall: "the puppy sniffs it and turns away in disgust",
        turn: "the lesson lands as a laugh: कुत्ता केला नहीं खाता",
      },
    ],
    rules: rules([
      "Vesper hears the whimper BECAUSE he is dreaming while others chatter; his name must be called at least three times.",
      "Vesper drifts into English once here, something like: a puppy, he is so small; and is reminded हिंदी में, वैस्पर! and repeats it in Hindi.",
      "Furia reaches the well first and announces it, मैं पहले, then instantly turns gentle and motherly with the puppy.",
      "The puppy is small, black, muddy, floppy-eared, terrified, then trusting; it never speaks; its actions carry it.",
      "Work in naturally: कुआँ (the old well), कीचड़ (the mud), काला, कुत्ता, कान (its droopy ears), केला (the refused banana), कालू (the name).",
      "The banana refusal is the joke of the scene and lands as the exact line: कुत्ता केला नहीं खाता.",
      "End on the bond sealed: Kalu curled against Kuku.",
    ]),
  },
  {
    id: "ep1-s3-chhupam",
    slug: "EXT./INT. AKSHAR GHAATI - KUKU'S HOME AND YARD - LATER",
    logline: "The trio hides Kalu from Papa; a whirlwind of jumping, mud, and crashing bowls nearly blows their cover, and Kuku wonders if Papa was right.",
    cast: [kuku, furia, vesper, cheeku, papa],
    layer: {
      peshat: "three children try to hide a bouncing puppy from a father; chaos escalates until near-discovery, and the smallest child doubts himself",
      sod: "caring is work; wanting is easy; the difference is the whole test",
    },
    beats: [
      {
        who: "KUKU",
        want: "to keep Kalu secret until he can prove himself",
        wall: "Kalu is a spring-loaded chaos machine: jumping on everything, rolling in mud, skidding through the yard",
        turn: "every fix creates a new mess; the plan is barely holding",
      },
      {
        who: "FURIA",
        want: "to run the hiding operation better than anyone could, first and fastest",
        wall: "Kalu bounds straight at toddler Cheeku",
        turn: "she scoops the baby clear without thinking, bowls crashing behind her, and keeps the toddler giggling instead of crying",
      },
      {
        who: "VESPER",
        want: "to do his job as lookout by the gate",
        wall: "a butterfly",
        turn: "he drifts after it mid-watch; Papa's footsteps come and there is no warning; near-catastrophe as the trio shoves Kalu behind the blanket just in time",
      },
      {
        who: "KUKU",
        want: "to believe he can do this",
        wall: "the wrecked yard, the crashed bowls, the close call, all say Papa was right, a dog is too much काम",
        turn: "holding the sleeping puppy, he wavers but does not give up; quietly: कालू मेरा है",
        subtext: "the doubt is real; the answer is not words, it will be what he does at the well",
      },
    ],
    rules: rules([
      "This is a fast comic montage scene with a real wobble of doubt at the end; keep the energy high, the beats visual.",
      "Kalu never speaks; his chaos is physical: jumping, mud, skids, crashes.",
      "Work in naturally: कूदना (Kalu jumps and jumps), कीचड़, कटोरा (Dadi's bowls crash), कंबल (the blanket bed and hiding spot), काम (Papa's word echoing in Kuku's doubt).",
      "Cheeku the toddler says only one or two repeated words, giggling.",
      "Papa passes through close enough to almost catch them; he is NOT fooled into looking silly; he simply almost notices and moves on.",
      "Vesper's butterfly drift is affectionate comedy, never blamed harshly.",
      "End quiet after the chaos: Kuku holding sleeping Kalu, doubting, deciding to keep going.",
    ]),
  },
  {
    id: "ep1-s4-bachaav",
    slug: "EXT. AKSHAR GHAATI - THE OLD WELL - GOLDEN HOUR",
    logline: "Kalu chases a pigeon and slips over the rim of the old well; Furia's charge fails, Vesper sees the answer, and Kuku's letter breath, hat and all, becomes the hook that saves him.",
    cast: [kuku, furia, vesper, papa],
    layer: {
      peshat: "a puppy dangles at the rim of a well; three children each try their gift in turn until the smallest one's strange breath lifts it to safety",
      sod: "the thing that made him different is the only thing that could save what he loves",
    },
    beats: [
      {
        who: "KUKU",
        want: "one calm evening walk with his secret dog",
        wall: "a pigeon; Kalu bolts after it, straight for the old well, and slips over the rim, scrabbling",
        turn: "play becomes terror in one breath; the trio runs",
      },
      {
        who: "FURIA",
        want: "to save Kalu herself, first, now",
        wall: "she charges to the rim but her arms are too short and the stone is slick",
        turn: "Vesper catches her tail; her first ever failed first; she calls for Kuku",
        subtext: "for once she wants someone ELSE to be first, and it costs her nothing to say it",
      },
      {
        who: "VESPER",
        want: "to see the shape of the answer the way he sees pictures in clouds",
        wall: "everyone is shouting and the puppy is slipping",
        turn: "dead calm inside the panic, he sees it: something must reach DOWN from ABOVE, like a hook; ऊपर से, हुक जैसा",
      },
      {
        who: "KUKU",
        want: "to make the only fire he has, his letter, do the impossible",
        wall: "raw fear, the memory of every failed flame; the first breath makes only the hatless ball, not a letter yet",
        turn: "the chant साँस, टोपी, अक्षर; the टोपी snaps onto the shape; the glowing क, the hooked letter they learned this morning, reaches down and lifts Kalu up into his arms",
      },
      {
        who: "PAPA",
        want: "to reach the well in time, having heard the shouting",
        wall: "he arrives at the exact moment the glowing letter rises",
        turn: "he stops dead and watches his small son do the impossible; he says nothing yet",
      },
    ],
    rules: rules([
      "This is the climax; real danger, real fear, but never gruesome: Kalu scrabbles at the rim, is lifted, is safe.",
      "The rescue sequence order is FIXED: Furia charges and fails, Vesper names the hook shape, then Kuku's power-up.",
      "The power-up chant is exactly: साँस, टोपी, अक्षर.",
      "The first breath makes a hatless ball shape that is NOT yet a letter; someone cries अभी नहीं; then the टोपी snaps on and it becomes क; the hook of the क is what lifts Kalu.",
      "Work in naturally: कबूतर (the pigeon), कुआँ, कूदना, क itself repeated.",
      "Papa arrives in time to SEE the rescue but says almost nothing; his reaction is held for the next scene.",
      "End on Kalu safe in Kuku's arms, and Papa standing there, seen.",
    ]),
  },
  {
    id: "ep1-s5-kalu-ghar",
    slug: "EXT. AKSHAR GHAATI - KUKU'S HOME - EVENING",
    logline: "Papa, who saw everything, gives his answer: Kalu is Kuku's; the bowl is filled, the blanket is laid, and one last banana is refused.",
    cast: [kuku, papa, furia, vesper],
    layer: {
      peshat: "a father who watched his son save a puppy says yes; the dog is fed and bedded; a banana is refused one last time to a big laugh",
      sod: "he did not become someone else to earn it; the thing he already was turned out to be enough",
    },
    beats: [
      {
        who: "KUKU",
        want: "to confess everything before Papa can be angry: the hiding, the mess, all of it",
        wall: "the words tumble out in a heap and Kalu is right there, wagging, undeniable",
        turn: "Papa kneels and stops him gently mid-confession",
      },
      {
        who: "PAPA",
        want: "to say what he saw at the well in the fewest words a father needs",
        wall: "his own no from this morning is still standing in the room",
        turn: "he takes it down himself: he saw the care, the courage, and that letter; कालू तुम्हारा है, कुकु",
        subtext: "he was wrong about small; he will not say the word wrong; giving the dog IS saying it",
      },
      {
        who: "FURIA",
        want: "to make Kalu's homecoming perfect, first and fastest",
        wall: "there is only so much a bowl and a blanket can be arranged",
        turn: "she fills the कटोरा and lays the कंबल and announces she did it first; nobody argues; everyone smiles",
      },
      {
        who: "VESPER",
        want: "to give Kalu a welcome present",
        wall: "the present he chose is a banana",
        turn: "the whole family, in chorus: कुत्ता केला नहीं खाता; the biggest laugh of the episode",
      },
    ],
    rules: rules([
      "Warm, small, and quick; the emotion carries it, not speeches; Papa's yes is a few plain words.",
      "Papa never says the words sorry or wrong or proud; the dog, the kneeling, and his hand on Kuku's head say it.",
      "Work in naturally: कटोरा (filled for Kalu), कंबल (his bed), केला (the refused gift), कालू, कुत्ता.",
      "The banana chorus line is exactly: कुत्ता केला नहीं खाता.",
      "End on the family settled around the puppy, night coming on.",
    ]),
  },
  {
    id: "ep1-s6-topi",
    slug: "EXT. AKSHAR GHAATI - DADI MAYA'S ROCK - NIGHT",
    logline: "Dadi leads the recap of every क the day held; Furia writes the letter in her book first, and the camera finds Vesper already asleep, curled around Kalu.",
    cast: [dadi, kuku, furia],
    layer: {
      peshat: "a grandmother and two children count up the day's letter words under the stars; one child writes the letter in her book; the other is found asleep with the puppy",
      sod: "a letter learned inside a day you lived is yours forever",
    },
    beats: [
      {
        who: "DADI MAYA",
        want: "to gather the whole day into the one letter",
        wall: "the children are tired and glowing and full of story",
        turn: "call-and-response harvest: क से? and the children fire back the day's words, कुत्ता, कालू, काला, कान, कीचड़, कुआँ, कटोरा, कंबल, केला",
      },
      {
        who: "DADI MAYA",
        want: "to seal the hat rule one last time",
        wall: "none",
        turn: "हिंदी का हर अक्षर टोपी पहनता है; the children trace the hat in the air",
      },
      {
        who: "FURIA",
        want: "to be the first to write today's letter in her letter book",
        wall: "her brother might... no, her brother is nowhere in sight",
        turn: "she writes the क, hat first, and holds up the book in triumph: मैंने पहले लिखा!",
      },
      {
        who: "DADI MAYA",
        want: "to say goodnight to all three children",
        wall: "only two are in front of her",
        turn: "the camera and the family find Vesper already fast asleep on the कंबल, curled around Kalu; softly: शुभ रात्रि, वैस्पर",
      },
    ],
    rules: rules([
      "This is the recap and goodnight; cozy, starlit, winding down.",
      "Call-and-response is REQUIRED and central: क से? answered with the day's actual words.",
      "The hat rule lands one final time as: हिंदी का हर अक्षर टोपी पहनता है.",
      "Furia writes क in her किताब, hat stroke first, and announces she was first; it is charming, not obnoxious.",
      "The final image is FIXED: Vesper asleep on the कंबल curled around Kalu; Dadi's last line is शुभ रात्रि, वैस्पर.",
      "Work in naturally: किताब, कंबल, and the day's क words in the response.",
    ]),
  },
]

/* ---- the batch runner: continue on error, report at the end ---- */

let writeOne = async (seed: Seed.sceneSeed) => {
  let out = Cinema_Backends.Path(dir ++ "/" ++ seed.id ++ ".scene.txt")
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("== WROTE " ++ seed.id ++ " (calls so far: " ++ Belt.Int.toString(Session.callsMade()) ++ ")")
    true
  } catch {
  | Write.WriteError(m) => {
      Js.log("== FAILED " ++ seed.id ++ " (gate): " ++ m)
      false
    }
  | Session.SessionError(m) => {
      Js.log("== FAILED " ++ seed.id ++ " (session): " ++ m)
      false
    }
  }
}

let rec run = async (i, okCount) =>
  switch Belt.Array.get(seeds, i) {
  | None => okCount
  | Some(seed) => {
      let ok = await writeOne(seed)
      await run(i + 1, ok ? okCount + 1 : okCount)
    }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log(
    "\n=== BATCH DONE: " ++
    Belt.Int.toString(ok) ++
    "/" ++
    Belt.Int.toString(Belt.Array.length(seeds)) ++
    " scenes written, " ++
    Belt.Int.toString(Session.callsMade()) ++ " model calls ===",
  )
  Session.close()
}

main()->ignore
