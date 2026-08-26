/* EP1 scenes 2–4 Seedance batch — typed shot records and the prompt/args emitter.

   The invariant this module exists to enforce BY CONSTRUCTION: a character in a
   shot's cast always gets BOTH its @TAG line in the prompt AND its reference
   binding in the provider args, because both are derived from the same token
   through the same registry. An untagged-but-bound (or bound-but-untagged)
   character is unrepresentable.

   This module is pure (no IO): Drakosha_SceneFlow's seedance stage owns file
   checks, readiness, receipts, and the one sanctioned spawn point. */

type castToken = Frosya | Vasya | Mama | Papa | Babies | Rusya | Musya | YagaFlight | YagaDomovoy | VasyaCat | VasyaWasp | VasyaMama
/* THE FAMILY LIVES INSIDE THE FIREPLACE. The hall is not a room containing a
   fireplace — it is the bricked-up fireplace's own cavity, and the giant
   sandstone boulder-blocks are its masonry seen at their size. The camera is
   always inside it; these tokens say which END it is pointed at.

   FRONT is the fireplace's front. Per @ROOM_FRONT's own tagLine the riveted iron
   plate is the FAR WALL and the small cleanout hatch is low in the LEFT WALL, in
   the brick, with the matchbox beds running along that same left wall and the
   rope-railed floor opening over at the right. The plate and the hatch are two
   different walls — do not merge them, as an earlier version of this comment did.
   BACK is the brick rear of the fireplace, behind them.

   Named for the fireplace and not the furniture, because the armchairs, the
   stove and the table can all move and the fireplace cannot. The earlier name
   was "reverse", which has no fixed referent — the reverse of the front is the
   back and the reverse of the back is the front — so nothing written with that
   word could be checked. Do not reintroduce it. */
type propToken = FloorAfter | RoomFront | RoomFrontLow | RoomFrontHatch | RoomBack | SeatingScene5 | Carry | Roof | Door | Stupa | Pomelo | Broom | Top | Tin | Chest | Tiles | Pouch | Pencil | Scooter | Road | Tank | Thread | Cake | Juice | Salad | Poppy

type shotRecord = {
  jobId: string, // "job12"
  shots: string, // "SH024-027" — must match the shooting script
  cast: array<castToken>,
  props: array<propToken>,
  startImage: option<string>, // relative to rnd/keyframes; None = refs+text only
  durationSec: int, // 5 | 8 | 12 (validated by the stage)
  creative: string, // CINEDANCE choreography blocks only — no @tags, no cast descriptions
  /* WHICH RECORDINGS THIS JOB ACTUALLY CARRIES, when it carries only part of a
     script shot. Empty means "everything the script gives these SH codes", which
     is true of almost every job and is what the duration gate assumes.

     It stopped being true once lines started being cut. SH123 is «МА… МА. МАМА!
     ВЖУХ!» — but the reading is an overhead of the floor and the ВЖУХ has to be
     on his face, so they are two shots. Sized against the whole line the
     overhead needs 7s and three of them are dead. Naming the cut it carries
     lets the gate size it against 4.05s of «Ма-ма. Мама!» instead, and still
     refuse it if that does not fit. */
  carriesLines: array<string>,
}

/* ---- The registry: one source of truth per token ---- */

type castEntry = {
  tag: string, // "@MAMA"
  tagLine: string, // full ACTIVE REFERENCES line, ends with the identity lock
  refPath: string, // relative to ep1prod/scene1/references, or "KF:" + keyframes-relative
}

