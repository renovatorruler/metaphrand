# Scene 8 — the СОК episode, in the author's order

Her hand-drawn sheet is at `kuku_flow/boards/2026-08-19_SCENE8_SOK_AUTHOR-SKETCH.jpeg`; my redraw of it is `..._SOK_author-order_v1.jpg`. This supersedes the СОК beats of BOARD A. Seven shots.

| # | shot | note |
|---|---|---|
| 1 | Overhead, the children's knees diagonally opposite, tiles between them | "What can we make?" — the knees identify the floor |
| 2 | Close overhead, her hand assembles `СОК` OUT OF TILES | the discovery: the word can be spelled at all |
| 3 | Фрося large, seated, writing — **paper not visible**, back of the stove behind her | back plate |
| 4 | Overhead on the paper: `СОК` already written, letters light on her voice, then «Точка!» and the pencil comes down and makes the dot | CARD |
| 5 | Cut to Вася: the glow PASSES OVER HIS FACE. The flash itself is never shown | |
| 6 | Back of his head huge in foreground, Фрося offering the thimble — «Соку хочешь?» | |
| 7 | He looks THROUGH the juice, eye refracted in the thimble — «Ты теперь так ВСЕГДА можешь?» (then maybe pull out as he lowers it) | |

## THE THING THAT MATTERS MOST — the eight letters are the story engine

The word is assembled **from tiles first, and only then written**. That makes the eight letters Мама dispensed the constraint that decides what can happen in the whole episode: `А О М С К Т Л Б` is exactly the alphabet that yields СОК, САЛАТ, МАК, МАМА, КОТ, БАК, ОСА, МОТОК, САМОКАТ — the entire word list of ep1. The children are not "doing magic", they are working out what is spellable with what they have. That is the show's actual engine and it was not visible in my version, where Фрося simply wrote whatever she fancied.

Consequence for the other two words: **do not repeat the tile-assembly beat.** СОК needs it because it is the discovery. САЛАТ she writes straight off (she has the idea now). МАК she writes giggling. The tile step appearing once and then being dropped IS the escalation.

## Never show the materialisation

The appearance of the juice is not filmed. Beat 5 is the reflected light crossing his face; beat 6 the thimble simply exists. This removes the hardest generated effect in the scene and puts the moment on a child's face, which is where it belongs. Apply the same rule to САЛАТ and МАК.

## The period is a physical act

«Точка!» is the pencil coming down and pressing a dot into the paper — not a mystical rising dot. It matches Grandma's rule («поставишь точку») and it is animatable in the compositing layer with no generation at all.

## BACK PLATE — pipeline consequence

The author marks "back plate" on shots 3 and 6. If the room's surfaces are locked as plates (the back of the stove, the boulder wall, the mat) and characters are composited over them, the room stops being re-invented per shot, which is the defect the geography law has been fighting since scene 6. Shots 1, 2 and 4 in this sequence contain no room at all — they are floor, paper and hands. Shot 3 is one plate plus one seated child.

**Open question for the author:** does "back plate" mean a still we lock and composite over, or simply the correct background to specify in the prompt? The answer changes how much of this scene needs generating at all.


---

## ROOM POPULATION — settled by the author 2026-08-19

Map: `kuku_flow/boards/2026-08-19_SCENE8_ROOM_MAP_v1.jpg`

- **МАМА** sits at the table in her usual place.
- **БАБУШКА-ЯГА** and **ПАПА** are at the same table.
- **РУСЯ and МУСЯ play on a small rug in front of the table, right beside Мама.**
- **ФРОСЯ and ВАСЯ** work downstage of them, closer to camera, with the tiles and the paper.
- The back of the giants' stove is the upstage wall; the niche and the cleanout hatch are on the left, the ramp on the right.

**The rug is the babies' starting point for the whole Вася-Мама sequence.** This is the detail that sharpens the joke: they are sitting next to their real mother, and they still cross the room to the fake one. The betrayal reads because it was not a long crawl and they left the mother who was already within reach.

