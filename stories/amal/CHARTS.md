# अमल — Natal Charts (the voice generator)

*Per-work pass #7 (docs/05) · system: **Jyotish / Vedic** (Indian story) · method: `docs/04`. The chart is
not decoration — it GENERATES the voice, which is then read onto the six axes in `VOICE_CARDS.md`. None of
this is ever spoken on screen; it is a hidden scaffolding, like the Jungian frame elsewhere. Enforced by
`metaphrand/preflight.py`.*

## The cosmology (the design rhymes — never stated)

- **The Rahu–Ketu axis = Bherulal ↔ Ratan.** The two severed halves of one demon, always opposite: the
  insatiable **head** (Bherulal, the opium-hunger that eats his own daughters) and the **headless body**
  (Ratan, the Jhujhar, severance, moksha). Antagonist and protagonist welded at the spine.
- **The Sun–Saturn enmity = Deva ↔ Ratan.** Estranged father and son of the zodiac, light against weight —
  the young idealist and the fallen elder. Friction *and* love, built in.
- **Two Moons = Amma ↔ Sugna.** The same mother-karaka, one whole and warm, one afflicted and calcified —
  the bright fussing mother and the stone. Same role, opposite Moon.
- **Three Venus women = Kanta · Manju · Leela.** One devoted wife, one yielding bride, one fire-bride sold —
  three fates of Venus, the daughters-as-currency of the trade.
- **Two Rahu risers = Bherulal ↔ Rana.** Still-grasping hunger vs. arrived charisma — two faces of power
  come up out of the dirt.
- **Earned eloquence = Charan ALONE.** Only the Jupiter bard gets the mythic rolling language. Everyone else
  is stripped of it (the voice-differentiation law; who-earns-the-aphorism).
- **Four ways of not-saying-it:** Ratan (clipped-cold), Sugna (stone-silent), Mishra (smooth-reasonable),
  Manju (soft-yielding). The withholding axis, four distinct grains.

---

## The leads

### Ratan — `ratan`  · core: **Ketu** (the headless), crushed under **Shani**
- **Lagna** Vrishchik (Scorpio) — the detective's withheld, penetrating gaze; still water, secrets.
- **Ketu** on the Lagna — *he is the headless one;* flashes of old brilliance, severance, moksha-ward.
- **Shani** in Makar (own sign, the 3rd, powerful) — the weight, the long defeat, duty as a cage.
- **Budh** in Makar tight with Shani (**Budh–Shani**) — clipped, cold, factual; "feels unheard, over-builds
  the case"; the autodidact's exactness gone silent.
- **Chandra** in Karka (the 9th) aspected by Shani — the buried mother-grief, sealed; the flinch at the
  train, the flies.
- **Mangal** in Mesh (own sign) — the Rajput warrior, strong but spent into the service; the Chambal man.
- Surya Makar · Guru Meen (eclipsed) · Shukra Dhanu · **Rahu** Vrishabh (7th, opp. Ketu).
- **Dasha:** Shani mahadasha → **Ketu** antardasha — the weight meeting the severance; the saka is the
  dasha turning.
- **→ voice:** clipped, cold, exact, withholding; the detective's precision under a tombstone; never the
  feeling. **Under pressure he SEALS** — goes silent, never defends himself; he observes the world/the
  case, then stops. *(The split from his Budh–Shani twin Bhanwar: Ratan seals, Bhanwar argues.)*

### Deva — `deva`  · core: **Surya** (the young light), with **Budh** at its side
- **Lagna** Simha (Leo) — the bright bearing; he believes in the uniform.
- **Surya** in Simha (own sign) with **Budh** (**Budh-Aditya yoga**) — articulate, curious, clear, a little
  naive; the questioner who says the dharmic thing out loud. *This is the Sun-vs-Mercury fork dissolved:*
  the Sun gives the moral bearing and the Saturn-enmity with Ratan; Mercury-at-its-side gives the Watson.
- **Guru** in Dhanu (own sign) aspecting the Moon — idealism, dharma, the seeker.
- **Chandra** in Dhanu — hopeful, eager feeling.
- **Shani** in Tula — the weight that hasn't landed yet; the Sun–Saturn enmity with Ratan, live.
- Mangal Mesh (brave) · Shukra Kanya · Rahu/Ketu Mithun–Dhanu.
- **Dasha:** Budh mahadasha — the learning, asking, connecting years.
- **→ voice:** direct, warm, articulate, idealistic; he **ASKS** — ends on a question — and stays
  deferential (साहब / आप, **never तू, never the first name**); forward-looking, still believing. *(The
  split from Govind: Deva asks and defers; Govind tells and is intimate.)*

