# Standard transitions — production-engine recipes (reusable across shows)

Transitions are a *standard*, not a per-episode decision. Codified here so the assembly applies the same
move every time. Approved on AMAL Ep2 (cold-open → title), 2026-06-22.

---

## 1. COLD OPEN → TITLE  (series standard)

The cold open ends on a spoken line; the title sequence has its own music track. The join must never (a)
start the music over a word, (b) leave a silent gap long enough to read as "something broke," or (c) hard-cut.
The **music carries the handoff**, and the title **grows out of the music on black**.

**Recipe.** Let `T` = the end of the cold open's last spoken word (the last audio segment's end).

| time | picture | sound |
|---|---|---|
| `T` | final cold-open image begins fading to black (**~1.0s**, black by `T+1.0`) | title track enters **from its absolute start (0:00)**, fade-in **~1.8s**; cold-open score bows out **~1.3s** |
| `T+1.0 … T+3.5` | **black**, held | music plays on black — the beat |
| `T+3.5` | title visuals **rise** (fade-in **~1.6s**) | music continues, building |

So the music starts the instant the word lands, the picture goes to black under it, and the title appears
**~3.5s into the music** (tunable 3–4s). No silence; nothing reads as a cut.

**Laws.**
- Title music is taken from the track's **absolute beginning** — never a later/climax window (the build must
  start low so it can grow). *(Why this rule exists: AMAL Ep1-era bug — a 123s-in climax window read as "too
  upbeat.")*
- Never overlap the music with the final word. Start it *at* the word, not before.
- The cold open almost never has real space after its last line (AMAL Ep2: 0.3s). The transition **manufactures**
  the space — hold the last frame / go to black — it does not rely on the cut having room.

**Params (tunable):** `music_from=0.0`, `picture_to_black=1.0`, `coldopen_audio_out=1.3`, `music_fade_in=1.8`,
`title_rise_after=3.5`, `title_fade_in=1.6`.

**Reference build:** `stories/amal/transition_demo4.mp4` (the approved feel).

---

## 2. (reserved) TITLE → EPISODE BODY, SCENE BUTTONS, ACT BREAKS

Same principle — see also the **beat** mechanism (manufactured silence at dramatic landings, score allowed to
ring), which is the general case this transition is a specific instance of.