let castEntry = (t: castToken): castEntry =>
  switch t {
  | Frosya => {
      tag: "@FROSYA",
      tagLine: "@FROSYA — её зовут Фрося — the ELDEST of the family's FOUR children: orange flower in her hair, safety pin on her patchwork dress. 100% matches the reference.",
      refPath: "packet_v2/page-05.png", // official «Фрося — ДО карандаша» sheet (packet v2)
    }
  | Vasya => {
      tag: "@VASYA",
      tagLine: "@VASYA — его зовут Вася — the SECOND of the family's FOUR children, younger than Фрося and older than Руся and Муся: enormous bushy eyebrows, shoelace belt. 100% matches the reference.",
      refPath: "packet_v2/page-04.png",
    }
  | Mama => {
      tag: "@MAMA",
      tagLine: "@MAMA — её зовут Мама — the mother: blonde braid, red-and-gold striped kerchief, cream apron over a dark red skirt. 100% matches the reference.",
      refPath: "packet_v2/page-07.png",
    }
  | Papa => {
      tag: "@PAPA",
      tagLine: "@PAPA — его зовут Папа — the father: short and stocky, huge beard, blue work shirt with suspenders, iron key on a cord. 100% matches the reference.",
      refPath: "packet_v2/page-08.png",
    }
  /* Руся and Муся are separate people and are cast separately. The old single
     @BABIES tag made one description carry two characters and handed the model an
     unlabelled pair sheet to work out which was which — and babies drifting is a
     defect we have already had. Each now has its own captionless solo plate cut
     from the approved pose library. @BABIES survives for the still batch. */
  | Rusya => {
      tag: "@RUSYA",
      tagLine: "@RUSYA — его зовут Руся — the THIRD of the family's FOUR children, a toddler boy: an orange-brown tufted topknot standing up from a bald head, big round brown eyes, a patched ochre smock. 100% matches the reference.",
      refPath: "C-RUS-01_solo_from_packet_page14.png",
    }
  | Musya => {
      tag: "@MUSYA",
      tagLine: "@MUSYA — её зовут Муся — the YOUNGEST of the family's FOUR children, a baby girl: one curling wisp of hair on an otherwise bald head, sleepy heavy-lidded eyes, rosy cheeks, patched pink cloth. 100% matches the reference.",
      refPath: "C-MUS-01_solo_from_packet_page14.png",
    }
  | Babies => {
      tag: "@BABIES",
      tagLine: "@BABIES: the two SMALLEST of the family's four children and no others — Руся, a toddler boy with an orange-brown tufted topknot, and Муся, the youngest, a baby girl with one curling wisp of hair and patched pink cloth. No others anywhere; the matchbox beds are empty. 100% matches the reference.",
      refPath: "packet_v2/page-14.png",
    }
  | YagaFlight => {
      tag: "@YAGA",
      tagLine: "@YAGA — её зовут Бабушка-Яга — old grandmother witch in human flight form, patched skirt, streaming headscarf, standing braced in her flying wooden mortar. 100% matches the reference.",
      refPath: "packet_v2/page-12.png",
    }
  | VasyaCat => {
      tag: "@VASYA_CAT",
      tagLine: "@VASYA_CAT: Вася turned into a small ginger cat — he keeps his ENORMOUS shaggy dark eyebrows above the cat's eyes, the one feature that makes him recognisable. 100% matches the reference.",
      refPath: "T-VAS-CAT-01_approved.png",
    }
  | VasyaWasp => {
      tag: "@VASYA_WASP",
      tagLine: "@VASYA_WASP: Вася turned into a small striped wasp — he keeps his ENORMOUS shaggy dark eyebrows above the wasp's eyes. 100% matches the reference.",
      refPath: "T-VAS-WASP-01_approved.png",
    }
  | VasyaMama => {
      tag: "@VASYA_MAMA",
      tagLine: "@VASYA_MAMA: Вася transformed into a second МАМА — the SAME height as Мама, the same red-and-gold kerchief, blonde braid, cream apron over the dark red patched skirt. But the face is his: ENORMOUS shaggy dark eyebrows, a wide gap-toothed grin, and big round startled eyes. 100% matches the reference.",
      /* A SOLO CROP, never the two-up sheet. T-VAS-MAMA-01_approved.png shows the
         real Мама standing beside her, and a reference holding two characters
         lets the model take the wrong one — the same fault as one BABIES sheet
         holding both Руся and Муся, which the author stopped on 2026-08-23. The
         two figures are cropped apart and bound separately. */
      refPath: "C-VASMAMA-01_solo_from_T-VAS-MAMA-01.png",
    }
  | YagaDomovoy => {
      tag: "@YAGA",
      tagLine: "@YAGA — её зовут Бабушка-Яга — old grandmother house-spirit, mushroom-red polka-dot kerchief, patched skirt and shawl, gold tooth, warm sly face. 100% matches the reference.",
      refPath: "packet_v2/page-09.png",
    }
  }

/* Props carry the SAME guarantee as cast: whatever image is bound to a job is
   also named in the prompt text, so the model is never handed an unlabelled
   picture and left to guess what it is for. Before this, props were bound and
   never tagged — the room master went into every interior job as an anonymous
   image with nothing pointing at it.

   A prop is one of two things, and the type makes the difference impossible to
   fudge. Backed: an approved asset exists, so it is both tagged and bound.
   Described: no asset exists yet, so it is described in words and binds NOTHING.
   The five Described props below were previously bound to the ROOM MASTER as a
   stand-in, which silently fed a picture of the family's hall to the model as
   the reference for a scooter, a road, a tank, a ball of thread and a cake. */
type propEntry =
  | Backed({tag: string, tagLine: string, refPath: string})
  | Described({tag: string, tagLine: string})

