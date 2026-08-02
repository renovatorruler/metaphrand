# EP1 «Я САМ» — SCENE 1 shot list (v1, draft for markup)

**СЦЕНА 1 — ПОДПОЛ, ПОДПОЛЬНАЯ ДОРОГА — УТРО**
Style: **Low Poly**. Characters: `charsheets/vasya_lowpoly.png`, `charsheets/frosya_lowpoly_v2.png`.
Location anchor: `ep1prod/plates/s1_underfloor_wide.png` (generate FIRST, attach to every shot).
Prop: `ep1prod/plates/prop_sock.png` (lock the sock like a character — its stripes keep changing).

---

## SCREEN DIRECTION — THE RULE FOR THIS SCENE

- **HOME / the destination is SCREEN LEFT.** They always haul the sock **right → left**.
  The sock therefore always **trails behind them to the RIGHT**.
- **The GIANTS are ABOVE.** All threat comes from overhead; both look UP, never sideways, for danger.
- **Camera stays on one side of the action** (180° rule) so cuts don't flip them.
- They are **never carrying the sock toward camera** and never face camera in the hauling shots —
  they face the direction of travel.
- Фрося leads, slightly ahead and screen-left of Вася.

## SCENE ARC (from the screenplay)

Hauling → Вася's question → Фрося's answer → **БУМ** overhead → «Замри!» → steps pass, yawn →
Вася's whisper → Фрося's proud answer → sock posted through the gap → they run home past the beam
carrying the hidden carving **«КОТ — ДРУГ»** (in frame, never remarked on).

---

## SHOTS

| # | Shot | Camera | In frame | Audio / line |
|---|---|---|---|---|
| **1** | **ESTABLISH.** The empty under-floor road: colossal joists overhead, dust, one warm shaft of light from a floorboard gap, giant button and thread spool on the ground. Nobody yet. | Wide, low, static | plate only | Clock ticking far above; floorboards creak; rustle |
| **2** | They enter from the RIGHT, hauling the huge striped sock behind them, straining, moving LEFT. | Wide, low ¾, slow pan left | Ф + В + sock + plate | ФРОСЯ *(commanding whisper)*: «Тяни. Тяни-тяни-тяни. Носок — на место, пока великаны не проснулись.» |
| **3** | Closer on the two mid-haul — bodies angled left, arms back on the cuff, feet skidding, dust puffing. | Medium ¾, tracking left | Ф + В + sock | *(effort sounds)* |
| **4** | Вася, puffing, turns his head to her without stopping. | Medium close on Вася | В (Ф's shoulder in frame) | ВАСЯ *(puffing)*: «А почему… уф… почему они вечно теряют носки? У них же всего две ноги!» |
| **5** | Фрося answers matter-of-factly, still hauling, not even looking back. | Medium close on Фрося | Ф | ФРОСЯ: «Потому что они люди. Люди теряют. А мы — домовята. Мы находим и кладём на место. Так устроен дом.» |
| **6** | **БУМ.** Looking UP: the dark shadow of a giant foot crosses the boards overhead; dust pours down through the cracks. No characters. | Low angle up at ceiling | plate (ceiling) | **БУМ. БУМ.** Heavy footfalls |
| **7** | Both snap their heads up, dust falling on them, mid-step. | Medium wide, low | Ф + В + sock | *(dust hiss)* |
| **8** | **«ЗАМРИ!»** Фрося's hand shoots up; both freeze rigid mid-motion. Only dust moves. | Medium ¾ | Ф + В + sock | ФРОСЯ *(sharp whisper)*: «Замри!» |
| **9** | Held stillness. Footsteps pass overhead and fade. A long human yawn from far above, like a distant horn. | Wide, static, held | Ф + В + sock + plate | Steps recede; **yawn** |
| **10** | Вася whispers without moving a muscle, eyes sideways. | Close on Вася | В | ВАСЯ *(whisper, frozen)*: «А если он нас увидит?» |
| **11** | Фрося, still frozen but proud, whispers back. | Close on Фрося | Ф | ФРОСЯ *(proud whisper)*: «Никто нас ни разу толком не видел. Ни од-но-го домовёнка. Нас не видят — нас слышат в стенах. И говорят спасибо за порядок.» |
| **12** | They shove the sock up into a gap at screen LEFT; it disappears. Soft plop. | Medium wide, low | Ф + В + sock + plate | *(soft plop — the sock lands in the drawer)* |
| **13** | They run home LEFT past the old stove beam. On the beam, dark old carving **«КОТ — ДРУГ»** — in frame, neither looks at it. | Wide tracking left | Ф + В + beam | *(running feet; stove crackle ahead)* |

**Note on shot 13:** the carving is the only place Cyrillic appears in-frame. Per the letterless
law, generate the beam **without text** and composite «КОТ — ДРУГ» afterwards.

---

## DECIDED (2026-07-30)

- **No drawer shot.** The sock going in stays OFF-SCREEN — we only hear the soft plop.
- **Shot 6 folded into shot 7** — the giant's shadow and dust fall in the same shot as the
  children snapping their heads up. No separate ceiling-only plate.
- **Test build = the minimum spine only:** shots **2, 4, 5, 7, 8, 9** (six shots).
  The rest stay written but ungenerated until the script settles.

### THE SET IS LATERAL, NOT A CORRIDOR
The plate is deliberately **side-on** — shallow depth, floor edge to edge, action axis running
left-right ACROSS the frame. A depth-receding corridor plate was rejected because it invites
movement INTO frame and fights the right→left haul. Keep every Scene-1 camera perpendicular
to the passage. Light falls in **pools at intervals**, so travelling characters pass through
light and shadow — use that.

## MOTION PLAN (after stills are approved)

- Animate via Kling `start_image` from the approved still: **2, 3, 6, 7, 8, 12, 13**
- Hold as near-stills with only dust/light moving: **1, 9**
- Dialogue shots **4, 5, 10, 11** — subtle motion only; lip sync is approximate, so favour
  wider framing or reaction cutting.
- Dialogue audio already exists in the cast voices (`s1_l1`…`s1_l6`, ElevenLabs eleven_v3).