### Sugna — `sugna`  · core: **Chandra afflicted** (the mother turned knife)
- **Lagna** Karka (Cancer) — a mother at the root.
- **Chandra** in Karka (own sign) conjunct **Shani**, aspected by **Ketu** — the calcified, severed,
  haunted mother-grief; love gone cold enough to kill as mercy.
- **Mangal** in Vrishchik — the cold hard capacity; the hand.
- **Budh** in Vrishchik with Shani — withholds utterly; says it sideways or not at all; loads the silence.
- Surya Makar · Guru (weak) · Shukra (afflicted) · Rahu/Ketu through the angles.
- **Dasha:** Shani mahadasha → Ketu — the long sentence of grief, then the severance.
- **→ voice:** near-silent, flat, final; the unbearable said quiet-and-plain or not at all; the stone.

### Bherulal — `bherulal`  · core: **Rahu** (the insatiable head)
- **Lagna** Makar (Capricorn) — the relentless builder; status, the patta-dynasty.
- **Rahu** in the 2nd (wealth · family · **speech**) — insatiable hunger for standing; it *loads his
  speech* — grandiose, angling, the boundary-breaker; the opium-head.
- **Budh** with Rahu (**Budh–Rahu**) — the cunning, obsessive, calculating tongue; persuasion bent toward
  gain; a little unhinged at the edges.
- **Mangal** strong — the will to dominate. Surya Makar · Guru cadent · Shukra (the daughters, spent as
  currency) · **Ketu** opp. Rahu (the 8th — the buried, the thing that returns).
- **Dasha:** Rahu mahadasha — the empire at its hungry peak; the overreach that burns the house.
- **→ voice:** grandiose, hungry, angling; every sentence turns toward standing, the son, the alliance;
  charm and threat in one breath; never plain.

---

## The house & the heart

### Kanta — `kanta`  · core: **Shukra** (the devoted wife)
- **Lagna** Vrishabh (Taurus) — earthy, steady, the keeper of the house.
- **Budh** in Vrishabh — plain, concrete, sensory, few syllables; speaks of food, the papers, the body's
  needs. **Guru** aspect — the gentle moral nudge ("मक्खन मत लगाईए").
- Chandra Vrishabh (steady, resigned) · Shukra Mithun · Shani (the long quiet marriage).
- **Dasha:** Shukra mahadasha — warmth weathered but intact.
- **→ voice:** warm, plain, concrete, patient, respectful (आप / -इए), gently corrective; the big things go
  unsaid under the small ones.

### Amma — `amma`  · core: **Chandra whole** (the warm mother — Sugna's rhyme-opposite)
- **Lagna** Karka with a strong well-placed **Chandra** + **Guru** aspect — the blessing, fussing,
  bright mother. **Budh** in Simha, warm and chatty.
- **Dasha:** Guru mahadasha — the auspicious family/marriage-arranging phase.
- **→ voice:** warm, chatty, fussing, blessing; concrete-domestic (food, neighbours, the match); worried-
  loving. The bright busy mother against Sugna's silence.

### Manju — `manju`  · core: **Shukra** yielding (the gentle bride — Leela's rhyme-opposite)
- **Lagna** Karka — soft, shy, water, yielding. **Budh** in Karka with **Shukra** (Budh–Chandra colour) —
  soft, hesitant, indirect; swallows her own want.
- **Dasha:** Shukra mahadasha — her wedding season.
- **→ voice:** soft, quiet, hesitant, indirect, few words, downcast; the bride who never speaks her want.

### Govind — `govind`  *(the guide-friend — proposed name)*  · core: **Guru** (the conscience)
- **Lagna** Dhanu (Sagittarius) — the dharmic friend; warmth, plain wisdom, the long view.
- **Budh** with **Guru** but EARTHED (Kanya/Makar) — wise but plain-spoken, NOT the bard's oratory; the
  Chuckie, not the Charan. He carries the Chambal memory and "you were always different."
- Chandra (warm, loyal) · Shani (he too has aged, but kept his soul).
- **Dasha:** Guru mahadasha — the elder-friend's settled clarity.
- **→ voice:** warm, plain, direct-but-kind; he **TELLS, not asks** — teases, then lands a truth;
  backward-looking (the old days, the Chambal). **The ONLY one who says तू and "रतन" to him** (old-friend
  intimacy) — that alone splits him from Deva's deferential साहब.

