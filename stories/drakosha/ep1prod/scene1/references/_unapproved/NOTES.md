# Quarantined — never approved, despite the filename

Both files below carry `_approved_plate` in their names and were never approved by the author. She caught this on 2026-08-13: "There is a photograph of Baba Yaga flying through the sky and another one going through the ledge on wheels. These are not approved. I don't know why they're in our references."

Nothing is deleted here. Paid output is never deleted or overwritten. These are moved out of the reference root only so that no session can bind them as canon.

## The two files

- `SET-ROOF-01_approved_plate.jpg` — a photographic roof and sky with a small flying mortar composited into it. Real shingles, real chimney, real sky.
- `SET-STOVE-HATCH-01_approved_plate.jpg` — a dark photographic passage with a figure in a wheeled mortar.

Neither is in the show's register. «Фрося и Вася» is stylised low-poly 3D, as the whole character packet v2 establishes.

## How to tell an approved asset from one of these

Every genuinely approved asset in the reference root has a `.receipt.json` beside it: `SET-HOME-ROOM-01`, `R-EP1-TOP-01`, `BATCH_A_approvals`, `BATCH_B_approvals`. These two have no receipt of any kind. The filename was the only thing claiming approval, and a filename is not a receipt.

A second proof they were placeholders: `2026-08-06_REFERENCE_GAP_AUDIT.md` lists `SET-STOVE-HATCH-01` as item 31 on the MISSING list — the audit says we do not have it, while a file claiming to be it sat in the folder.

## What this breaks, deliberately

`Drakosha_SeedanceBatch.res` binds the `Roof` prop token to `SET-ROOF-01_approved_plate.jpg`, and jobs 15 and 16 both carry `Roof`. With the file moved, those two jobs now fail the reference-existence check instead of quietly feeding a photograph into a stylised show. That failure is correct and should stay until a real roof plate exists.

`SET-STOVE-HATCH-01` was bound by nothing — there is no Hatch token in the registry — so moving it changes no job.

## The open decision behind the gap

Both files were standing in for the human world: the outside of the human house, and the sooty route Баба-Яга travels between the stove and the home. What that world looks like is an author decision that has not been made. Until it is, no roof or passage reference exists.

---

## Added 2026-08-13: `SET-YAGA-DOOR-01_approved_states.png`

Author: "Why do we need the wall, the door plate? I never approved the door plate."

No receipt names it. `BATCH_A` approves the transformation sheets, `BATCH_B` approves the tin and the pencil, and the room master carries its own receipt. This file has none — the same false `_approved_` filename as the two photographs above.

It is also redundant and actively harmful. The approved room master ALREADY contains the little arched iron door, low in the left wall. The plate disagrees with it: the plate sets the door in small red brick with pale mortar and gives it a rusty finish, while the room master sets it in giant sandstone boulder-brick with a green-patinated door and a warm glowing rim. Jobs 17, 18 and 19 bound both images at once, so the two references argued about the same door.

The one thing the plate offered that the room master does not is the OPEN, soot-blown state. That is a real gap, and the way to fill it is a state plate derived from the room master's own door — not a separately invented door.

`@DOOR` is now a Described prop: it binds no image and its wall comes from `@ROOM`.
