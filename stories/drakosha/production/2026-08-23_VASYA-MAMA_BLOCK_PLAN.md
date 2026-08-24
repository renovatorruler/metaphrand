# The Вася-Мама block — shot plan (SP110–SP122 / SH120–SH136)

The shooting script breaks this into seventeen shots. This plan does it in ten, one of which costs nothing and one of which is a reusable card that pays for itself the next time Вася transforms into anything. Nothing in the comedy is cut; what is cut is coverage — the separate insert of the apron hem, the second angle on Мама lifting the babies, the four separate tile shots, and above all the two-Мама wide.

## What already exists, and what it changes

Every line in this block is recorded and sitting in `kuku_flow/audio/`: line60 (5.28s), line61 (2.48s), line62 (4.96s), line63 (5.76s), line64 (5.76s), line65 (1.36s), line66 (1.60s). Twenty-seven seconds of dialogue, and the two long Вася-Мама lines are what force shot 7 to be long. The only new recording this block needs is Фрося's laugh at the very end.

**The Вася-Мама design is already drawn** — `REVEAL-MAMA_author.png`. Мама's kerchief, braid and apron, Вася's enormous shaggy eyebrows and gap-toothed grin, standing in the transformation space with МАМА in gold light at his feet. That was the single biggest risk in this block and it is not a risk, because the author drew the answer on 19 August.

The transformation machinery was designed the same day and is written up in `2026-08-19_SCENE8_TRANSFORMATION_SYSTEM.md`: `C-VAS-TRANSFORM-PRE_author.png` (Вася, arms raised, serious) → `C-VAS-TRANSFORM-CHARGED_author.png` → dissolve → the reveal card. Generated once, it serves кот, оса, мама and every target after them.

## The plan

| # | shot | sec | cr | what happens |
|---|------|-----|----|--------------|
| 1 | «Мне слово!» | 10 | 25 | Overhead on the work area, the framing that already worked for Руся. Вася sets the glass aside and digs in the pouch — *«А я, я тоже хочу. Мне слово лёгкое.»* Фрося, across from him, nods at the chips without touching them — *«Ну собери сам, ты же читать будешь.»* Ends with his hand going into the pile. |
| 2 | МАМА assembled and read | 8 | 20 | Down onto the floor between him and camera. The last chip lands, his finger traces the four — *«Ма-ма. Мама! Вжух!»*, the Вжух said with no confidence at all. **The letters must be legible — see the ask below.** |
| 3 | The transformation | 5 | 13 | PRE → CHARGED → white, in the transformation space. **Generated once and reused forever.** |
| 4 | The reveal card | 1 | 0 | Hard cut to `REVEAL-MAMA_author.png`, held one second. A still. Free. |
| 5 | He looks at his hands | 5 | 13 | Back in the room, standing where Вася stood. He raises both hands, turns them over, touches the apron he is suddenly wearing. Not a word. |
| 6 | Мама touches her eyebrows | 4 | 10 | Close on the real Мама at the table. She stares off, her hand drifts up, checks her own eyebrows, comes down. Silent. **This is what tells the audience there are two of them, instead of a shot with two of them in it.** |
| 7 | The babies notice | 4 | 10 | Starts on the last frame of the shot already in the cut — both babies close on the rug. They look off toward him, squeal, and crawl out of frame. |
| 8 | Climbing and complaining | 13 | 33 | Camera low in front of Вася-Мама, knees to head. Руся and Муся come in from both sides and grab the apron; Муся starts chewing the hem. He lifts both hands clear so as not to squash them — *«Ай, Фрося, они меня едят! Почему они меня едят?»* He tries to prise Руся off with one finger and she grips harder — *«Я не мама, я Вася. Снимите их с меня.»* |
| 9 | Мама takes them off | 7 | 18 | Camera stays on him. **Only Мама's arms come into frame**, lifting Руся, then Мусю. Her line arrives from off-screen while we hold on his face — *«Брови-то твои, Вася.»* He deflates. |
| 10 | The angry ВЖУХ | 5 | 13 | Close on him, offended — *«Вжух!»* White wipe, and the boy is back, pouch on his belt. |
| 11 | Фрося on the floor | 4 | 10 | She folds up laughing. Needs a laugh take. |

Sixty-six seconds, ten generations, **165 credits ≈ $7.10**.

## The three simplifications, and why each is safe

**The two Мамы are never in the same frame.** This is the author's call and it is the right one — two identical characters in one shot is the single thing a video model is worst at, and the joke does not need it. Shot 6 (the real Мама checking her own eyebrows) says *there are two of them* more cheaply and more funnily than a wide would. The one place they must physically interact is shot 9, and that is solved by showing only her arms.

**Мама's punchline plays off-screen, on his face.** *«Брови-то твои, Вася»* lands harder on his reaction than on her delivery, and it means shot 9 never has to hold her face and his in one frame.

**Four tile shots become one.** The script asks for four separate overhead inserts as he lays М, А, М, А. One shot where the last chip lands and his finger traces all four does the same work, and the sounding-out is carried by his voice, which is where the literacy actually lives.

## What is needed before shot 2 can run

**Вася's chips.** Only Фрося's alphabet exists on disk (`alphabet/frosya/assets/` — eight letters in six states). There is no chip artwork. Shot 2 is the beat where a five-year-old watching has to read МАМА, so the letters cannot be left to the model — that was settled when the tile top-down was thrown out. Two options: either the author draws chip PNGs for `М` and `А` (regular and lit, per the composable-alphabet contract) and the pipeline composites and lights them on his voice with the rig that already exists, or she makes a single start frame with the four chips laid out legibly and the shot is generated from it. The second is faster; the first is reusable for every word Вася ever reads.

**A room plate of Вася-Мама.** The reveal card is in the transformation space. Shots 5, 8, 9 and 10 need him standing in the room. One plate of Вася-Мама in the main room, at Мама's height, would anchor all four.

**Фрося's laugh.** Not in `LINE_INDEX.json`. One take, ElevenLabs, the same voice as the rest.

## Open question on line62

*«Ма-ма. Мама! Вжух!»* is recorded, but the author wants that Вжух uncertain — the first time he tries it, he does not know it will work. Worth listening to the existing take before shot 2 is built; if it is confident, it needs one more pass.

## Still outstanding from the block before this one

SH119 — Яга's approving hum, and Фрося tucking the pencil behind her ear. Small, and it belongs between the poppy and *«Мне слово!»*.
