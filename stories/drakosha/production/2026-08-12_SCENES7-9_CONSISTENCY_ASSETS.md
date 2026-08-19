# Scenes 7–9 (SP080–SP136) — every object that needs a consistency asset

The segment: мама opens the hidden niche and binds both gifts to the letter chest; the eight letters are issued; Вася gets his pouch; Фрося makes СОК, САЛАТ, МАК; Вася turns into мама; Фрося discovers three letters are missing from МАШИНА; she makes the САМОКАТ and rides for the road. Roughly two minutes.

Three asset classes:
**ELEMENT** — a named, reusable image bound wherever the name appears (characters, props, sets, wardrobe). This is what our registry already emulates.
**TYPE** — exact typography, composited, never generated.

SOUL ID IS RULED OUT (author, 2026-08-13): it only holds for photorealistic faces, not stylized/low-poly characters. Do not propose it again for this show. Character consistency comes from reference images + the registry.

## Characters

| # | Object | Script | Class | Have? |
|---|---|---|---|---|
| 1 | Фрося (pre-pencil, then pencil behind ear) | throughout | ELEMENT | packet_v2/page-05 ✅ — **but two states**: the pencil goes behind her ear at SP109 and stays. Needs a second element. |
| 2 | Вася | throughout | ELEMENT | packet_v2/page-04 ✅ — **state change**: pouch tied to belt from SP091 onward. Needs "with pouch" element. |
| 3 | Мама | SP081–108 | ELEMENT | packet_v2/page-07 ✅ |
| 4 | Папа | SP096 (tea, background) | ELEMENT | packet_v2/page-08 ✅ |
| 5 | Бабушка-Яга, домовой form | SP094, 096, 109 | ELEMENT | packet_v2/page-09 ✅ |
| 6 | Руся + Муся | SP104 (Руся crawls to the salad alone) | ELEMENT | packet_v2/page-14 ✅ — **Руся needs a solo element**; he acts alone here and the pair sheet can't cast him singly. |
| 7 | Вася-мама | SP114–122 | ELEMENT | T-VAS-MAMA-01 ✅ (two-up sheet; needs the right-hand figure cut out) |

## Props — the letter system

| # | Object | Script | Class | Have? |
|---|---|---|---|---|
| 8 | Окованный сундук (iron-bound chest) | SP081, 085, 094 | ELEMENT | D-MAM-CHEST-01 ✅ — needs **open** and **closed** states |
| 9 | Деревянные фишки-буквы (letter tiles), generic | SP081, 096 | ELEMENT | ⬜ **missing** — we have ignition plates for КОТ only |
| 10 | The eight issued tiles: А О М С К Т Л Б | SP085–087 | TYPE | ⬜ **missing** — must be exact; Вася reads them aloud |
| 11 | Мешочек (pouch) tied to Вася's belt | SP091–092 | ELEMENT | ⬜ **missing as its own asset** (visible on his sheet only) |
| 12 | Волшебный карандаш | SP082–083, 097, 109 | ELEMENT | D-FRO-PENCIL-01 ✅ |
| 13 | Скрытая ниша (hidden niche in the wall) | SP081, 094 | ELEMENT | ⬜ **missing** — `SET-MOM-NICHE-01` has an ID, no image |
| 14 | Клочок бумаги (paper scrap she writes on) | SP097 ff. | ELEMENT | ⬜ **missing** |

## Props — the materializations

| # | Object | Script | Class | Have? |
|---|---|---|---|---|
| 15 | Напёрсток с соком | SP098–100 | ELEMENT | ⬜ missing |
| 16 | Плошка салата | SP102–104 | ELEMENT | ⬜ missing |
| 17 | Алый мак, cut, long stem | SP106–108 | ELEMENT | ⬜ missing |
| 18 | Самокат | SP132–136 | ELEMENT | ⬜ **missing — hero prop**, and it recurs in the chase |
| 19 | Words as they appear written: СОК, САЛАТ, МАК, МАМА, САМОКАТ, and the gapped МА□□□А | SP097–132 | TYPE | partial — tile/ignition plates exist for КОТ only |

## Sets

| # | Object | Script | Class | Have? |
|---|---|---|---|---|
| 20 | Main room, home | all | ELEMENT | SET-HOME-ROOM-01_author_master_FINAL ✅ |
| 21 | The tea table with three adults | SP096 | ELEMENT | covered by the room master |
| 22 | Покоробленная доска → road descent | SP136 | ELEMENT | in the room master ✅ |
| 23 | The magic mat (spell space) | every spell | ELEMENT | SET-MAGIC-MAT ✅ |
| 24 | Spell reveal space | every materialization | ELEMENT | REVEAL plates exist for creatures; ⬜ **none for objects** |

## What's actually missing — the build list

**Typography (free, composited):** the eight letter tiles as individual faces; the five spelled words; the gapped МА□□□А.

**Elements to create (≈9 images):** generic letter tiles, the pouch, the hidden niche, the paper scrap, the juice thimble, the salad bowl, the poppy, the САМОКАТ, and an object-reveal space to match the creature reveals.

**State variants of things we already have (≈4):** Фрося with pencil behind ear, Вася with pouch, the chest open, Руся alone.

## The position-lock technique worth adopting

The Elements guide describes making a **top-down schematic** of a scene into an asset and then locking positions against it in text. This segment needs it: the tiles on the floor, the pencil, the paper, the growing row of created objects, and three adults at the table all have to stay put across many shots. One schematic of the floor layout, referenced in every shot of the segment, would prevent the drift we had on the road.