let propEntry = (t: propToken): propEntry =>
  switch t {
  | FloorAfter =>
    Backed({
      tag: "@FLOOR_AFTER",
      tagLine: "@FLOOR_AFTER: the floorboards as they must look once he is gone — the four blocks lying dark and unlit in their row, the other blocks scattered around them, and the woven pouch on its side to the right. Everything on this floor stays exactly where this reference has it. 100% matches the reference.",
      /* Shot from the SAME camera as the start frame — wall/floor boundary at
         y=400 against the start frame's 399. It is bound instead of the bare
         empty-room plate, which showed a floor with nothing on it and would have
         invited the blocks and the pouch to vanish along with him. */
      refPath: "KF:2026-08-25_V05_floor_without_him_dark.png",
    })
  | RoomFront =>
    Backed({
      tag: "@ROOM_FRONT",
      tagLine: "@ROOM_FRONT: the family's hall inside the old bricked-up fireplace — boulder-brick walls, a riveted iron plate as the far wall, plank floor, a garland of coloured bulbs, a plank-on-spools table, matchbox beds along the left wall, a small dark iron cleanout hatch low in the left wall, a rope-railed floor opening at the right. 100% matches the reference.",
      refPath: "SET-HOME-ROOM-01_author_master_v4_hatch_cradle-clear.png",
    })
  | RoomFrontLow =>
    Backed({
      tag: "@ROOM_FRONT_LOW",
      tagLine: "@ROOM_FRONT_LOW: the SAME hall as @ROOM_FRONT, seen from a second camera height — down near the floorboards, looking along the room, the planks filling the lower half of frame and the knitted cradle cropped large in the near left foreground. This is a second viewpoint of one room, not a second room: same walls, same beds, same hatch, same table, same railed opening. Use it whenever the camera is low.",
      refPath: "SET-HOME-ROOM-01_author_low_angle.png",
    })
  | RoomFrontHatch =>
    Backed({
      tag: "@ROOM_FRONT_HATCH",
      tagLine: "@ROOM_FRONT_HATCH: the SAME hall as @ROOM_FRONT, seen from a third camera position turned toward the hatch wall — the cleanout hatch reads clearly at three-quarter in the left wall, the bed row runs away beside it, the knitted cradle sits in the near left foreground, and the table and sealed iron plate fall away to the right rear. One room, a third viewpoint. Use it whenever the hatch is the subject.",
      refPath: "SET-HOME-ROOM-01_author_hatch_angle.png",
    })
  | SeatingScene5 =>
    Backed({
      tag: "@SEATING",
      tagLine: "@SEATING: who sits where at the dinner table in this scene — Мама at the left end feeding Муся, Бабушка-Яга on the far side with the black riveted plate behind her, Папа at the right end feeding Руся, Вася and Фрося on the near side with their backs to camera and Фрося directly across from Бабушка-Яга. Take every position from this picture. It is the SEATING CHART for the scene and is NOT the framing of any shot — no shot in this job looks like it. 100% matches the reference.",
      refPath: "FRAME:scene5/2026-08-17_SCENE5_MASTER_dinner-table_author.png",
    })
  | RoomBack =>
    Backed({
      tag: "@ROOM_BACK",
      /* Shortened 2026-08-18. The long version was mostly furniture inventory and
         it crowded out the choreography at the prompt ceiling. What this plate is
         actually FOR is the thing behind the children when the camera looks down
         the room — the model does not blur backgrounds, so it needs real content
         back there rather than an instruction to dissolve it. */
      tagLine: "@ROOM_BACK: the far end of the SAME hall, past the rope railing and the ramp down — what lies beyond Фрося and Вася whenever the camera looks down the room. Same ENORMOUS sandstone boulder-blocks, same strung bulbs, the kitchen end with its stove and counter. 100% matches the reference.",
      refPath: "SET-HOME-ROOM-02_author_far_wall_v2.png",
    })
  | Carry =>
    Backed({
      tag: "@CARRY",
      tagLine: "@CARRY: how Мама holds her two youngest — Муся wrapped in pink and carried in the crook of Мама's arm, Руся up on his own feet beside her with a fistful of her skirt in his hand. Take that arrangement from this reference; do not invent another.",
      refPath: "C-MAM-CARRY-02_from_packet_page16.png",
    })
  | Roof =>
    Backed({
      tag: "@ROOF",
      tagLine: "@ROOF: the human house from outside — a long roof of dark slate tiles capped with a terracotta ridge, one red brick chimney standing up from it, clear blue sky with low-poly faceted white clouds. 100% matches the reference.",
      refPath: "SET-ROOF-01_author_master.png",
    })
  /* The door is PART OF THE ROOM and comes from @ROOM_FRONT. There was a separate
     "door states" plate; the author never approved it, and it disagreed with the
     room master about the wall — small red brick against the master's giant
     sandstone boulders. Binding both made two references argue about one door. */
  | Door =>
    Described({
      tag: "@DOOR",
      tagLine: "@DOOR: the small iron CLEANOUT HATCH low in the left wall of @ROOM_FRONT, exactly as it appears there — a flat dark iron plate set into the giant sandstone boulder-brick, its latch bar and ring on the left edge so it hinges on the right and swings sideways, lying back flat against the brick when open. Its sill sits about a third of the way up the wall, well off the floor. It is NOT a door and must never read as an entrance to the home: the family never uses it, and nobody comes or goes through it except Бабушка-Яга. It does NOT glow at rest — no light rim, no halo, no seam of light — it is dark, cold iron whenever nothing is happening to it, and light around it is an EVENT that appears only when something is coming through. NO APPROVED PLATE of it open yet — take the hatch itself from @ROOM_FRONT.",
    })
  | Stupa =>
    Backed({
      tag: "@STUPA",
      tagLine: "@STUPA: Баба-Яга's ступа — a carved wooden mortar in bare unpainted faceted wood, tapering in at the middle and standing on a stepped round foot, its mouth open and EMPTY. Indoors it stands empty and upright on the floorboards and she stands on the floor beside it, never inside it. 100% matches the reference.",
      refPath: "PROP-STUPA-01_author_solo.png",
    })
  | Pomelo =>
    Backed({
      tag: "@POMELO",
      tagLine: "@POMELO: Баба-Яга's помело — a long straight dark-wood stick with a shaggy head of torn grey and tan rag strips and thin twigs lashed to its end. It is a rag mop, NOT a twig besom. 100% matches the reference.",
      refPath: "PROP-POMELO-01_author_solo.png",
    })
  | Broom =>
    Backed({
      tag: "@BROOM",
      tagLine: "@BROOM: Баба-Яга's birch broom — a pale notched wooden handle with a bundle of thin dark-brown birch twigs bound to its end with cord wrapped several times. It is a twig besom, NOT a rag mop. 100% matches the reference.",
      refPath: "PROP-BROOM-01_author_solo.png",
    })
  | Top =>
    Backed({
      tag: "@TOP",
      tagLine: "@TOP: the mended юла́ — a red and cream striped wooden spinning top, metal staples and wood patches over its mends, a rope pull-toggle at the neck, and two little wooden chairs on opposite shoulders. 100% matches the reference.",
      refPath: "R-EP1-TOP-01_approved_author.png",
    })
  | Tin =>
    Backed({
      tag: "@TIN",
      tagLine: "@TIN: Фрося's art tin — a round shallow metal tin with a rolled rim and worn bare metal, its lid painted in parallel diagonal red and orange stripes chipped back to metal at the edges, holding EXACTLY FIVE faceted hexagonal colored cores (red, orange, yellow, green, blue) lying FLAT side by side in one straight row on a cream woven cloth liner, held down by two stitched cream cloth bands. 100% matches the reference.",
      refPath: "D-FRO-ARTBOX-01_approved_tin.png",
    })
  | Chest =>
    Backed({
      tag: "@CHEST",
      tagLine: "@CHEST: мама's letter chest — a small dark wooden chest with a domed lid, iron straps and rivets and a hasp latch, filled with small square pale-wood tiles carved with Cyrillic letters. 100% matches the reference.",
      refPath: "D-MAM-CHEST-01_approved.png",
    })
  | Tiles =>
    Backed({
      tag: "@TILES",
      tagLine: "@TILES: the wooden letter tiles — small square wooden tiles, each carved with one Cyrillic letter. 100% matches the reference. WHERE the tiles are in this shot is stated in the shot text and nowhere else.",
      refPath: "D-MAM-CHEST-01_approved.png",
    })
  | Pouch =>
    Backed({
      tag: "@POUCH",
      tagLine: "@POUCH: Вася's small cloth drawstring pouch for his letter tiles, as shown on his character sheet. 100% matches the reference. WHERE the pouch is in this shot — worn at his belt, or lying on the floor — is stated in the shot text and nowhere else.",
      refPath: "packet_v2/page-04.png",
    })
  /* THE JUICE — author's ruling 2026-08-23: the magic makes a GLASS, not a
     thimble. The thimble is the family's found-object scale; magic does not
     shop in their kitchen, and the glass is what lets Вася look at the world
     through it. Script updated from напёрсток to стакан the same day. */
  | Juice =>
    Backed({
      tag: "@JUICE",
      tagLine: "@JUICE: a small faceted low-poly drinking glass, clear with a thick base, filled most of the way with bright orange juice. A plain glass tumbler at a child's scale. 100% matches the reference.",
      refPath: "D-JUICE-GLASS-01_author.png",
    })
  | Salad =>
    Backed({
      tag: "@SALAD",
      tagLine: "@SALAD: the salad bowl — a small rounded ceramic bowl in pale clay with a painted band of red flowers and a green zigzag around it, filled with a diced salad of green and red pieces. 100% matches the reference.",
      refPath: "D-SALAD-BOWL-01_author.png",
    })
  | FloorAfter =>
    Backed({
      tag: "@FLOOR_AFTER",
      tagLine: "@FLOOR_AFTER: the floorboards as they must look once he is gone — the four blocks lying dark and unlit in their row, the other blocks scattered around them, and the woven pouch on its side to the right. Everything on this floor stays exactly where this reference has it. 100% matches the reference.",
      /* Shot from the SAME camera as the start frame — wall/floor boundary at
         y=400 against the start frame's 399. Bound INSTEAD of the bare
         empty-room plate, which showed a floor with nothing on it and would have
         invited the blocks and the pouch to vanish along with him. */
      refPath: "KF:2026-08-25_V05_floor_without_him_dark.png",
    })
  | Poppy =>
    Backed({
      tag: "@POPPY",
      tagLine: "@POPPY: the poppy — a single cut scarlet poppy on a long green stem with one serrated leaf, low-poly faceted petals around a dark seed centre. 100% matches the reference.",
      refPath: "D-POPPY-01_author.png",
    })
  | Pencil =>
    Backed({
      tag: "@PENCIL",
      tagLine: "@PENCIL: the magic pencil — a short stubby faceted wooden pencil in warm honey-toned wood. ONE END ONLY is sharpened to a dark graphite point; THE OTHER END IS BLUNT, FLAT AND BARE WOOD. It is never sharpened at both ends and there is no dark tip at the blunt end. No paint and no ferrule. 100% matches the reference.",
      refPath: "D-FRO-PENCIL-01_approved.png",
    })
  /* No approved asset exists for any of these five. They are described only and
     bind no image — see the reference gap list. */
  | Scooter =>
    Described({
      tag: "@SCOOTER",
      tagLine: "@SCOOTER: a kick scooter sized for Фрося, built from lost human things in the same mended, salvaged register as the юла. NO APPROVED REFERENCE YET — build from this description only.",
    })
  | Road =>
    Described({
      tag: "@ROAD",
      tagLine: "@ROAD: the underfloor road — a long plank corridor beneath the giants' floorboards, brick foundation walls either side, lanterns strung far along it. NO APPROVED REFERENCE YET — build from this description only.",
    })
  | Tank =>
    Described({
      tag: "@TANK",
      tagLine: "@TANK: a large inverted metal container, human-scale junk used as a trap, dropped mouth-down over its captive. NO APPROVED REFERENCE YET — build from this description only.",
    })
  | Thread =>
    Described({
      tag: "@THREAD",
      tagLine: "@THREAD: a ball of thread at house-spirit scale, with a loose end that can be paid out into the dark. NO APPROVED REFERENCE YET — build from this description only.",
    })
  | Cake =>
    Described({
      tag: "@CAKE",
      tagLine: "@CAKE: the birthday cake, built at house-spirit scale from crumbs and berries, with thin candles. NO APPROVED REFERENCE YET — build from this description only.",
    })
  }

