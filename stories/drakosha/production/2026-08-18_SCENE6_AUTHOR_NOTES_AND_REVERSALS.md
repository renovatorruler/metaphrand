# Scene 6 — the author's read, and what it changes

Scene 6 is **ACCEPTED AS SHOT, 2026-08-18.** Nothing in this document is a reason to regenerate any part of it. Everything here governs scene 7 onward.

---

## What worked, and is therefore now the standard

> The facial expressions and character direction are amazing, especially for grandma, Фрося and Вася. Excellent shots, excellent facial expressions, timing and everything else. These close-ups work really well. You could tell what's going on and it creates a great scene.

Two things earned that and both stay:

**Close-ups carry this show.** A run of tight singles with hard cuts reads better than coverage, costs less, and is the only framing at which the character sheets hold. Keep building scenes out of them.

**Faces are directed as muscles, not moods.** The REACTIONS block naming what the mouth and brows DO, per character, per shot, is what produced the performances she is praising. It is a gate now and it stays one.

---

## THE BROOM — I HAD THIS BACKWARDS

This is a reversal of a call I made on 2026-08-18 and acted on twice.

I treated the broom in Бабушка-Яга's hand as a defect, stripped it from her reference line, and wrote HANDS blocks that put her hands empty and folded. **That was wrong, and it cost a 32.5-credit reshoot to introduce a mistake.**

The author, looking at the actual footage:

> The broom was just standing behind her, somehow, like, just hanging in the middle of the room because it didn't even have a wall to lean on. But if she actually had the broom in her hand, I think it would have worked. Because Grandma uses this as a staff, and I think it's a lot more characterful when she has it there. It reminds us that she's the forest witch.

**The real defect was a broom standing in mid-air with nothing to lean on** — a floating prop, which is a geography failure, not a prop failure. I diagnosed the prop.

### The standing order

**БАБУШКА-ЯГА HAS HER BROOM AND LEANS ON IT.** It is a staff. She is the forest witch and the broom is what says so without a line of dialogue. From scene 7 onward, the HANDS block reads something like:

> Бабушка-Яга: her right hand is closed around the shaft of her broom, the head of it planted on the floorboards, taking a little of her weight — she leans on it the way an old woman leans on a stick. Her left hand is folded at her waist.

The dinner shot where she stood leaning on it was, in the author's words, "a lot more in character." **If the earlier scenes were ever reshot, the better call would be for her to have the broom throughout.** They are not being reshot; this applies going forward.

### What survives from the wrong call

The machinery is right even though the content was wrong, and it stays:

- `assertHandsWritten` still requires a positive HANDS statement per character. That gate is what makes "leaning on her broom" possible to state — the failure it prevents is the blank cell, not the broom.
- `assertTagLinesAreIdentityOnly` still keeps held props out of the reference line. **A prop belongs in the choreography where it can change shot to shot, not welded into her identity where it appears at dinner with both her hands full.** She leans on the broom in most shots and puts it down to hand over a pencil; only a HANDS block can say that.

So: the broom comes back, in her hand, written into HANDS every time — never back into the tag line.

---

## THE PENCIL — right for the gift, too big for use

> The pencil is huge. I still think it works, 'cause this is the gift scene and we could really see this big present, but I don't think it will be fitting behind her ear. I don't think anybody will notice if we'll make it slightly smaller in the scenes where she's actually placing it behind the ear and using it.

**Scale is per scene, not per show.** The gift scene wants the pencil читаемо large — it is the present, and the audience has to see it arrive. Every later scene wants it smaller: it has to sit behind her ear, be written with one-handed, and stop being the subject.

`propScale` for `Pencil` therefore needs two readings and the job has to pick one. Nobody will notice the change; everybody would notice a beam behind a child's ear.

---

## МАМА — the performance problem is a character problem

> Mom somehow always has a bit of a flat performance. I'm not sure how to properly resolve that. Maybe we need to understand better how she's supposed to be acting.

She is right that this is not a settings problem, and the voice audition is only half of it. The other half is that **I have been directing Мама as the person who objects**, and the staging sheet says so in as many words: flat, level, unimpressed. Played straight, that is a wet blanket, and a wet blanket is boring no matter who reads the line.

