# EP9 punch list — parent's V22 review (2026-08-19)

Shot numbers = V22 burn-ins (= ep9_simple_shot_numbers.v3.json). RULE for this pass: no retime, no re-render until the parent finishes reviewing — every fix lands at source (screenplay, audio manifests, overrides keyed by stable beat ids, FX files) and one rebuild happens at the end on their go.

| # | note | fix | status |
|---|---|---|---|
| 1 | S20 nice scene: pan+zoom full frame → sage, room to breathe | camera move support in builder + retimer boost S03-B01 +4s | code in progress |
| 2 | "छड़ी की ताल" line incomprehensible (order 115) | rewritten with gust/झूला analogy (screenplay done), re-record via delta tool; picture S24 → PH05 (pulsing staff + chest intro) | audio pending |
| 3 | "मैं इसे खोल दूँगा" has no referent (order 127, S29) | NEW still: Kuku straining at the golden circle, circle inert | gen queued |
| 4 | S31 "नया अक्षर भारी होगा" unexplained; SHOW don't tell | wire ST_gate_scale.png (ghost ब filling the notch, sage tiny) — exists, unused | wire queued |
| 5 | S34 goat threat never established | S32 (Vesper's line) NEW still: napping cloud straining up, goat startled; S33 (Dadi's line) NEW still: goat safe on ground by Kalu, cloud tugging above | gen queued |
| 6 | S37 chest unexplained | S24→PH05 and S25→PH06 rewires establish chest + circle before Castor fiddles with it | wire queued |
| 7 | S42 five bracelets from nowhere | NEW still: the one circle splitting into five equal rings (beat S04-B05 is authored exactly so) | gen queued |
| 8 | S43 Dadi's stroke-anatomy narration is noise; just "यह ब है" + draw it on screen (order 148) | screenplay done; re-record short line; letter draws itself as VFX | audio pending |
| 9 | S45/S46 letter VFX shows a YELLOW BLOCK not ब | root cause: alpha bug in B08_b_reveal/B09_b_pulse + glossy off-style plate; rebuild both as stroke-order draw + bracelet pulse on a new papercraft forge plate | FX rebuild queued |
| 10 | S48 shows an instruction panel (panel_2.png); should just flow to S49 | rewire S05-B01 to NEW still: five bracelets glowing on five wrists (its authored story event) | gen queued |
| 11 | S53/S54 Kuku says "मैं अभी नहीं उड़ूँगा" over a FLYING pose | NEW still: BIG Kuku grounded, wings folded, firm stance | gen queued |

| 12 | S57 is another instruction panel (panel_6.png) | rewire S05-B06 → ST_big_reveal.png (five large forms discovering themselves — the beat's actual event under Furia's "हम सच में बड़े ड्रैगन बन गए हैं") | gen queued |
| 13 | S61 great shot, hold longer | retimer boost S06-B02 (funded by the S43 narration cut) | code queued |
| 14 | S66 Leda relief with no established danger | wire S06-B07-L1 → ST_leda_looks_down.png (aerial POV: goat + Kalu tiny and safe below); danger itself established by new S32/S33 stills | gen queued |
| 15 | S82 Kuku announces then fails in the same shot with no action between | S81 keeps his announce CU; S82 (S07-B04-L2, authored "कुकु विशाल ब का केवल एक सिरा अकेले उठाता है") → ST_kuku_carry_fail.png: him straining alone, letter barely lifted | gen queued |
| 16 | S100–107 climax is all talking heads over off-screen action | action coverage set: S100→ST_inside_letter, S101/102→ST_carry_formation, S104→ST_wind_path, S105→ST_align_gate, S107+S110→ST_letter_lock | gen queued |
| 17 | After S111/112 no celebration — cut straight to shrink + guilt | boost S08-B16 and wire ST_celebration.png (five wheeling around repaired gate, goat bounding to its mother); guilt beats then land as a quiet coda | gen queued |
| 18 | S122–126 डोरी demo: Dadi asks to be SHOWN, we show faces | S09-B06-L2→ST_dori_string.png (string tied gate→home across the sky); S09-B07/B08→ST_dori_test.png (Dadi pulling it taut, light running the length, Rishi answering) | gen queued |
| 19 | S131–133 (through S136) self-transformation payoff never shown | S10-B02→ST_leda_transform.png (her solo, mid-growth); S10-B03→ST_four_transform.png (four light-pillars at once) | gen queued |
| 20 | S139-area recap: Dadi lists ब words, letters should be ON SCREEN | local word-card VFX from the real Devanagari font (बच्चा/बड़ा/बादल/बकरी/बचाना, ब lit) composited over the recap beats S10-B01-L1..L4 | FX queued |
| 21 | Letter-of-the-day bug: show ब in a corner throughout | builder overlay: small translucent ब top-right on every shot (top-left stays the shot chip) | code queued |
| 22 | S140 good shot, linger + pan face-to-face then zoom out | second camera mode panAcross (zoom in leftmost → pan to rightmost → zoom out) + retimer boost S10-B06 | code queued |

Seconds ledger (retimer arbitrates at rebuild): freed ≈8s (S43 narration cut) minus ≈3.5s (longer 115) funds boosts S03-B01/S06-B02/S08-B16/S10-B06 — if floors exceed 720 the boosts shrink in this priority order: S20, S140, S61, celebration.

Rebuild sequence when the parent says go: delta tool (audio) → retimer (with S03-B01 boost; regenerates v4, shot numbers v4, SFX timeline) → animatic → guide proxy. Shot numbers will shift after the retime; the parent's V22 numbers stay mapped through this table's beat ids.