It also gives the launch (SH127-128) an actual distance to cover, which is what makes it filmable — they start at the rug and arrive at Вася-Мама, rather than simply being near him already.

Мама leaves her seat exactly twice in the scene and both times along the same path, table → children: once for the poppy (SH117-118), once to peel the babies off (SH132-133).

## DECIDED — the tile build is partial and silent

She completes `СОК` in tiles on screen so the young audience can read it, but she does **not** say the letters there. The searching is hands only. The spelling aloud happens once, at the paper, where the letters light. One spelling, in the place where it does work.

Split of line 52 accordingly:
- over the tiles (shots 1-2): «Так. Пробуем. Что можно написать?»
- at the paper (shot 4): «С-О-К. СОК!» then «Точка!»

Note also that Фрося uses ВАСЯ'S tiles to plan the word she then writes with her own pencil. The two gifts already lean on each other in the very first game, which is Яга's whole design («порознь — никак») showing up quietly long before anyone says it.


---

## PRICE — the СОК segment (2026-08-19)

All on `seedance_2_0_mini` at **2.5 credits/second**. Gate minimum is 4s. Scene 7's real per-job costs were 20 / 25 / 27.5 / 30 / 32.5 / 35 / 37.5 for 8-15s, so these numbers are the same arithmetic the ledger already recorded.

### Option B — recommended: generate only the shots with a performance in them

| # | shot | how | sec | credits |
|---|---|---|---|---|
| 1 | overhead, knees + tiles | **composite** — generated floor/knees plate with BLANK tiles, letters composited | — | 0 |
| 2 | her hand assembles `СОК` | **composite** — same plate, hand pass, author's tile art | — | 0 |
| 3 | Фрося seated, writing, back plate | GEN | 6 | 15.0 |
| 4 | overhead paper: С-О-К lights, «Точка!» | **CARD** | — | 0 |
| 5 | the glow crosses Вася's face | GEN | 4 | 10.0 |
| 6 | over his head, «Соку хочешь?» | GEN | 5 | 12.5 |
| 7 | looking through the juice | GEN | 6 | 15.0 |
| | **subtotal** | | **21s** | **52.5** |
| | retry allowance — shots 3 and 7, one each | | 12s | 30.0 |
| | **envelope** | | | **~90** |

### Option A — generate shots 1 and 2 as well

Adds 5s + 5s = 10s = **25 credits**, plus a retry allowance for them, because **these are the two shots with Cyrillic letters in frame** and letters are exactly what the model gets wrong. Every letter shot in scene 7 came back with duplicated and invented characters, and fixing them cost a day of compositing. Envelope **~120**, at materially higher risk of a reshoot.

### Why B is not a compromise

Shots 1, 2 and 4 are all the same thing: a flat floor seen from above with wooden tiles and paper on it. There is no acting in them and no camera move that matters. Once one plate of that floor exists — with the children's knees in frame so the surface reads — all three are composites, and the author's own tile and letter art goes straight in without the model ever being asked to spell.

That leaves the model doing only what it is good at: a child folded up on the floor writing, a light crossing a face, an offer of a thimble, and a boy squinting through juice.

### Not credits, but required before the segment can be finished

- the composable alphabet (author) — blocks shot 4 and the tile art for 1-2
- **«Точка!» has never been recorded** — three short ElevenLabs takes, no credits
- Мама's voice recast does not touch this segment

**Compare:** scene 7 was 250 credits for 82 seconds of cut footage. This segment is roughly 25 seconds of screen time for **~90**.


---

## PRICE, CORRECTED (2026-08-19, same day)

The ~90 figure above priced shots 1, 2 and 4 at zero by treating them as stills with an overlay. That is exactly the stiffness the author objected to, so the figure was cheap for a bad reason. See `COMPOSITE_LIVENESS_LAW.md`.

**Every shot is a generated live plate.** The letters are ours in the shots that contain letters; nothing else changes.

