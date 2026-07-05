# अमल — Context Folders (the card catalog)

**What this is:** the labeled slices of AMAL's canon, so each editing pass can be handed
*only* the folder it needs — not the whole bible. Nothing here is a copy; each folder points
at where its content really lives. The fine splitting (one character's voice, the one ritual a
scene triggers) happens at load time, not here.

---

### secrets — the held cards, must never leak
- **holds:** Sugna killed Leela (the season reveal); the weapon is amal; Sugna *is* the woman in
  the train flashback; Ratan's own signatures are complicit. The why and the mother's hand stay buried.
- **source:** `PASS_CONTEXT.md` §HELD CARDS · `BACKSTORY.md` (the train, the leak rule)
- **handed to:** the **backstory** pass — and nobody else. This is the one folder that must stay
  *out* of the language passes.

### world — who's who and what's true
- **holds:** the belt, the patta economy, the cast, the timeline, the ending.
- **source:** `BIBLE.md` · `PASS_CONTEXT.md` §CANON · `PLOT.md` · `SEASON_ARC.md` · `FINALE.md`
- **handed to:** the **consistency** pass.

### culture — the ritual rules, one at a time
- **holds:** cremation, birth, mundan, wedding, matchmaking, the amal/kasumba ceremony.
- **source:** `culture/GATE.md` (the router) → opens only the one doc a scene actually triggers.
- **handed to:** the **cultural** pass (only).

### voice — how each person talks
- **holds:** a card per character (Ratan terse and sealed, Sugna the stone, Bhanwar the mirror who
  talks more under pressure, Charan the only earned eloquence…).
- **source:** `VOICE_CARDS.md`, keyed `### Name — key`; the loader hands over only the characters
  present in the scene.
- **handed to:** the **voice** and **dialogue-realism** passes.

### texture — the lived feel of Malwa
- **holds:** the black-cotton soil, the obscene casual cash, the doda-amlis, Malwi in the mouths,
  the two-hundred-year leash.
- **source:** `MALWA.md` · `BACKSTORY.md` §"Malwa, woven in"
- **handed to:** the **shrink-wrap** pass.

### heart — the bonds underneath (thin for now)
- **holds:** Ratan and Kanta gone silent; Sugna and Leela; Govind and the boy Ratan was.
- **source:** `BACKSTORY.md` (the character icebergs). No dedicated file yet — give it one if the
  heart pass ever needs more than this.
- **handed to:** the **heart** and **human-reaction** passes.

---

### Folders nobody gets
The craft passes work on the words alone, so they get **no** story folder — that's the whole point.
**show-not-tell · clear-pane · concreteness · naturalness · editorial** run on the scene text and
nothing else. **drama** gets the scene's own brief (want / wall / turn), not a canon folder.
