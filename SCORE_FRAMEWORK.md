# SCORE_FRAMEWORK.md — the scoring craft, codified

*The music side of the engine, built the way the writing side was: grounded in the craft canon, codified
into a method, enforced by a gate. The score is not background; it is the layer that carries the subtext
the surface withholds. This doc is story-agnostic; §8 is AMAL as the worked example.*

---

## 0. The law (read first, every cue)

1. **The score serves the drama, never itself.** (Davis; Karlin & Wright; Lynch's *"don't change a single
   note."*) If a cue is beautiful but does no dramatic job, it is wallpaper — cut it.
2. **Music carries the SUBTEXT** — the emotional truth the dialogue and image will not say. This is the
   Twin Peaks principle: the calm surface, the dread underneath.
3. **Theme economy.** One central-character theme + one or two dramatic themes, developed deeply. A
   leitmotif for *everyone* is the scoring version of over-writing. (Karlin & Wright.)
4. **Silence is a cue.** Do not score wall-to-wall. The power of a theme is in the rooms where there is
   none. Every cue defends its existence or is cut. (Davis.)
5. **Mood-direction, not technical direction.** A cue is specified by an evocative verbal *brief* — place,
   atmosphere, who/what is present, the emotional truth, the arc — never by notes. The brief is the spec
   (the Badalamenti/Lynch method).

---

## 1. The canon (the sources, like the writing books)

- **Richard Davis, *Complete Guide to Film Scoring*** — the *grammar*: the dramatic **functions** of music,
  **spotting**, source vs. underscore, ethnic/period instrumentation, the mix (music yields to dialogue),
  the discipline of not over-scoring.
- **Fred Karlin & Rayburn Wright, *On the Track*** — the *architecture*: **spotting notes + timing notes**;
  the **central-character theme**, the **single / two dramatic themes**, characterization through theme;
  **theme economy**.
- **The Badalamenti / Lynch method** — the *method*: **mood-direction → music**; a cue has a **dramatic
  arc** (place → the theme materialises → it builds → it recedes); **emotional truth over literalism**;
  spaciousness; the vision is law.

The unifying artifact across all three is the **mood brief**: it names the **function** (Davis), invokes a
**theme in a state** (Karlin & Wright), and gives the **mood-arc** (Badalamenti).

---

## 2. The cue-function taxonomy (Davis) — every cue declares ONE primary job

| function | what it does |
|---|---|
| **PLACE** | set geography / period / culture |
| **MOOD** | establish or sustain atmosphere |
| **SUBTEXT** | reveal the unspoken inner life (the load-bearing one) |
| **TENSION** | build / sustain / release suspense |
| **LEITMOTIF** | signal a character or idea (a theme is present) |
| **CONTINUITY** | bind scenes, carry across a cut |
| **COMMENT** | ironic counterpoint to the image |
| **SILENCE** | deliberately no music — also a decision |

A cue may carry a secondary function, but it must have one clear primary, or it is wallpaper.

---

## 3. The spotting schema — the per-scene record (the operational artifact)

For every scene, one SPOT record (or `SILENCE`):

- **in / out** — where the cue enters and leaves (often *not* the whole scene).
- **function** — the primary cue-function from §2.
- **leitmotifs** — which themes are present **and in what state** (e.g. *Ratan: stirring*; *Rana: curdled*).
- **mood brief** — 3–5 sentences of Lynch-style direction: the place, the atmosphere, who/what is present,
  the emotional truth, and the movement. This is what the generator reads.
- **arc** — the cue's shape: `held-still` / `slow-build` / `build-and-resolve` / `hard-stop` / `under-and-out`.
- **palette** — the instrument colours pulled for this cue.
- **mix** — where the cue ducks for dialogue, and whether it drops out under key lines.

---

## 4. The leitmotif palette — economy + transformation (Karlin & Wright)

A show declares **one central theme + one or two dramatic themes**; everything else is *texture*, not a
named theme. The iron rule: **a theme must change when its character changes** — never restate it static.
Each theme is defined by (a) a recognisable melodic/timbral seed, and (b) its **states**.

---

## 5. Realization — brief → cue

- **Tooling:** ElevenLabs Music API (`force_instrumental`) as primary; MusicGen as fallback (the INDIVISIBLE
  score path, `examples/score.py`).
- **Brief → prompt:** the mood brief becomes the generation prompt — instrumentation + mood-arc + the
  named leitmotif/state as the melodic intent. Keep the Lynch language; it generates better moods than
  technical terms.
- **Leitmotif consistency:** reuse a fixed seed phrase / stem per theme so the same motif is *recognisable*
  across its states (the listener must feel "that's Ratan" even when it has darkened).
- **Length:** the spotted in/out, not the whole scene. Generate to the cue, not the runtime.

---

## 6. The score gate (analogous to the craft gates)

- **Function declared** — every cue names a primary function; flag functionless cues.
- **Economy** — ≤ 1 central + 2 dramatic named themes; flag a fourth.
- **Presence** — the right theme is present where its character/idea is; flag a missing or *wrong* leitmotif.
- **Transformation** — a theme's *state* matches the character's state (no CHARGE-theme in a defeated scene).
- **Silence** — flag wall-to-wall scoring; some scenes must be unscored so the rest can land.
- **Mix** — the cue yields to dialogue; flag a cue that fights the words.

The gate over-flags by design; the human is the stop. Don't chase a perfect cue — chase the dramatic job.

---

## 7. The workflow (per episode)

1. **SPOT** — walk the locked script scene by scene; write each SPOT record (or mark SILENCE).
2. **PALETTE** — generate the leitmotif seeds once (the base motifs in each state).
3. **REALIZE** — generate each cue from its brief + seed.
4. **GATE** — run §6.
5. **MIX** — layer the cues under the voices (duck for dialogue) into the assembly.

---

## 8. AMAL — the worked palette

**CENTRAL · रतन / झूझार (the saka man).** Seed: the Jhujhar motif. States —
- **DEAD** — a hollow, deadened sarangi, no pulse, a held note that won't resolve ("वर्दी पहने एक लाश"). The
  compromised years.
- **STIRRING** — a slow heartbeat (nagara, far off) enters; the motif half-forms but never completes. As he
  wakes (the sleeplessness, the refusal).
- **CHARGE** — the full Jhujhar: nagara + dhol + the war-cry, the headless one who fights on. Reserved for
  the saka register — the corpse-walks-on ending, and (season) the saka itself.

**DRAMATIC A · राणा / the velvet ravine (the antagonist's "Leland tinge").** Seed: a warm, folksy
benediction phrase (sweet sarangi / harmonium, almost a blessing) laid over a **low detuned drone** — the
rot under the velvet. States —
- **VELVET** — pure sweetness, the public charm (the durbar, the offer). The horror is that it's lovely.
- **CURDLED** — the drone surfaces, one wrong interval — when the host steps back and the ravine looks out
  (the measure-taking after the नहीं; the आराम order).

**DRAMATIC B · the priced girl + the silenced mother (लीला, and सुगना's grief).** Seed: a **Rudaali**
(रुदाली) lament — a solo Rajasthani female voice keening wordless *alaaps*, long aching melismas that rise
into something between a song and a woman's stifled scream of grief, doubled and answered by a lone
sarangi over a low sustained drone. The Rudaali is the hired mourner who wails the grief a family is
forbidden to show; here it is **सुगना's** — the mother who must not be heard (and, held card, must not be
*found out*). It plays on लीला (the morgue, the sale/धनराज) and on **every सुगना–रतन exchange**. Raw,
funereal, unresolved — it never completes, because her grief never gets to. *(USER-SPECIFIED; the one cue
whose sound is fixed.)*

**TEXTURES (not named themes):**
- **the तौल / patta economy** — a cold metallic tick under a tanpura drone; the machine weighing everything
  (the cash, the deals).
- **the belt / Malwa** — algoza folk-flute and cold-dawn ambience; beautiful and rotten at once.

*Spotting note:* much of AMAL should be **unscored** — the realist register lives in dialogue and room
tone. Reserve the cues for the moments that need their subtext sung: the held morgue, Rana's velvet, the
cut, the thaw with Kanta, the corpse that walks on. (`docs` cross-ref: the One Law and clear-pane apply to
music too — intrigue lives in the drama, not in a busy cue.)