let propTagLine = (t: propToken): string =>
  switch propEntry(t) {
  | Backed({tagLine}) => tagLine
  | Described({tagLine}) => tagLine
  }

let propTag = (t: propToken): string =>
  switch propEntry(t) {
  | Backed({tag}) => tag
  | Described({tag}) => tag
  }

let propRefPath = (t: propToken): option<string> =>
  switch propEntry(t) {
  | Backed({refPath}) => Some(refPath)
  | Described(_) => None
  }

let castName = (t: castToken): string =>
  switch t {
  | Frosya => "FROSYA"
  | Vasya => "VASYA"
  | Mama => "MAMA"
  | Papa => "PAPA"
  | Babies => "BABIES"
  | Rusya => "RUSYA"
  | Musya => "MUSYA"
  | YagaFlight => "YAGA_FLIGHT"
  | YagaDomovoy => "YAGA_DOMOVOY"
  | VasyaCat => "VASYA_CAT"
  | VasyaWasp => "VASYA_WASP"
  | VasyaMama => "VASYA_MAMA"
  }

/* The name each character is called BY in the choreography. castName gives the
   @tag spelling; this gives the Cyrillic the prose actually uses, so a gate can
   check whether a given person was written about at all. */
let castRuName = (t: castToken): option<string> =>
  switch t {
  | Frosya => Some("Фрося")
  | Vasya => Some("Вася")
  | Mama => Some("Мама")
  | Papa => Some("Папа")
  | Rusya => Some("Руся")
  | Musya => Some("Муся")
  | YagaFlight | YagaDomovoy => Some("Яга")
  | VasyaMama => Some("Вася-мама")
  | VasyaCat | VasyaWasp | Babies => None
  }