Мама is not the obstacle in this scene. She is the one who out-thinks the room. Бабушка-Яга gives the flashy gift; Мама lets her, waits, names the one thing that makes the gift useless, and then produces the thing that fixes it. **She wins the scene and she knows she is going to win it from the first word.**

That is a person enjoying herself, not a person disapproving. It is also why the author's note on the read was *"she needs to sound clever"* — the cleverness is the character, not a colour added to the line.

Working card, to be used in every Мама direction from here:

> **МАМА** — she grew up with magic and it does not impress her; she is the only adult in the house who thinks two moves ahead. She never raises her voice because she never needs to. Warm with her children and dry with her mother. When she concedes a point she means it, and she concedes it because she is about to take the argument anyway. Her authority is domestic and absolute and she enjoys using it.

Directions built on that card read *warm → practical → sly → quiet triumph*, which is exactly the shape the author approved for the audition line. Directions built on "flat and unimpressed" produced the takes she rejected.

---

## GEOGRAPHY

The largest note, and it has its own document: `SCENE_GEOGRAPHY_LAW.md`. In one line — **Бабушка-Яга against the hatch wall, the children against the ramp, Мама off to her right against the back wall with the niche** — and every shot must say which wall is behind whom.


---

## THE PENCIL COMES BACK SHARPENED AT BOTH ENDS (2026-08-18, scene 7)

Confirmed in s7jobA and again in s7jobB, so it is systematic rather than one bad roll. The reference `D-FRO-PENCIL-01_approved.png` is sharpened at ONE end and blunt at the other; the model puts a dark graphite tip on both.

**The reference was bound and described in both jobs** — image reference, reference line, scale line, and named again in the positive constraints. It drifted anyway. Two things follow:

1. **A bound reference is a strong pull, not a guarantee.** It holds best when the thing is what the camera is looking at, and it is weakest on a held prop that no shot is about. In s7jobA the pencil is a small object clutched against a chest in a wide; in s7jobB it lies on the lid in a straight-down close-up — and it drifted in both, which is the point.
2. **A reference line must state what is NOT there, not only what is.** "Sharpened to a dark graphite point" describes one end and says nothing about the other, so the model symmetrised it. The registry line now reads: one end only sharpened, the other end blunt, flat and bare, never sharpened at both ends, no dark tip at the blunt end.

**Scene 7 is NOT being regenerated for this.** The author's call: *"I don't want to regenerate anything. I want to see if I can live with this."* The corrected line applies from scene 8 on.

Also noted and not fixed: in s7jobB Фрося's hand sits beside the pencil rather than keeping two fingers on it as written. The magic still visibly takes her pencil and his hand together, so the beat survives.


---

## МАМА, THIRD TIME — HER REGISTER DEPENDS ON WHO SHE IS TALKING TO (2026-08-18, scene 7)

> Mom looks very angry and abrupt in the whole scene.

This is the third time Мама has come back wrong, and I have now misdiagnosed it twice. First I thought it was the voice; then I thought it was the performance tags. It is neither. **It is that I wrote her the same way in two scenes that require opposite registers.**

In scene 6 she is answering HER MOTHER. Dry, level, unimpressed, conceding nothing — correct, and it is what the staging sheet says.

In scene 7 she is with HER CHILDREN, giving them the thing that makes their gifts usable. I carried the scene-6 direction straight across: "brows low, mouth closed and level, she does not hurry, nothing sour in it." Performed by an actor that reads as stern; performed by this model it reads as **angry**.

**The rule: Мама's register is set by her addressee, and it must be re-decided every scene.**

- **To Бабушка-Яга** — dry, flat, level. She is not impressed by magic and never has been.
- **To her children** — warm, patient, and firm underneath. She is teaching, not ruling. Her mouth is soft at rest; the firmness lives in her eyes and in the fact that she does not repeat herself.
- **To Папа** — not yet established.

The character card stands and this refines it: she never raises her voice because she never needs to, and *not needing to* looks like warmth with children and dryness with her mother. Written as one flat setting for both, it becomes anger.
