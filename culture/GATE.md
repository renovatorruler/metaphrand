# CULTURE GATE — read the right ritual doc BEFORE writing or rendering

Hindu ritual scenes carry hard rules; getting them wrong **breaks the scene**. Real violations shipped in AMAL
before this existed: *ancestors' "bones" buried in the land* (Hindus cremate), *"burn the body"* (it's
दाह-संस्कार), and *women standing at the cremation ghat* (women never go — they mourn at home). All from missing
ritual grounding.

## The rule (binding)
**Before you write or render any scene involving one of the ceremonies below, you MUST read the matching
`culture/` doc first.** Don't read them all — read **only** what the scene triggers. This keeps it cheap:
the cost is one small doc, only when a ceremony is actually present.

| If the scene touches… | READ |
|---|---|
| death · funeral · mourning · cremation · the ghat/श्मशान · 13th-day/तेरहवीं · asthi/अस्थि · a corpse/लाश | **culture/cremation.md** |
| a wedding · baraat · phere/फेरे · engagement/सगाई · vidaai · sindoor/मंगलसूत्र | **culture/wedding.md** |
| arranging a marriage · rishta/रिश्ता · kundli/कुंडली · dowry/दहेज · the photo/proposal · "seeing" the girl | **culture/matchmaking.md** |
| a birth · naming/नामकरण · छठी · sutak/सूतक | **culture/birth.md** |
| a mundan/मुंडन · tonsure · a child's first haircut | **culture/mundan.md** |
| the ceremonial opium offering · कसूम्बा/kasumba · अमल · मनुहार · drinking opium-water from the host's palm | **culture/amal_kasumba.md** |

## The mechanical check (token-efficient)
Run the scanner on any script before writing/rendering it:

```
python culture/cultural_gate.py stories/amal/EP2_PAGES_HI.md
```

It scans each scene for ceremony triggers and prints exactly **which doc(s) each scene needs** — so you read a
cultural doc only when a scene actually requires it, and you can't forget. Trigger keywords live in
`cultural_gate.py`. (It over-flags by design — triage, don't blindly trust a non-flag on a subtle scene.)

## Standing law
This gate is part of the craft pipeline alongside clear-pane / naturalness / the drama gate: **a Hindu ritual
scene is not "done" until its `culture/` doc has been read and checked against.** New ceremony, new doc — add
it here and to the scanner.