/* ---- Emission ---- */

exception BatchError(string)

/* SCALE. Nothing in these prompts ever stated how big anything is — the model was
   left to infer a matchbox world from prop names alone. These figures are the locked
   ones from 2026-08-04_OBJECT_SCALE_REGISTRY_v1.md, where Фрося's standing height is
   the unit (1 F = 3.50 in). Stated as relations between things in frame, because a
   model cannot measure inches but can be told what reaches whose chest. */
let castScale = (t: castToken): option<string> =>
  switch t {
  | Frosya => Some("Everyone here is tiny. Фрося is 3.50 in / 8.9 cm and is the unit.")
  | Vasya => Some("Вася is shorter than Фрося, about up to her eyebrows.")
  | Mama => Some("Мама is a little taller than Фрося.")
  | Papa => Some("Папа is the tallest, about a head above Мама.")
  | Babies => Some("@BABIES are far smaller: РУСЯ about 1.9 in, and МУСЯ smaller still — each fits along one of @MAMA's forearms.")
  | Rusya => Some("Руся is about half Фрося's height.")
  | Musya => Some("Муся is smaller again than Руся and is carried.")
  | YagaDomovoy => Some("@YAGA at house-spirit size stands about 3.60 in / 9.1 cm — the same order as the parents, never towering over them.")
  | YagaFlight => Some("@YAGA in human flight form stands about 147 cm — SIXTEEN TIMES the family's size. She is a full-grown human woman here.")
  | VasyaCat => Some("@VASYA_CAT is a cat at house-spirit scale, a little longer than @VASYA is tall.")
  | VasyaWasp => Some("@VASYA_WASP is a wasp at house-spirit scale, small enough to fly through a gap in the floorboards.")
  | VasyaMama => Some("@VASYA_MAMA stands at МАМА's full height, not Вася's — the height IS the joke, and she is a head taller than Фрося.")
  }

let propScale = (t: propToken): option<string> =>
  switch t {
  | RoomFront =>
    Some("The furniture is lost human things at this size: matchbox beds, a plank laid on thread spools, thimbles on the shelf, fairy-light bulbs overhead.")
  | Top =>
    Some("@TOP is as tall as Фрося and about three-quarters of Папа's height — a heavy, chunky object. Its two chairs are sized for these two children, one child per chair.")
  | Tin => Some("@TIN is a round tin that @FROSYA carries in both hands, about as wide as her head.")
  | Stupa => Some("@STUPA comes up to about @YAGA's waist.")
  | Pomelo => Some("@POMELO is a little taller than @YAGA.")
  | Broom => Some("@BROOM is a little taller than @YAGA.")
  | Chest => Some("@CHEST is a chest @MAMA can lift, its lid about knee height on her when it stands on the floor.")
  /* CORRECTED 2026-08-18. This said "a stub about half of @FROSYA's height — a
     two-handed tool for her", which is the pre-miniaturisation canon and is
     wrong. БАБУШКА-ЯГА MINIATURISES EVERYTHING SHE BRINGS: the pencil arrives
     sized for the person receiving it, so it sits in Фрося's palm, she writes
     with it one-handed, and it tucks behind her ear. The shooting script still
     carries the old version at SH068 ("почти достаёт до локтя" — almost reaches
     her elbow); that line is stale and must not be copied into a prompt. */
  | Pencil => Some("@PENCIL is sized for @FROSYA's own hand — it sits in her palm, she writes with it one-handed, and it fits behind her ear. It is NOT a giant human pencil and never dwarfs her.")
  | RoomFrontLow | RoomFrontHatch | RoomBack | SeatingScene5 | Carry | Roof | Door | Tiles | Pouch | Scooter | Road | Tank | Thread | Cake | Juice | Salad | Poppy | FloorAfter => None
  }

/* The creative text may not smuggle tag lines past the emitter: any "@" is a
   build-the-record-properly error, caught before money. */
let assertCreativeClean = (r: shotRecord): unit =>
  if Js.String2.includes(r.creative, "@") {
    raise(
      BatchError(
        r.jobId ++ ": creative text contains an @tag — cast lines are emitted, never hand-written",
      ),
    )
  }

/* A Latin-spelled character name sitting next to a Russian line gets SPOKEN in
   English phonetics — the clip where Папа said "Frosha" was generated from a
   prompt that was 2.4% Cyrillic and spelled her name "FROSYA" twice against
   «Фрося» once. The dominant spelling wins. Character names in the choreography
   are Cyrillic; the Latin form survives only as the @TAG handle, which is bound
   to the Cyrillic name inside the tag line itself. */
let latinCastNames = ["FROSYA", "VASYA", "MAMA", "PAPA", "YAGA", "Frosya", "Vasya", "Mama", "Papa", "Yaga"]