| # | shot | sec | credits |
|---|---|---|---|
| 1 | overhead, knees + tiles, "что можно сделать?" | 5 | 12.5 |
| 2 | her hand turns and places the tiles | 5 | 12.5 |
| 3 | Фрося seated, writing, back plate | 6 | 15.0 |
| 4 | overhead on the paper, «С-О-К», «Точка!» | 6 | 15.0 |
| 5 | the glow crosses Вася's face | 4 | 10.0 |
| 6 | over his head, «Соку хочешь?» | 5 | 12.5 |
| 7 | looking through the juice | 6 | 15.0 |
| | **subtotal** | **37s** | **92.5** |
| | retry allowance — 3 shots | 15s | 37.5 |
| | **envelope** | | **~130** |

Shots 1, 2 and 4 are shot with **blank tiles and blank paper**, or with the tiles face down. The model is never asked to spell anything, which is the whole point; it is asked to give us children moving on a floor, which it does well.

Roughly 25 seconds of screen time for ~130 credits, against scene 7's 250 for 82 seconds.


---

## PRICE, SETTLED (2026-08-19)

The tile-scale finding removes the need to composite the tile field at all — see `COMPOSITE_LIVENESS_LAW.md`. Every shot is generated; only the paper letters in shot 4 are the author's art, which is her design and not a workaround.

| # | shot | sec | credits | tiles |
|---|---|---|---|---|
| 1 | overhead, knees + tiles, «Что можно написать?» | 5 | 12.5 | NOT READABLE — a scatter, nobody reads it |
| 2 | her hand assembles `СОК`, tight and locked | 5 | 12.5 | ~13% of frame height, the jobD case |
| 3 | Фрося seated, writing, back plate behind her | 6 | 15.0 | — |
| 4 | overhead on the paper, `С-О-К`, «Точка!» | 6 | 15.0 | author's letters over a live plate |
| 5 | the glow crosses Вася's face | 4 | 10.0 | — |
| 6 | over his head, «Соку хочешь?» | 5 | 12.5 | — |
| 7 | looking through the juice | 6 | 15.0 | — |
| | **subtotal** | **37s** | **92.5** | |
| | retry allowance — 3 shots | 15s | 37.5 | |
| | **envelope** | | **~130** | |

Expected finishing work, not counted as credits: repainting one or two glyphs on the static tiles of shot 2, exactly as `Б`-as-`6` was repaired in scene 7.


---

## «И ТО́ЧКА» — RECORDED AND CHOSEN, 2026-08-20

`kuku_flow/audio/tochka_FROSYA_APPROVED.mp3` — 1.52s, Ekaterina `GN4wbsbejSnGSa1AzjH5`, the same voice as every other Фрося line. Registered in `LINE_INDEX.json`.

**The line is «И то́чка», not «Точка».** A bare one-word line has no run-up and a voice model lands it flat or turns it into a question. «И то́чка» is also idiomatic — it means *and that is that* as well as naming the mark — so the phrase she ends on is both the physical act and the seal. It answers Бабушка's rule, «поставишь точку».

**One recording, not one per word.** The Точка clip is generated once and reused in every transformation, so a per-word reading would put a different mouth on the same footage. Three per-word takes were made and deleted for exactly that reason.

Chosen take, as generated:

```
[a breathy delighted whisper] Ии… то́чка!
style 1.0   stability 0.15   similarity 0.75   eleven_v3
```

**It is not actually a whisper, and that was checked rather than assumed.** Autocorrelation across all eight takes shows the four "whispered" ones are 65-84% voiced with a median f0 of 193-291 Hz — the same pitch as the spoken takes, only quieter. A true whisper has no vocal fold vibration at all. **The `[whispers]` tag on this voice lowers the level and keeps full voicing.** So the take is a hushed, breathy, delighted reading, and that is what it should be described as. It is the loudest of the four hushed takes at rms 3528, which matters because the quieter ones would have vanished under room tone.

The drawn-out «Ии…» puts «точка» at 0.32s, which leaves a third of a second of run-up — that is where the pencil comes down, so the word lands **on** the mark rather than describing it afterwards.
