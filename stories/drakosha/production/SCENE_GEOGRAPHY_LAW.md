# The geography law — every character owns a wall

Written 2026-08-18 from the author's note on scene 6. This is the third law, and it belongs beside the two in `STAGING_MATRIX_DOCTRINE.md` rather than inside them, because it governs the SET rather than the people.

---

## The defect

Scene 6 was shot as a run of close-ups with the background written as *"the hall running away, soft and out of focus."* Every shot was individually correct and the scene had no geography at all. Nobody could say where anyone was standing, because nothing in the prompts said.

The author's verdict:

> The whole bit was missing proper directions for where they're standing and what we should be seeing in the background. We should have set it up very simply.

"Soft and out of focus" is not a background. It is a refusal to choose one, and it hands the model the same blank cell that the broom and the frozen face came out of — with the same result, which is that the model fills it differently in every shot and the room stops being a room.

---

## THE LAW

**Every character in a scene is assigned a wall before any shot is written, and every shot states which wall is behind each person in frame.**

A wall is a named, plated thing — not an adjective. There are four in the family's hall and they are the whole vocabulary:

| name | plate | what is actually visible |
|---|---|---|
| **the hatch wall** | `@ROOM_FRONT_HATCH` | the small dark iron cleanout hatch low in the boulder-block wall |
| **the ramp side** | `@ROOM_FRONT` | the rope railing and the floor opening, boulder-block above |
| **the back wall** | `@ROOM_BACK` | the kitchen end — stove, shelf of thimble cups, and the niche panel with its iron ring |
| **the table end** | `@ROOM_FRONT` | the plank-on-spools table, matchbox beds along the left |

If a shot is tight enough that no wall reads, say so explicitly — *"this framing shows no wall"* — rather than leaving the cell empty. An admitted blank is a decision; an unwritten one is a defect waiting.

---

## THE STANDING ORDER FOR THE GIFT SCENES (author, 2026-08-18)

This is the fixed geography of scenes 6 and 7 and it is not to be re-derived per shot.

- **БАБУШКА-ЯГА stands with her back to the HATCH WALL.** She is the fixed point of the scene; both children come to her and she goes nowhere. Everything shot toward her carries the hatch wall behind.
- **ФРОСЯ and ВАСЯ stand with their backs to the RAMP.** Their backs are to the wall opposite Бабушка-Яга, so anything shot toward the children shows some rope railing and boulder-block behind them.
- **МАМА stands to БАБУШКА-ЯГА'S RIGHT, at a distance.** Far enough that she is out of every shot framed on Бабушка-Яга — which is why she is never seen in them and does not need to be. When the camera turns to Бабушка-Яга's right, Мама is simply there.
- **МАМА'S BACKGROUND IS THE BACK WALL.** She is the only character who carries `@ROOM_BACK`, and this is what makes her turn work: **when she turns away at the end of scene 6 she is turning toward the niche the chest comes out of.** The turn is not a gesture, it is a look at the thing she is about to fetch, and it only reads if the niche is behind her in the first place.
- **PROFILE AND TIGHT CLOSE-UPS may use the front plate for anyone**, because at that framing there is little or no wall in shot. State that this is what is happening.

The whole geography is one sentence: **Бабушка-Яга against the hatch, the children against the ramp, Мама off to her right against the back wall with the niche.**

---

## Why this is not just neatness

The turn at the end of scene 6 is the cut into scene 7. Shot against an unnamed blur it is a woman turning her head; shot against the back wall it is a woman looking at the niche she is about to open. Same performance, same frame, and only one of them is a story beat.

Geography is what lets a cut mean something. Without it every shot is an island and the audience has to be told what to feel instead of shown where they are.

---

## Enforcement

`assertBackgroundsAssigned` in `studio/src/Drakosha_SeedanceDryRun.res` requires every job's BACKGROUNDS block to name every character in the cast and to place each of them against one of the named walls above, or to state explicitly that the framing shows no wall. A background written only as "soft and out of focus" fails.


---

## ADDENDUM — A TOP-DOWN SHOT MUST SAY WHAT SURFACE IT IS (2026-08-18, scene 7)

The author, on the assembled scene:

> Kids are supposed to be doing this whole thing on the floor, but somehow the floor becomes some kind of weird table.

s7jobC and s7jobD both say "STRAIGHT DOWN ONTO THE PLANK FLOOR". Both came back reading as a table or a ledge, because **a top-down view of planks is identical whether those planks are a floor or a tabletop.** The word "floor" in the prompt is not a picture; nothing inside the frame said which it was.

**The rule: a top-down or detail shot must contain at least one object that identifies the surface it is looking at.** A knee, a foot, the edge of the play mat, the chest standing on it, the hem of a skirt pooling on it. Something that only makes sense at floor level and belongs to the geography established in the wide.

This is the same defect as the unnamed background, one level down. A wall was named and the shot still floated, because the shots that lost the room were the ones with no wall in them at all — and I told those shots what they were looking at instead of showing them.

Without it a detail shot is a texture, and a texture belongs nowhere.


---

## ADDENDUM 2 — THE PLATE IS THE AUTHORITY, NOT THIS DOCUMENT (2026-08-19)

I labelled a room map from the table above instead of from the approved plate, and put the niche and the chest on the left wall. The left wall is the **matchbox beds**, the arched cleanout door and the tyre cradle. The author:

> The niche and the chest — you're supposed to have the matchstick beds there. You should not be making mistakes like that. You have to look at these images.

**THE RULE: before any wall, prop or position is named in a map, a board, a creative or a prompt, open the approved plate and look at it.** The plate is `ep1prod/scene1/references/SET-HOME-ROOM-01_author_master_v4_hatch_cradle-clear.png`, plus the shot footage for anything the plate does not show. Where this document and the plate disagree, **the plate wins and this document gets corrected.**

### What the plate actually shows

| where | what is there |
|---|---|
| **left wall** | matchbox beds in a row (crates with pillows and plaid), the small arched cleanout door with its glowing seam, the tyre-and-rope cradle on its sled |
| **upstage centre** | the riveted iron stove FRONT, warm light leaking round its edges, hanging lantern, the plank-on-spools table in front of it — **and this is where the birthday cake sits, candles along the edge** |
| **right / kitchen end** | shelf of thimble cups and canisters, the small shelf with a bowl, the red stool, the rope railing and the ramp down to the underfloor road — and the niche with the chest, a low block in the boulder wall |
| **floor** | wide planks, macaron cushions, the round floor disc |

The niche as actually shot in scene 7 is a **low** hinged block in a boulder-block wall that swings out; the chest is pulled out onto the floor at the children's height. It is not a tall alcove.

This addendum exists because the failure was not a guess, it was a citation — I trusted a table I had written earlier over the picture in front of me. A table describing a picture is a summary, and summaries lose things.