let assertCyrillicNames = (r: shotRecord): unit =>
  latinCastNames->Belt.Array.forEach(n =>
    if Js.String2.includes(r.creative, n) {
      raise(
        BatchError(
          r.jobId ++
          ": choreography spells a character name in Latin (\"" ++
          n ++
          "\") — next to a Russian line that gets spoken in English phonetics. Use the Cyrillic name.",
        ),
      )
    }
  )

/* Russian stress is unmarked, so a multi-syllable word handed to a voice model
   is a coin flip — «юла» reads as the girl's name «Юля» unless the stress is
   given. The pronunciation registry already holds the audio spelling for every
   taught word; this makes it impossible to put the display spelling inside a
   spoken line and ship it. Display spelling stays untouched everywhere else. */
let dialogueSegments = (s: string): array<string> =>
  s
  ->Js.String2.split(`«`)
  ->Belt.Array.keepMap(part =>
    switch Js.String2.indexOf(part, `»`) {
    | -1 => None
    | i => Some(Js.String2.slice(part, ~from=0, ~to_=i))
    }
  )

let assertDialoguePronunciation = (r: shotRecord): unit => {
  let lines = dialogueSegments(r.creative)
  Drakosha_Pronunciation.words->Belt.Array.forEach(w =>
    if w.display != w.audio {
      lines->Belt.Array.forEach(l =>
        if Js.String2.includes(l, w.display) {
          raise(
            BatchError(
              r.jobId ++
              ": a spoken line contains \"" ++
              w.display ++
              "\" in its DISPLAY spelling — a voice model reads it wrong. Use the audio spelling \"" ++
              w.audio ++
              "\" inside the quoted line.",
            ),
          )
        }
      )
    }
  )
}

/* Every multi-syllable Russian word in a spoken line carries an explicit stress
   mark, the way a children's primer prints them. Russian stress is unmarked in
   normal writing and a voice model guesses — «именинница» came back wrong, and
   «юла» reads as the name «Юля». Words containing ё are exempt: ё is always
   stressed in Russian. Only SPOKEN text is marked; nothing displayed is touched. */
let ruVowels = `аеёиоуыэюяАЕЁИОУЫЭЮЯ`
let stressMark = `\u0301`

/* A prompt that carries no spoken line at all is the failure that produced a
   12-second scene-5 job in ENGLISH: the choreography described "she speaks,
   warm and sly" instead of quoting the line, so the model wrote its own
   dialogue in the language the prompt was written in. Every existing assertion
   about dialogue iterates over segments that were not there, so all of them
   passed vacuously. A shot that is meant to be silent says so in one word. */
/* A THIRD STATE: SPEECH WE SEE BUT DO NOT HEAR. Added 2026-08-21.

   The gate offered two options — quote the line, or declare the shot silent —
   and a room full of adults at tea is neither. Declaring it silent gave a
   frozen tableau: the author's note was that a room where nobody talks reads
   as a room where nothing is happening. Quoting a line would demand a
   recording for dialogue the audience is never meant to make out.

   BACKGROUND SPEECH is the real category. The model animates mouths freely,
   its invented audio is muted like any other shot's, and a murmur bed goes
   under. The declaration has to be explicit so that nobody reaches this state
   by accident — a foreground line left unquoted must still fail. */
let assertHasDialogue = (r: shotRecord): unit => {
  let lines = dialogueSegments(r.creative)
  let lower = Js.String2.toLowerCase(r.creative)
  let declaredSilent =
    Js.String2.includes(lower, "nobody speaks") ||
    Js.String2.includes(lower, "no dialogue in this sequence") ||
    (Js.String2.includes(lower, "background speech") &&
      Js.String2.includes(lower, "not intelligible"))
  if Belt.Array.length(lines) == 0 && !declaredSilent {
    raise(
      BatchError(
        r.jobId ++
        ": choreography quotes no spoken line and is not declared silent. Quote the Russian in «», or write \"nobody speaks\", or — for a room where people talk but the audience is not meant to make out the words — declare BACKGROUND SPEECH and say it is NOT INTELLIGIBLE. Describing that a character speaks without one of these makes the model invent its own dialogue, in English.",
      ),
    )
  }
}

/* Every quoted segment must actually be Russian. A Latin-alphabet line inside
   the quote marks is a line that will be spoken in English. */
let assertDialogueIsRussian = (r: shotRecord): unit =>
  dialogueSegments(r.creative)->Belt.Array.forEach(l => {
    let hasCyrillic = Js.Re.test_(%re("/[\u0400-\u04FF]/"), l)
    if !hasCyrillic && Js.String2.length(Js.String2.trim(l)) > 0 {
      raise(
        BatchError(
          r.jobId ++ ": a quoted spoken line contains no Cyrillic — \"" ++ l ++ "\". Every line is spoken in Russian.",
        ),
      )
    }
  })

/* B1 — the job-10 rejection was an 8,160-character prompt. Long prompts also
   bury the rules that matter under scenery. */
/* This used to measure r.creative against 7500, which is the wrong string: the
   emitter prepends ACTIVE REFERENCES and SCALE, so what the model actually
   receives runs roughly 2000 characters longer and grows with the cast. A job
   could sit under the ceiling here and go out well over it.
   The ceiling means "longer than any prompt that has ever worked here", NOT "the
   filter trips at this number". job17 succeeded — its footage is what job18's
   start frame was cut from — and job19 and job18 succeeded shorter. Job 10 was
   rejected nsfw at a length BELOW job17, so length alone was never the cause
   there: the infant clothing detail, "barefoot" on four characters and the
   age+sex construction were.

   9400, raised from 9200 on 2026-08-17. NOT because a longer prompt succeeded —
   because the identity locks themselves grew by roughly 150 characters that day
   (the four children were re-ranked as four siblings rather than two pairs, Руся
   and Муся got real descriptions instead of pose locks, and every tagLine got the
   "100%" guarantee that only Яга had carried). Every job's floor rose together,
   so the same job17 choreography that worked now measures 9347. The evidence did
   not change; the ruler did. Raise this again ONLY for the same reason, or when a
   genuinely longer prompt has actually succeeded. Measured on the finished
   prompt, which is what the model receives — not on the creative file. */