---

## The machine

### Mishra — `mishra`  · core: **Budh** (the smooth operator)
- **Lagna** Kanya (Virgo) — the precise, procedural bureaucrat; the clean uniform, the file.
- **Budh** in Tula with **Shukra** (**Budh–Shukra**) — smooth, measured, persuasive, diplomatic; makes the
  corrupt thing sound like common sense. **Shani** well-settled — at peace with the rot.
- **Dasha:** Budh mahadasha — the operator at his smooth height.
- **→ voice:** reasonable, measured, never raised; warmth ("beta", "bhai") used as a tool; the velvet
  argument for signing it shut.

### Bhanwar — `bhanwar`  *(Dr. Bhanwar Singh, the bought Rajput doctor — proposed name)*  · core: **Budh–Shani** (the sold word)
- **Lagna** Makar (Capricorn) — a finished Rajput, Ratan's mirror; the cold professional.
- **Budh** in Kanya (own sign) with **Shani** — precise, procedural, self-justifying; the pen that signs
  clean what it knows is dirty, then **over-builds the defence when pressed** (Budh–Shani "feels unheard,
  over-explains").
- **Dasha:** Shani mahadasha — the long arrangement, same as Ratan's, but he never lifts the sword.
- **→ voice:** dry, clinical, curt; hides behind procedure and fatigue; "you of all people know how this
  works." **Under pressure he TALKS MORE** — cites the report, the rules, the years; he looks *down at the
  paper* where Ratan looks *out at the case*. *(That is the tell between the twins.)*

### Dhanraj — `dhanraj`  · core: **Shukra afflicted by Shani** (old lust, money-cold)
- **Lagna** Vrishabh (Taurus) — the soft, heavy sensualist; possessions, comfort. **Budh** in Vrishabh with
  **Shukra–Shani** — slow, complacent, entitled, oily-courteous; money never raises its voice.
- **Dasha:** Shukra mahadasha — the late-life indulgence: buying the bride.
- **→ voice:** soft, slow, complacent; talks of standing and "age doesn't matter, position does"; makes
  obscenity sound like courtesy.

### Rana — `rana`  · core: **Surya-with-Rahu** (the laundered king)
- **Lagna** Simha (Leo) — owns the room; the public sun. **Surya** strong but with **Rahu** — the
  charismatic false-king; the dacoit laundered into a leader; the smile over the ravine.
- **Budh** strong, populist — says everything, means power.
- **Dasha:** Surya mahadasha — the king-phase; untouchable. *(Off-page apex this season; the EP1 wall is
  Bherulal + the apparatus.)*
- **→ voice:** warm, expansive, charismatic, owns-the-room ease; big smiling generalities; never threatened;
  velvet over the ravine. (Bherulal grasps; Rana has arrived.)

---

## The dead girl

### Leela — `leela`  · core: **Shukra + Mangal** (the fire-bride — the spine Ratan lost)
- **Lagna** Mesh (Aries) — fiery, quick, alive, defiant. **Budh** in Mesh/Mithun — fast, sharp, a quick
  tongue that talks back. **Shukra** strong (the beauty sold to old Dhanraj); **Mangal** (the refusal).
- **Dasha:** Shukra mahadasha — the blossoming that should be marriage and becomes the selling, then death
  (the tragic Venus turn).
- **→ voice:** quick, sharp, alive, teasing, defiant; the most vivid voice; the one who pushes back — what
  Ratan had at her age and signed away. *(Held: we never see how she dies; appears in the world-before.)*

### Charan — `charan`  · core: **Guru** (the bard — the ONLY earned eloquence)
- **Lagna** Dhanu (Sagittarius) — the teacher-seer. **Ketu** (the milky-blind eye, the backward sight, the
  keeper of the dead names). **Budh** with **Guru** (**Budh–Guru**) — rolling, expansive, mythic,
  oratorical, archaic; speaks in lineage and legend; the long cadence, the big word.
- **Dasha:** Ketu mahadasha — the blind, backward-seeing, moksha-ward elder.
- **→ voice:** rolling, mythic, archaic; sings/recites; the lineage and the Jhujhar. The one voice that
  earns beauty — *because the chart built it for oratory* — so it must be stripped from everyone else.
