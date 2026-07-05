# The writing-issues catalogue

Every distinct writing problem the system gates against, deduped and grouped the way a writer thinks about them (not the way the code files them). The same tell is often enforced in two or three places — once by deterministic code, once by an LLM critic, once in a doc — those are merged here into one entry.

Tag on each item: **[code]** = a regex/parser catches it deterministically · **[judge]** = needs an LLM critic · **[code+judge]** = both.

Sources swept: `metaphrand/` (passes, craftlint, naturalness, showing, concreteness, embodiment, density, heart, dossier, blind_attribution, cinema, drama, scene_craft, weave, world, doorways, kishotenketsu, arrangement, canon, editor), `examples/prose_gates.py`, `docs/01–07`, and the skills (humanizer, clear-pane, drama-enhancer, screenplay-humanizer, writing-style) + memory.

The six you keep coming back to most: **punchy/staccato prose**, **the telling narrator (show-not-tell)**, **shrink-wrap**, **the appended fact**, **every character sounding the same**, and **presenting things to you that aren't self-contained.**

---

## 1. AI prose voice — sentences arranged for effect
The umbrella, "the One Law": if a line sounds like *writing* when read aloud as that person in that moment, it's wrong, however good it sounds. [judge: naturalness.py]

- **Punchy / staccato run** — three or more short, clipped sentences in a row. [code]
- **Two-word punch** — a ≤3-word sentence ended for impact ("Cold."). [code]
- **Completion fragment (withhold-then-append)** — a verbless fragment finishing the prior sentence's information ("Four. All black."). [code]
- **Comma-drip** — the same withholding via commas ("Forty-one people, a church group, the wrong neighborhood…"). [code]
- **Appended fact / end-loaded detail** — a fact stapled on after the sentence closes ("…दूँगा, नक़द।"). [judge — clear-pane exempts dialogue, so this gate catches it]
- **Corrective definition** — "That's not X. That's Y." [code]
- **Negative parallelism** — "not just X, but Y" / "not only… but…". [code]
- **Rule of three as rhythm** — three parallel items used as a drumbeat. [code]
- **Coined epigram / chiasmus / balanced antithesis** — sentences built to be quoted ("He didn't have a plan. He had a problem."). [judge]
- **"X stopped being X" / paradox-button / category-crossing wit** — the cleverness formulas. [judge]
- **Held-to-the-end punch** — the key word withheld for the final slot. [judge]
- **Facts recited as beats** — telegraphic noun-phrases for atmosphere ("छब्बीस की रात। पौने दस बजे।"). [judge]
- **Em-dash overuse / semicolon literariness** — over-punctuating for "punch." [code]
- **AI vocabulary** — delve, tapestry, testament, underscore, vibrant, pivotal, intricate, showcase, nestled… [code]
- **Copula avoidance** — "serves as," "stands as," "boasts" instead of is/has. [code]
- **Elegant variation** — synonym-cycling one thing (the man / the figure / the hero). [judge]
- **False range** — "from X to Y" where X and Y aren't on a real scale. [code]
- **Clickbait opener / cadence** — "Here's the thing," every sentence begging the next. [code]
- **Poignancy-reach ending / tidy bow** — the engineered lump-in-throat closer. [judge]

## 2. Show-don't-tell — the telling narrator / unfilmable lines
A screenplay line can only be what a camera sees and a mic hears.

- **Naming the feeling/state** — "she was jealous," "he felt regret." [code: showing.py]
- **Interiority verbs** — knew, realized, understood, remembered, decided, sensed. [code]
- **Unfilmable action** — thoughts, memory, knowledge, meaning the lens can't photograph ("He remembers his father"). [judge]
- **Interpretive -ing tail** — an action explaining its own meaning ("pocketing the ring, symbolizing surrender"). [judge]
- **Meaning-naming clause** — "…which meant the walls talked both ways." [judge]
- **Abstract face-read** — "something mean and amused crossed his face." [judge]
- **Over-choreographed blocking** — "he lowers himself, his body betraying its exhaustion" for "he sits." [judge]
- **The explaining narrator / V.O. that tells** — "We watch… we see… we don't hear…". [judge]
- **Telegraphing** — a character announces an act then does it ("I'm going to open this door now"). [judge]
- **Summary construction** — "there was no out-arguing him," "the truth was…". [code]

## 3. Flowery / ornament (concreteness)
Aim ~0% flowery; every image physical; a metaphor must carry a legible meaning, not decorate.

- **Simile** — any "like…" or "as X as." [code]
- **Purple verb** — glass bleeds, stone sings, the sea breathes, a hum thrums. [code]
- **Abstract poetic noun** — betrayal, longing, oblivion, fate, anguish, essence. [code]
- **Brochure adjectives** — vibrant, breathtaking, nestled, must-visit. [code+judge]
- **Cute conceit / metaphor admiring itself** — "the pause had a kitchen in it." [judge]
- **Personification flourish** — "the bags waited patient." [judge]
- **Costume metaphor** — "wearing the uniform / clothes / skin of…". [code]
- **Un-embodied metaphor** — concrete but carries no legible meaning off the page. [code+judge]

## 4. Shrink-wrap — the thin, skeletal, generic draft
- **Skeletal (bone only)** — the thinnest story stretched over exactly the handed beats; the abstract where the specific belongs. [code: density.py + judge]
- **Generic placeholder** — a stand-in instead of the lived particular of THIS exact world. [judge]
- **Declared-but-undramatized want** — a character given a want who never gets a beat to pursue it (set-dressing). [code]
- **Synopsis wearing dialogue** — telling the story as a passive summary instead of a scene with momentum. [judge]