let assertEmittedBudget = (jobId: string, prompt: string): unit =>
  if Js.String2.length(prompt) > 9400 {
    raise(
      BatchError(
        jobId ++
        ": the emitted prompt is " ++
        Belt.Int.toString(Js.String2.length(prompt)) ++
        " characters, which is longer than any prompt that has ever succeeded on this show — the record is job17 at 9198. Cut the choreography, not the locks.",
      ),
    )
  }

/* B6 — retired canon that keeps coming back. The hatch is side-hinged and never
   a ramp; the ступа carries no pestle and no lashed bundles. */
let retiredCanon = [
  ("pestle", "the pestle was retired from the ступа"),
  ("bundles lashed", "the lashed bundles were retired from the ступа"),
  ("like a ramp", "the cleanout hatch is side-hinged and never drops open like a ramp"),
  ("drops open", "the cleanout hatch is side-hinged and never drops open"),
]

let assertRetiredCanon = (r: shotRecord): unit => {
  let c = Js.String2.toLowerCase(r.creative)
  retiredCanon->Belt.Array.forEach(((phrase, why)) => {
    /* a mention inside a prohibition is the prompt doing its job, not a defect */
    let idx = Js.String2.indexOf(c, phrase)
    if idx >= 0 {
      let from = idx - 14 < 0 ? 0 : idx - 14
      let before = Js.String2.slice(c, ~from, ~to_=idx)
      let negated =
        Js.String2.includes(before, "no ") ||
        Js.String2.includes(before, "never") ||
        Js.String2.includes(before, "without")
      if !negated {
        raise(BatchError(r.jobId ++ ": choreography says \"" ++ phrase ++ "\" — " ++ why ++ "."))
      }
    }
  })
}

/* The giant boulder-blocks ARE the scale-tell: they are what shows these people
   are matchbox-sized. A prompt that says "brick" without saying the blocks are
   enormous gets ordinary masonry back, and the characters silently become
   ordinary people. */
let assertScaleTell = (r: shotRecord): unit => {
  let c = Js.String2.toLowerCase(r.creative)
  /* "bricked-up fireplace" is the canon name of where they live, and the giants'
     own chimney is genuinely normal brick. Only the family's WALLS are at issue. */
  let saysWall = Js.String2.includes(c, "brick wall") || Js.String2.includes(c, "brick walls")
  let qualified =
    Js.String2.includes(c, "boulder") ||
    Js.String2.includes(c, "giant") ||
    Js.String2.includes(c, "enormous") ||
    Js.String2.includes(c, "sandstone")
  if saysWall && !qualified {
    raise(
      BatchError(
        r.jobId ++
        ": choreography says \"brick wall\" without calling the blocks giant/boulder/enormous/sandstone — the model returns normal-scale masonry and the scale-tell is lost.",
      ),
    )
  }
}

/* B8 — nine beats written into an eight-second shot. The model compresses, and
   it chooses what to drop. Roughly 1.2s is the floor for a beat that reads. */
let assertBeatBudget = (r: shotRecord): unit => {
  let beats =
    r.creative
    ->Js.String2.split("\n")
    ->Belt.Array.keep(l => Js.Re.test_(%re("/^\s*\d:\d\d to \d:\d\d/"), l))
    ->Belt.Array.length
  if beats > 0 && Belt.Int.toFloat(beats) *. 1.2 > Belt.Int.toFloat(r.durationSec) {
    raise(
      BatchError(
        r.jobId ++
        ": " ++
        Belt.Int.toString(beats) ++
        " timed beats in " ++
        Belt.Int.toString(r.durationSec) ++
        "s. Under about 1.2s each the model compresses and picks what to drop itself — lengthen the job or cut beats.",
      ),
    )
  }
}

let assertDialogueStress = (r: shotRecord): unit =>
  dialogueSegments(r.creative)->Belt.Array.forEach(line => {
    let cleaned = line->Js.String2.replaceByRe(%re("/[^\u0400-\u04FF\u0301-]/g"), " ")
    cleaned
    ->Js.String2.split(" ")
    ->Belt.Array.forEach(w =>
      if w != "" {
        let vowels =
          w->Js.String2.split("")->Belt.Array.reduce(0, (n, c) =>
            Js.String2.includes(ruVowels, c) ? n + 1 : n
          )
        let marked = Js.String2.includes(w, stressMark)
        let hasYo = Js.String2.includes(w, `ё`) || Js.String2.includes(w, `Ё`)
        if vowels >= 2 && !marked && !hasYo {
          raise(
            BatchError(
              r.jobId ++
              ": spoken word \"" ++
              w ++
              "\" has more than one syllable and no stress mark — a voice model will guess. Mark the stressed vowel.",
            ),
          )
        }
      }
    )
  })

/* The show's cast are small children, and a provider content filter scores text
   without context. Job10 was rejected outright as nsfw on 2026-08-13 and still
   charged, on a prompt that described infants' clothing and called four
   characters barefoot. Their bodies and their bare feet are IN THE REFERENCE
   PLATES — the text never needs to say it. Author ruling: never write barefoot
   children, or any body state, anywhere in a prompt. */
