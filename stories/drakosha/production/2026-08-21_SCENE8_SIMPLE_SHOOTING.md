# Scene 8 — the simple shooting script

Built back from the SPEC (SP096-SP122), not from the 35-shot version. The shooting script atomised the spec: 27 beats became 35 shots, and every magic beat became a three-shot ceremony. This restores the spec's pace and keeps only what we can actually shoot.

## THE GOVERNING IDEA — ESTABLISH THE RITUAL ONCE, THEN ABBREVIATE IT

The full ceremony — writing, sounding out, the mark, the ignition, the object — happens **once**, on СОК, because that is the discovery. After that the scene is a comedy and comedy needs speed, so:

| word | how much ritual |
|---|---|
| **СОК** | the whole thing. Write, sound out, «И точка», ignition, object. |
| **САЛАТ** | the word is ALREADY on the paper in graphite when we cut to it. Her hand comes in, the mark, the ignition. No writing shown. |
| **МАК** | fastest of all. Graphite word, mark, ignition, flower — played through her giggle. |

That is the joke shape: the first one is a reveal, the repeats are the punchline, and a punchline cannot be slow. It also removes two writing animations from the budget.

**Graphite-first is the author's idea and it is the key to the whole scene.** A sheet of paper with the word already written in graphite is our own artwork, composited, free — the alphabet has a `graphite` state for exactly this. Only the ignition is an event. So words two and three cost one short plate each instead of a writing performance.

## THE OTHER TWO CONSTRAINTS, AND WHAT THEY BUY

**Never put the adults and the children in one frame.** The author cannot generate a stable image with all seven — adding Фрося and Вася to the table plate causes character drift. So we do not ask for it. Open on the adults (a plate that already exists and works), then cut to the children. That is ordinary coverage, it is cheaper, and it removes the hardest image in the scene.

**Вася never assembles tiles on camera.** Four shots of a boy placing lettered tiles is the single most expensive thing in the old script and the thing the model is worst at. Instead: a start plate of loose tiles and an end plate with `МАМА` already spelled, his hands entering and leaving frame between them. The model interpolates the middle; it is never asked to spell anything. Both frames are ours.

## THE SHOTS — 18, against 35

| # | shot | sec | model | notes |
|---|---|---|---|---|
| 1 | the table: Мама, Папа, Яга talking, babies on the rug | 5 | mini | author's existing plate as start frame |
| 2 | cut to the children on the floor, tiles spilling | 5 | mini | «тук-тук-тук» |
| 3 | over her paper: she writes `СОК`, sounds it out | 5 | mini | letters composited in graphite |
| 4 | **her large, «И точка», the press, the bloom** | 4 | mini | **generated once, reused in every transformation** |
| 5 | flash out — the thimble is there; she offers it | 5 | mini | «Сока хочешь?» |
| 6 | Вася close: «Ты теперь всегда так можешь?!» | 4 | mini | |
| 7 | the paper, `САЛАТ` already in graphite, mark, ignition | 4 | mini | no writing shown |
| 8 | Вася recoils, the bowl is there: «Фу-у-у! Овощи!» | 4 | mini | |
| 9 | Руся crawls in, inspects, crawls out — ONE shot | 8 | mini | was three shots; the joke is the continuous move |
| 10 | `МАК` in graphite, mark, ignition, the poppy | 4 | mini | through her giggle |
| 11 | she carries it to Мама; both lines | 7 | mini | Мама's voice pending recast |
| 12 | Яга hums, Фрося tucks the pencil behind her ear | 4 | mini | two beats in one frame |
| 13 | «А я? Мне слово!» and «Ну собери сам» — two-shot | 8 | mini | both lines in one setup |
| 14 | **tiles: loose → `МАМА` spelled** | 4 | mini | start + end plate, hands passing through |
| 15 | he reads МА-МА, ВЖУХ, light swallows him | 5 | mini | |
| 16 | two Мамы, the family silent behind | 6 | mini | identity risk, one retry budgeted |
| 17 | Мама checks her own brows | 4 | mini | |
| 18 | the swarm: babies launch, cling, «Они меня едят!», the finger pry | 10 | mini | was four shots |
| 19 | Мама lifts both babies off, «Брови-то твои, Вася» | 7 | mini | |
| 20 | angry ВЖУХ, Вася back, Фрося falls over laughing | 6 | mini | |

**110 seconds of generation. At mini's 2.5 credits a second: 275 credits.**

With a retry allowance on the two risky shots (16, the two Мамы; and 18, the swarm): **~315 credits.**

### Where the cheaper models could be used, and why mostly they cannot

Kling 3.0 is 1.5 credits a second against mini's 2.5 — but it takes **no reference images**, and every shot above has a character whose identity must hold. The one exception is shot 14, the tile interpolation, where both frames are ours and no face is in play: on Kling that shot is 6 credits instead of 10.

Kling 2.6 with sound off is 1.0 a second, cheaper still, but it has no end frame, so it cannot do the tile shot either.

**Everything with a face stays on mini.** That was settled by two blank-faced generations on 2026-08-20.

## WHAT IS COMPOSITED, AND THEREFORE FREE

Every letter, in every state — the alphabet has graphite through ignite_90 to magic, and the eight Ep1 letters are done. The ignitions. The «И точка» mark. The materialisation of each object out of the letters breaking apart.

## STILL OPEN

Мама's voice, which gates shot 11. Вася's chips, which have no artwork at all and gate shot 14's end plate. And whether Фрося looks at camera on «И точка» — she never does anywhere else in the show.

---

## TWO SCRIPT CHANGES MADE 2026-08-21

**The pencil does NOT shorten in the pilot.** The author had decided this and it was never written down anywhere, so it survived in five documents and would have gone into the shot list. Removed from the SPEC (SP109), the numbered bilingual (L113), the shooting script (SH119B) and from this document. The shot is now two beats — Яга's approving hum, and Фрося tucking the pencil behind her ear — and it is four seconds instead of five.

The wear rule may return in a later season as a clock. It is not part of the pilot's plot and nothing in the pilot may show it.

**«И то́чка» is now in the script**, on all three of Фрося's words. It goes at the end of her line, with the mark as the action:

> **SP097 — ФРОСЯ:** *(по-хозяйски, быстро)* Так. Пробуем. Что можно написать? С-О-К. СОК! *(опускает карандаш и ставит точку)* И то́чка.

Added identically at SP101 (САЛАТ) and SP105 (МАК), and mirrored in the numbered bilingual at L101/L105/L109 and in the shooting script at SH104/SH109/SH115.

**This gives the two children matching triggers and they are opposite in kind.** Фрося seals with «И то́чка» — quiet, deliberate, a mark pressed into paper. Вася detonates with «ВЖУХ!» — loud, thrown, done to him. Neither of them was written as a pair, but the scene now reads as one, and the difference between the two gifts is audible as well as visible.

One recording serves all three, because the clip is generated once and reused: `kuku_flow/audio/tochka_FROSYA_APPROVED.mp3`.