## 5. Dialogue
- **On-the-nose** — saying exactly what they feel and mean, no subtext. [judge]
- **Theme stated aloud** — a character announcing the moral. [judge]
- **As-you-know-Bob exposition** — characters telling each other what they both already know. [judge]
- **Too-clean / articulate about pain** — real speech is messy, halting, evasive, inarticulate about wounds. [judge]
- **Everyone witty / wise-ass-itis** — writer-wit in every mouth; carved epigrams that land too perfectly. [judge]
- **Stock AI lines** — "we need to talk," "you have no idea," "promise me," "after everything we've been through." [code: word-list]
- **Wrylies** — an adverb parenthetical on every line, JANE (angrily). [code-ish]
- **Throat-clearing** — hellos, goodbyes, errand-logistics played in real time. [judge]
- **Hindi idiom calqued from English** — an English metaphor translated word-for-word ("a corpse in a uniform"), not a native idiom. [judge]

## 6. Voice — characters all sound the same
- **Indistinct voice** — cover the name cues and you can't tell who's speaking. [judge: blind_attribution.py]
- **Everyone sounds like "the writer"** — one nervous system shared across the cast. [judge]
- **Unearned eloquence** — articulacy a character's station/caste hasn't earned. [judge]

## 7. Scene is information, not a fight (drama)
- **Postcard scene** — no one wants something badly, no wall, no turn. [code+judge]
- **No stakes / no clock** — nothing lost on failure; no "why now." [judge]
- **No opposition** — two people who agree; a meeting, not a scene. [judge]
- **No reversal / frictionless win** — the pursuer simply succeeds. [judge]
- **Exposition as briefing** — a fact entering for the audience, not as a weapon between characters. [judge]
- **Two people discussing an absent third** — no engine between the bodies on screen. [judge]
- **Easy for the hero / no escalation** — the objective isn't hard to the edge of impossible. [judge]
- **No plot change / no character change** — situation or interior ends exactly as it opened. [judge]
- **Character as narrator** — voicing the theme, the ending, or what the moment "means." [judge]
- **One-note / redundant beats** — beats repeat instead of escalating. [judge]

## 8. Heart — emotion announced, not earned
- **Announced feeling** — "a cold dread settled over him." [judge]
- **Inhuman / convenient reaction** — a grieving parent behaving like a clerk. [judge]
- **Unbanked wound or thaw** — a bond breaks or warms with no deposit banked earlier (you can't argue someone warm). [code: heart.py]
- **Free kindness** — a mercy that costs the character nothing, so characterizes nothing. [code+judge]
- **Decorative feeling** — bonds that never gate the plot. [code]

## 9. Subtext / secrets / theme — saying the quiet part loud
- **Theme stated aloud.** [judge]
- **Backstory leak** — the submerged iceberg surfacing as exposition. [code: dossier.py + judge]
- **Held card / Sod leaked** — the surface tipping the secret you're driving toward. [judge]
- **Character states own history** — announcing their backstory instead of carrying it as subtext. [judge]
- **Flattened to one literal layer** — no held depth under the surface. [judge]

## 10. Momentum / pacing
- **The satisfying pause** — closing a loop without opening a bigger one; the reader is free to stop. [judge]
- **Ending on the landing, not the turn.** [judge]
- **Resting / establishing / info-dump beats** — momentum is subtraction; cut the breather that does nothing. [judge]
- **Clean solution** — a problem solved without spawning a worse one (no yes-but / no-and). [judge]
- **Octane fatigue** — flat-line at 11, no valleys; every scene a gunfight. [judge]
- **Surprise over dread** — one-second jolts instead of the bomb you see under the table. [judge]
- **Abstract stakes** — stakes you can't see instead of a face, a child, a losable thing. [judge]

## 11. Structure / spine (gates the shape, not the sentence)
- **No promise / opening on weather** — an opening that makes no contract, or opens on atmosphere instead of a person doing/saying. [judge]
- **Missing / out-of-order doorways** — no Act-1 lock-out or Act-2 push, or out of order. [code: doorways.py]
- **Declared, not tested, transformation** — the change announced rather than proven in the arena. [judge]
- **Monorail** — a single thread, no B-story refracting the theme. [code: weave.py]
- **Frictionless antagonist / the fog** — a villain with no agency and no wall of his own. [judge]
- **Corridor, not a world** — too few characters, no women, props instead of people. [code: world.py]
- **POV drift** — more than one protagonist; the camera leaves his chest. [judge]
- **Kishōtenketsu / descent shape broken** — the four movements absent or out of order; a turn that lands too early. [code: kishotenketsu.py]

## 12. How things get presented TO YOU
- **Not self-contained** — describing the story with insider references, as if you already hold all the context. [judge — the presentation law]
- **Terse shorthand** — beat-lists in clipped fragments instead of connected, self-explaining prose. [judge]

---

### The split that matters for building gates
Roughly half of family 1 (punchy, fragments, corrective-definition, em-dash, AI-vocab, copula, rule-of-three) and the hard show-not-tell labels (family 2) are **[code]** — catchable cheaply and deterministically, no LLM. The rest — on-the-nose dialogue, shrink-wrap, voice-sameness, the subtle slop, theme-stated-aloud — are **[judge]** and need a focused critic. Build the [code] gates first (free, instant, never lenient); back them with [judge] critics that block, never advise.