let bodyStateWords = [
  "barefoot", "bare feet", "bare legs", "bare arms", "bare skin", "naked", "undressed",
  "thighs", "belly", "diaper", "nappy", "bare chested", "shirtless",
]

let assertNoBodyState = (r: shotRecord): unit =>
  bodyStateWords->Belt.Array.forEach(w =>
    if Js.String2.includes(Js.String2.toLowerCase(r.creative), w) {
      raise(
        BatchError(
          r.jobId ++
          ": choreography says \"" ++
          w ++
          "\" — never describe a child's body or bare feet in a prompt; the reference plates carry it, and this is what got a job rejected as nsfw.",
        ),
      )
    }
  )

/* Camera language that reads as a literal viewpoint gets DRAWN as one. Job10's
   shot C said "at the eye height of Фрося … framed from her perspective" and came
   back as a face seen through a dark eye-shaped iris. Say where the camera sits
   and how high it is; never say whose eyes we are behind. */
let povPhrases = ["from her perspective", "from his perspective", "point of view", "pov shot", "eye height of", "through her eyes", "through his eyes"]

let assertNoPov = (r: shotRecord): unit =>
  povPhrases->Belt.Array.forEach(w =>
    if Js.String2.includes(Js.String2.toLowerCase(r.creative), w) {
      raise(
        BatchError(
          r.jobId ++
          ": camera direction says \"" ++
          w ++
          "\" — the model draws that literally, as a view through an eye. State the camera's position and height instead.",
        ),
      )
    }
  )

/* Баба-Яга exists at two scales and has a sheet for each. Job18 shipped bound to
   the HUMAN flight sheet while its own text said "already at her small domovoi
   size, the same height as the family" — the picture followed the reference, not
   the words, and 52 credits bought the wrong grandmother. The prompt's own claim
   about her size now has to agree with the sheet it is given. */
let assertYagaScale = (r: shotRecord): unit => {
  let c = Js.String2.toLowerCase(r.creative)
  let saysSmall =
    Js.String2.includes(c, "domovoi size") ||
    Js.String2.includes(c, "same height as the family") ||
    Js.String2.includes(c, "domovoi-sized")
  /* only POSITIVE assertions count — "never seen at human size" is the opposite claim */
  let saysHuman =
    Js.String2.includes(c, "at full human size") ||
    Js.String2.includes(c, "full-sized human") ||
    Js.String2.includes(c, "roughly 147cm")
  let hasFlight = r.cast->Belt.Array.some(x => x == YagaFlight)
  let hasDomovoy = r.cast->Belt.Array.some(x => x == YagaDomovoy)
  if saysSmall && hasFlight {
    raise(
      BatchError(
        r.jobId ++
        ": the choreography says she is at domovoi size, but the job binds @YAGA's HUMAN flight sheet. Bind YagaDomovoy.",
      ),
    )
  }
  if saysHuman && hasDomovoy {
    raise(
      BatchError(
        r.jobId ++
        ": the choreography says she is at human size, but the job binds @YAGA's DOMOVOI sheet. Bind YagaFlight.",
      ),
    )
  }
}

let emitPrompt = (r: shotRecord): string => {
  assertCreativeClean(r)
  assertCyrillicNames(r)
  assertDialoguePronunciation(r)
  assertDialogueStress(r)
  assertNoBodyState(r)
  assertNoPov(r)
  assertYagaScale(r)
  assertHasDialogue(r)
  assertDialogueIsRussian(r)
  assertRetiredCanon(r)
  assertScaleTell(r)
  assertBeatBudget(r)
  let castLines = r.cast->Belt.Array.map(t => (castEntry(t)).tagLine)
  let propLines = r.props->Belt.Array.map(propTagLine)
  let roster =
    r.cast
    ->Belt.Array.map(t => (castEntry(t)).tag)
    ->Js.Array2.joinWith(", ")
  let propRoster = r.props->Belt.Array.map(propTag)->Js.Array2.joinWith(", ")
  let propClause = switch Belt.Array.length(r.props) {
  | 0 => ""
  | _ => " The set and props are " ++ propRoster ++ ", and each matches its reference exactly."
  }
  let constraints =
    "POSITIVE CONSTRAINTS\n" ++
    "Exactly these characters and no others: " ++
    roster ++
    ". Every character matches their reference exactly." ++
    propClause ++
    " No additional people, no additional babies, no duplicates. " ++
    "No text, no subtitles, no watermarks."
  let scaleLines = Belt.Array.concat(
    r.cast->Belt.Array.keepMap(castScale),
    r.props->Belt.Array.keepMap(propScale),
  )
  let scaleBlock = switch Belt.Array.length(scaleLines) {
  | 0 => ""
  | _ => "SCALE\n" ++ scaleLines->Js.Array2.joinWith("\n") ++ "\n\n"
  }
  let prompt =
    "ACTIVE REFERENCES\n" ++
    Belt.Array.concat(castLines, propLines)->Js.Array2.joinWith("\n") ++
    "\n\n" ++
    scaleBlock ++
    r.creative ++
    "\n\n" ++
    constraints
  assertEmittedBudget(r.jobId, prompt)
  prompt
}

/* Reference bindings: cast first, then props, deduplicated, same registry. */
let emitRefPaths = (r: shotRecord): array<string> => {
  let all = Belt.Array.concat(
    r.cast->Belt.Array.map(t => (castEntry(t)).refPath),
    r.props->Belt.Array.keepMap(propRefPath), // Described props bind no image
  )
  let seen = Js.Dict.empty()
  all->Belt.Array.keep(p =>
    switch Js.Dict.get(seen, p) {
    | Some(_) => false
    | None =>
      Js.Dict.set(seen, p, true)
      true
    }
  )
}
