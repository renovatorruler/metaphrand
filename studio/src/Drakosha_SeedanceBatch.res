/* EP1 scenes 2–4 Seedance batch — typed shot records and the prompt/args emitter.

   The invariant this module exists to enforce BY CONSTRUCTION: a character in a
   shot's cast always gets BOTH its @TAG line in the prompt AND its reference
   binding in the provider args, because both are derived from the same token
   through the same registry. An untagged-but-bound (or bound-but-untagged)
   character is unrepresentable.

   This module is pure (no IO): Drakosha_SceneFlow's seedance stage owns file
   checks, readiness, receipts, and the one sanctioned spawn point. */

/* FrosyaPencil and VasyaPouch are the SAME two children later in the day, and
   they exist because the sheets differ. Фрося carries the pencil stub in her hair
   from the moment she is given it, and Вася wears the pouch from SH098 onward.
   Added as new tokens rather than by repointing Frosya and Vasya, because the
   scenes before those two moments still need the earlier sheets and silently
   changing 25 existing shot records is how the wrong мама happened. */
type castToken = VasyaNoFace | Frosya | FrosyaPencil | Vasya | VasyaPouch | Mama | Papa | Babies | Rusya | Musya | YagaFlight | YagaDomovoy | VasyaCat | VasyaWasp | VasyaMama
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
type propToken = RoadPlate | VasyaArm | FloorTopdown | RoadWall | ScooterCutout | ScooterPlaced | TwoMamas | FloorAfter | RoomFront | RoomFrontLow | RoomFrontHatch | RoomBack | SeatingScene5 | Carry | Roof | Door | Stupa | Pomelo | Broom | Top | Tin | Chest | Tiles | Pouch | Pencil | Scooter | Road | Tank | Thread | Cake | Juice | Salad | Poppy

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

/* A REFERENCE LINE NAMES WHO, NOT WHAT THEY LOOK LIKE.
   Author, 2026-09-02: "why are we describing a reference when we have a blockout
   and a reference? I do not want to see any descriptions."

   Every line in this file was a paragraph, 87 to 808 characters, sitting in the
   HIGHEST-WEIGHTED block of the prompt and re-describing an image attached to the
   same request. That is not merely wasted budget: @ROAD's opened "running away
   into the dark" and closed with lights "running far away down the road", and
   SP138 came back with the girl turning round and riding away up the road while
   the blockout had her coming straight at the lens. Words beat the blockout
   because they sat higher up.

   A line needs exactly enough to bind the TAG to the right attached image, plus
   the one feature the model reliably drops if unnamed — Вася's eyebrows are what
   make him recognisable at distance. Everything else is in the picture, and
   [[sheet-beats-negation]] cuts both ways: words cannot beat the sheet, so all
   they can do is muddy it.

   Trimmed so far: @ROAD, @FROSYA (pencil), @VASYA (pouch) — the three the scene 10
   shots bind. assertReferenceLinesAreShort below refuses the rest as they come up. */
let castEntry = (t: castToken): castEntry =>
  switch t {
  | Frosya => {
      tag: "@FROSYA",
      tagLine: "@FROSYA: a girl with long dark hair, an orange flower in her hair on one side, freckles and a gap-toothed grin, wearing a floral patchwork dress with a large safety pin at the front. 100% matches the reference.",
      refPath: "packet_v2/page-05.png", // official «Фрося — ДО карандаша» sheet (packet v2)
    }
  | FrosyaPencil => {
      tag: "@FROSYA",
      tagLine: "@FROSYA: the girl. 100% matches the reference.",
      refPath: "packet_v2/page-06.png", // official «Фрося — ПОСЛЕ карандаша (canon)» sheet
    }
  | VasyaPouch => {
      tag: "@VASYA",
      tagLine: "@VASYA: the boy, ENORMOUS bushy brows. 100% matches the reference.",
      refPath: "C-VAS-02_with_pouch_from_page04.png",
    }
  /* HIS SHEET WITHOUT THE FEATURE NOTE. The brows are named on his usual line because
     they are what the model drops at distance — but in a shot that never sees his face
     that is a description of something not in frame, competing for attention with the
     three things that are. Author, 2026-09-03: "do not talk about his eyebrows. It's
     pointless here." */
  | VasyaNoFace => {
      tag: "@VASYA",
      tagLine: "@VASYA: the boy. 100% matches the reference.",
      refPath: "C-VAS-02_with_pouch_from_page04.png",
    }
  | Vasya => {
      tag: "@VASYA",
      tagLine: "@VASYA: a small figure with ENORMOUS bushy dark eyebrows and short fair hair, wearing a shoelace tied round the waist as a belt. 100% matches the reference.",
      refPath: "packet_v2/page-04.png",
    }
  | Mama => {
      tag: "@MAMA",
      tagLine: "@MAMA: a woman with a long blonde braid, a red-and-gold striped kerchief, a cream apron over a dark red skirt, and ordinary thin eyebrows. 100% matches the reference.",
      refPath: "packet_v2/page-07.png",
    }
  | Papa => {
      tag: "@PAPA",
      tagLine: "@PAPA: a short stocky man with a huge dark beard, a blue work shirt with suspenders and an iron key on a cord round his neck. 100% matches the reference.",
      refPath: "packet_v2/page-08.png",
    }
  /* Руся and Муся are separate people and are cast separately. The old single
     @BABIES tag made one description carry two characters and handed the model an
     unlabelled pair sheet to work out which was which — and babies drifting is a
     defect we have already had. Each now has its own captionless solo plate cut
     from the approved pose library. @BABIES survives for the still batch. */
  | Rusya => {
      tag: "@RUSYA",
      tagLine: "@RUSYA: a bald baby with an orange-brown tufted topknot standing up from the head, big round brown eyes and a patched ochre smock. 100% matches the reference.",
      refPath: "C-RUS-01_solo_from_packet_page14.png",
    }
  | Musya => {
      tag: "@MUSYA",
      tagLine: "@MUSYA: a bald baby with one curling white wisp of hair, sleepy heavy-lidded eyes, rosy cheeks and patched pink cloth. 100% matches the reference.",
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
      /* IDENTITY ONLY, AND NO STORY. The old line spent 185 characters re-describing
         the attached sheet. It also said this cat IS Вася transformed, which is context
         for us and instruction for nobody: the model has a sheet of a cat and needs to
         draw that cat. Author, 2026-09-03: "do not tell us that VasyaCat reference is
         Vasya in a cat form. Who cares? I do not want a single line in this prompt
         assuming that the model cares about the context." */
      /* NOT "small". The script's «маленького рыжего кота» is small as cats go; beside a
         house spirit he is gigantic, and that word sitting in the highest-weighted block
         argues with every size instruction below it. */
      tagLine: "@VASYA_CAT: the ginger cat, ENORMOUS shaggy brows. 100% matches the reference.",
      refPath: "T-VAS-CAT-01_approved.png",
    }
  | VasyaWasp => {
      tag: "@VASYA_WASP",
      tagLine: "@VASYA_WASP: Вася turned into a small striped wasp — he keeps his ENORMOUS shaggy dark eyebrows above the wasp's eyes. 100% matches the reference.",
      refPath: "T-VAS-WASP-01_approved.png",
    }
  | VasyaMama => {
      tag: "@VASYA_MAMA",
      tagLine: "@VASYA_MAMA: a woman with a long blonde braid, a red-and-gold striped kerchief and a cream apron over a dark red patched skirt, with ENORMOUS shaggy dark eyebrows over big round eyes and a wide gap-toothed grin. 100% matches the reference.",
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
  | TwoMamas =>
    Backed({
      tag: "@TWO_MAMAS",
      tagLine: "@TWO_MAMAS: the two women standing side by side — TWINS, the same height with head tops level, identical build and dress, differing only in their faces. 100% matches the reference.",
      refPath: "T-VAS-MAMA-01_approved.png",
    })
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
  /* THE POUCH USED TO POINT AT A PICTURE WITHOUT A POUCH IN IT. Its refPath was
     packet_v2/page-04.png — Вася's own sheet, on which he wears a shoelace belt
     and a mallet and no pouch at all — while its tagLine said "as shown on his
     character sheet". Every job that bound @POUCH was therefore handing the model
     a reference that did not contain the thing the line named, and the pouch was
     being carried entirely by prose. Found 2026-09-01; now bound to the real
     article, cut from SH098 where Мама ties it on. */
  | Pouch =>
    Backed({
      tag: "@POUCH",
      tagLine: "@POUCH: Вася's small leather drawstring pouch. 100% matches the reference.",
/* The author's clean solo prop on white, 2026-09-02, replacing a CROP out of an
         earlier shot that carried that shot's warm blurred room behind it — the same
         fault that put the living room into the exchange wide. Author: "we're not
         giving any crops as a reference."
         It is SHUT in this picture: the drawstring is knotted at the neck and the
         gathered fabric stands above the tie. I first read that gathered top as an
         open mouth and said so; the author corrected it. */
      refPath: "D-VAS-POUCH-02_author_solo.png",
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
  /* APPROVED 2026-08-27 — the author's own sheet, with turnaround, detail insets,
     swatches and a scale panel. It supersedes the old description outright: that
     text called for something salvaged and mended in the register of the юла, and
     the approved scooter is nothing of the kind. It is a clean manufactured red
     one, which is what she asked for — "as long as it looks like a regular
     scooter, all we care is that it's consistent." A card that argued with its own
     reference would be the height-anchor mistake all over again. */
  /* THE SCOOTER STANDING IN THIS ROOM, AT SIZE. 2026-08-30, the author's plate.
     The sheet says what the scooter IS; this says how big it is on these boards
     beside a kneeling Фрося, which is the one thing three attempts at wording
     failed to pin. It is a reference, not a keyframe — in it she is looking at
     her paper, which is the wrong beat for either end of a shot. */
  | ScooterPlaced =>
    Backed({
      tag: "@SCOOTER_PLACED",
      tagLine: "@SCOOTER_PLACED: the same kick scooter standing upright on the floorboards of the main room, at the size it is on these boards. 100% matches the reference.",
      refPath: "PROP-SCOOTER-02_in-place_author.png",
    })
  /* THE SCOOTER WITH NO ROOM AROUND IT. @SCOOTER's in-place plate is a picture of
     the hall with a scooter standing in it, and it was chosen for a shot where the
     value was placement — where the scooter stands, at what size, on these boards.

     ONCE A BLOCKOUT SUPPLIES PLACEMENT, that plate stops being a scooter reference
     and becomes a second backplate. On s9exchangewide, 2026-09-01, it beat
     @ROOM_BACK outright: the render came back with the in-place plate's stove, its
     shelf of jars, its melon, its string lights and its letter tiles on the floor,
     and none of @ROOM_BACK's furniture. Two room shots went in and the one shot at
     this shot's camera won.

     So: a blockout-directed job binds ScooterCutout, which has no room in it at all,
     and lets the backplate be the only picture of the room in the job. */
  | ScooterCutout =>
    Backed({
      tag: "@SCOOTER",
      tagLine: "@SCOOTER: the red kick scooter. 100% matches the reference.",
      refPath: "PROP-SCOOTER-01_approved_cutout_transparent.png",
    })
  | Scooter =>
    Backed({
      /* SIXTY WORDS PAINTING A SCOOTER, AT THE TOP OF THE PROMPT, FOR AN OBJECT
         THAT MUST NOT EXIST UNTIL THE LAST THREE SECONDS. 2026-08-30. The line
         listed the deck, the clamp collars, the lightning bolt and the mudguard
         — all of it visible in the attached image, and all of it read as
         instruction because it sits in the first block. The author had already
         warned that showing the model the finished scooter invites it to open on
         one. A reference line fixes identity; the picture does the describing.
         The in-place plate replaces the design sheet: it is the same scooter,
         drawn by the author, standing on these boards at its size. 2026-08-30,
         second version — the author's own frame of the empty room with the
         scooter in it, same camera as the start plate and no Фрося in the
         picture. It carries size and placement without showing the shot's last
         moment, which is what a reference of the finished state would do. */
      tag: "@SCOOTER",
      tagLine: "@SCOOTER: Фрося's red kick scooter, brand new and gleaming. 100% matches the reference.",
      refPath: "PROP-SCOOTER-02_in-place_author.png",
    })
  /* APPROVED 2026-08-27 — the author's plates. They supersede every earlier
     description, including the one written from her verbal brief the same day:
     the floor is PLANKS, not concrete, and the open side is not bare darkness
     but a colonnade of wooden posts carrying the joists, with the dark behind
     them. That is a better answer than either version I wrote, because it says
     out loud what holds the floor up.

     THE TWO PLATES ARE REVERSE ANGLES AND THEY AGREE. Facing away from the ramp
     the block wall is on the RIGHT and the posts on the LEFT; facing back toward
     the ramp it is the other way round. The chase has her ride away and come
     back, so the wall must change sides with her — getting that backwards is the
     scene-8 geography error waiting to happen again. */
  /* APPROVED 2026-08-27 — the author's plates, cool-palette concept latest.

     THE ROAD IS COOL AND THE ROOM IS WARM, DELIBERATELY. Author: "what if we
     keep it color-wise feeling very different from the upstairs space... so you
     immediately know from the quality of light and colors that you're in a
     different space." It also buys palette headroom: EP1 goes further down still
     (the dark hole at SP169), and a show that is amber everywhere has nothing
     colder left to spend when it needs to frighten.

     COOL AMBIENT, WARM KEY ON THE FACES. The space is steel blue; the characters
     are lit warm. Let the key go cool and the faces go muddy, which kills the
     comedy in a show made for small children.

     WHAT THIS SUPERSEDES: the floor is PLANKS, not concrete. The open side is a
     colonnade of posts carrying the joists, not bare darkness. The four chase
     test clips are warm amber throughout and are BLOCKING REFERENCE ONLY — their
     palette is retired.

     THE TWO EARLIER PLATES ARE REVERSE ANGLES AND THEY AGREE. Facing away from
     the ramp the block wall is on the RIGHT and the posts on the LEFT; facing
     back toward the ramp it is the other way round. The chase has her ride away
     and come back, so the wall changes sides with her. */
  /* THE WALL-AND-POSTS ANGLE. @ROAD's other plates look ALONG the road — the ramp
     view and its reverse — and neither is this shot, which faces the stone wall
     square with two posts standing between the lens and it. Author, 2026-09-02, when
     shown the ramp plate for the laps: "wrong reference. You have the reference for
     that back row and posts." Same road, same tag; the camera is the difference, and
     a set plate at the wrong angle drags the whole frame to its own. */
  /* A HAND SHEET, NOT A BODY SHEET, and ONE of them. The tile shots see hands and
     nothing else, and the Б motion test settled what that needs: given his full figure
     the model returned a generic adult-proportioned hand; given a hand sheet it was
     right. Author, 2026-09-03: "I really don't think we need two arm references. What
     do they give us?" Nothing — a left hand is a mirror of a right, so one sheet
     produces both, and naming the arm only invites the model to reason about
     handedness. The LEFT sheet is bound because its close-up row carries a POINT pose,
     which is the gesture these shots end on. */
  | VasyaArm =>
    Backed({
      tag: "@HAND",
      /* NOT "the boy's hand". A minor next to a body part is the pattern that had a
         mini run refused as nsfw this morning; the wording that passed dropped the
         child and named the sheet instead. The sheet is a sheet of small hands and
         carries the proportions on its own. */
      tagLine: "@HAND: the hand and forearm. 100% matches the reference.",
/* BACK TO THE ORIGINAL SHEET. The arm turnaround returned the author's own adult
         hand proportions; his first hand sheet — 13 poses, elbow to fingers — is the one
         that worked on the Б test. Author, 2026-09-03: "the hand proportions are my
         hands, not the reference hand. I think we should be using the original hand
         reference I provided you." */
      refPath: "C-VAS-HAND-01_author_right-arm-sheet.png",
    })
  /* The boards seen from STRAIGHT ABOVE. Every other road plate looks along the road
     and is useless to a camera pointing at the floor. Supplied by the author for the
     tile-motion test and proven there. */
  | FloorTopdown =>
    Backed({
      tag: "@FLOOR",
      tagLine: "@FLOOR: the wooden floorboards seen from above. 100% matches the reference.",
/* The ROAD's own boards from above, supplied 2026-09-03 — cool at one edge and
         warm where a bulb pools, which is the light every other scene 10 shot came back
         with. FLOOR-01 was a generic warm floor made for the Б test and would have put
         a different room's light under the tiles. */
      refPath: "R-EP1-FLOOR-02_author_road_boards_topdown.png",
    })
  | RoadWall =>
    Backed({
      tag: "@ROAD",
      tagLine: "@ROAD: the underfloor road. 100% matches the reference.",
      /* THE COOL ONE, NOT THE WIDE ONE. Both show this angle; the _wide plate is
         warmer — brown posts, orange boards — and SP138 came back cool: grey-blue
         stone, cold depth, warm only in the bulbs and a pool underfoot. Author,
         2026-09-02: "this seems to be a lot warmer than what we have." A set plate
         sets the temperature of the whole frame, so the two shots have to be cut
         from the same one or they will not sit together. */
/* The author's own grade of the wide plate, 2026-09-02, matched to a frame of
         the delivered SP138 rather than to an intention. The ungraded _wide plate is
         browner and would not cut with the descent; the un-wide plate is cool but
         tight, and she would be entering and leaving frame almost on top of him. */
      refPath: "SET-ROAD-01_author_wall_straight_posts_wide_COOL.png",
    })
  /* THE CLEAN PLATE, MADE BY THE AUTHOR TO MATCH ONE START FRAME EXACTLY. Same camera,
     same lens, same light, nobody in it — so when a character walks off a mark the model
     has the actual boards, wall and posts that were behind them rather than an invention.
     This is NOT @ROAD: @ROAD is the master set plate at its own angle and will fight a
     start frame. Bind this one only with the start frame it was built for. */
  | RoadPlate =>
    Backed({
      tag: "@PLATE",
      tagLine: "@PLATE: the empty road behind them, with nobody in it. 100% matches the reference.",
      refPath: "SET-ROAD-02_clean_plate_author.png",
    })
  | Road =>
    Backed({
      tag: "@ROAD",
      /* A HUNDRED WORDS RE-DESCRIBING A PLATE THAT IS ATTACHED TO THE SAME REQUEST.
         Author, 2026-09-02: "why are we describing a reference when we have a
         blockout and a reference? I do not want to see any descriptions."

         And it was not merely wasted: this line opened with "running away into the
         dark" and closed with lights "running far away down the road" — the word
         AWAY twice, in the highest-weighted block of the prompt — while the girl's
         direction was stated only twice, lower down, once as the direction-agnostic
         "out of frame". SP138 came back with her turning round and riding away up
         the road. The blockout had her right; the words outranked it.

         A set line fixes IDENTITY. The plate fixes everything else, and it always
         travels with the line. Same law as [[sheet-beats-negation]] from the other
         direction: words cannot beat the sheet, so they can only muddy it. */
      tagLine: "@ROAD: the underfloor road. 100% matches the reference.",
      /* The CLEAN plate, no characters in it. A set reference carrying a
         character invites the model to copy that character into shots she does
         not belong in — the with-scooter concept is kept as a look guide only.

         TWO MASTER ANGLES, matched pair, author 2026-08-27 — the ROUGH build:
           SET-ROAD-01_author_MASTER_ramp_rough.png     — facing the ramp; wall LEFT, posts RIGHT
           SET-ROAD-01_author_MASTER_reverse_rough.png  — facing away;    wall RIGHT, posts LEFT
         The boards are hand-laid salvage: different lengths, butted joins, open
         seams, split ends, nail heads. These supersede the neat clean pair, which
         read as manufactured boardwalk. The domovoi built this road themselves.
         Bound here is the ramp angle. Shots travelling AWAY from the ramp take
         the reverse plate as their start frame instead. Getting this backwards
         flips the road under the characters mid-chase. */
      refPath: "SET-ROAD-01_author_MASTER_ramp_rough.png",
    })
  | Tank =>
    Described({
      tag: "@TANK",
      tagLine: "@TANK: a large metal tank, brand new and clean — bright unscratched metal with a bright rim, no rust, no dents and no staining. It arrives inverted, mouth down, and drops over its captive. NO APPROVED REFERENCE YET — build from this description only.",
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
  | Frosya | FrosyaPencil => "FROSYA"
  | VasyaNoFace | Vasya | VasyaPouch => "VASYA"
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
  | Frosya | FrosyaPencil => Some("Фрося")
  | VasyaNoFace | Vasya | VasyaPouch => Some("Вася")
  | Mama => Some("Мама")
  | Papa => Some("Папа")
  | Rusya => Some("Руся")
  | Musya => Some("Муся")
  | YagaFlight | YagaDomovoy => Some("Яга")
  | VasyaMama => Some("Вася-мама")
  | VasyaCat | VasyaWasp | Babies => None
  }

/* WHAT TO CALL SOMEBODY WHEN NO REFERENCE WAS SENT. 2026-08-30.
   "@FROSYA" is an instruction to match reference image one. On Kling and Veo
   there is no reference image one, so the tag points at nothing and the model
   is left to guess what the token means. Identity on those calls comes from the
   start frame, so the prompt should just say who is in it in plain words. */
let castPlainNoun = (t: castToken): string =>
  switch t {
  | Frosya | FrosyaPencil => "the girl"
  | VasyaNoFace | Vasya | VasyaPouch | VasyaCat | VasyaWasp => "the boy"
  | Mama | VasyaMama => "the woman"
  | Papa => "the man"
  | Rusya | Musya => "the baby"
  | Babies => "the babies"
  | YagaFlight | YagaDomovoy => "the old woman"
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
  | Frosya | FrosyaPencil => Some("Everyone here is tiny. Фрося is 3.50 in / 8.9 cm and is the unit.")
  | VasyaNoFace | Vasya | VasyaPouch => Some("Вася is a head shorter than Мама — the top of his head reaches about her chin.")
  | Mama => Some("Мама is a little taller than Фрося.")
  | Papa => Some("Папа is the tallest, about a head above Мама.")
  | Babies => Some("@BABIES are far smaller: РУСЯ about 1.9 in, and МУСЯ smaller still — each fits along one of @MAMA's forearms.")
  /* Sized against the adults, not against Фрося — she is usually not in the
     shots the babies share with Мама, and an absent anchor is filtered out
     anyway (2026-08-26). Registry: babies 4.32cm, Мама 9.91cm — knee-to-waist. */
  /* No text anchor for the babies: in every shot they share with an adult they
     are already IN the start frame at their size, and a sentence against either
     woman is a second anchor competing with the picture (author, 2026-08-26:
     "let the model figure it out since the start frame already has their
     size"). The one relation kept is baby-to-baby, which no plate states. */
  | Rusya => None
  | Musya => Some("Муся the baby is a little smaller than the other baby.")
  | YagaDomovoy => Some("@YAGA at house-spirit size stands about 3.60 in / 9.1 cm — the same order as the parents, never towering over them.")
  | YagaFlight => Some("@YAGA in human flight form stands about 147 cm — SIXTEEN TIMES the family's size. She is a full-grown human woman here.")
  /* SIZE IS ONLY EVER RELATIVE TO A CHILD. "A little longer than @VASYA is tall" is
     both a measurement nobody can act on and the wrong answer: the point of the beat
     is that a cat is GIGANTIC beside a house spirit, which is what lets one lying down
     shut a road. Author, 2026-09-03: "we don't care about them being three and a half
     inches. The only thing we care about is that this cat is gigantic in comparison to
     her." */
  | VasyaCat => Some("@VASYA_CAT is GIGANTIC beside the children — lying flat he is longer than @FROSYA is tall, and his shoulder stands higher than her chest.")
  | VasyaWasp => Some("@VASYA_WASP is a wasp at house-spirit scale, small enough to fly through a gap in the floorboards.")
  /* CORRECTED 2026-08-26. This said she is "a head taller than Фрося", while
     МАМА's own line says she is only "a little taller than Фрося". Read
     together those two sentences tell the model the pair are DIFFERENT heights,
     and they never state the one fact that matters when both are in frame: the
     two of them are identical. v09rescue came back with Мама visibly towering
     over him — the author: "he's definitely Vasya's height, and she's an adult
     woman's height." The comparison to Фрося is dropped; the identity is stated
     directly, because that is what the shot is actually about. */
  /* CORRECTED AGAIN 2026-08-26. The previous version anchored her to "a grown
     woman's full height" AS WELL AS to @MAMA. Those are two anchors and the
     outside one won: @MAMA walked in at full size beside a figure the start
     plate had already drawn small, and towered. The author: "I don't care if
     they're huge as long as when two mamas are in the shot, the two women are
     the same height." So there is now ONE anchor and it is each other. */
  | VasyaMama => Some("@VASYA_MAMA and @MAMA are TWINS: identical in height, build and dress, head tops level side by side, differing only in their faces — as @TWO_MAMAS shows them.")
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
  /* NO SCALE LINE. The plate shows the scooter standing on these boards beside a
     kneeling Фрося, so its size is settled by a picture. Three attempts to say
     it in words — against Вася who was not in the shot, then against a standing
     child who does not exist until the next shot, then against her kneeling head
     — were all worse than the image. */
  | VasyaArm | FloorTopdown | RoadWall => None
  | ScooterPlaced => None
  /* NO SCALE LINE FOR THE SCOOTER. The plate shows it standing on these boards
     at its size, so the size is settled by a picture. Three attempts to say it
     in words — against Вася who was not in the shot, then against a standing
     child who does not exist until the next shot, then against her kneeling head
     — were each worse than the image, and the last of them was still sitting in
     the prompt after I wrote a comment claiming I had removed it. */
  | Scooter | ScooterCutout => None
  | RoomFrontLow | RoomFrontHatch | RoomBack | SeatingScene5 | Carry | Roof | Door | Tiles | Pouch | Road | Tank | Thread | Cake | Juice | Salad | Poppy | FloorAfter | TwoMamas | RoadPlate => None
  }

/* The creative text may not smuggle tag lines past the emitter: any "@" is a
   build-the-record-properly error, caught before money. */
/* CHOREOGRAPHY REFERS TO ACTORS BY TAG. 2026-08-26, the author: "Why are you
   saying the second woman when it should be just tagged as mama?" Right — the
   tags exist to kill ambiguity, and prose like "the new woman" reintroduces
   it. So @tags are now REQUIRED vocabulary in the creative, with one rule: a
   creative may only use the tags of the cast and props actually bound to the
   job. An unknown tag is still the old error — it means the record is wrong,
   not the prose. (Dialogue headers and spoken lines stay Cyrillic: the Frosha
   incident showed Latin spellings next to Russian lines poison the phonetics,
   and tags never appear inside anything spoken.) */
let assertCreativeClean = (r: shotRecord): unit => {
  let allowed = Belt.Array.concat(
    r.cast->Belt.Array.map(t => castEntry(t).tag),
    r.props->Belt.Array.map(propTag),
  )
  let re = %re("/@[A-Z_]+/g")
  let found = switch Js.String2.match_(r.creative, re) {
  | None => []
  | Some(m) => m->Belt.Array.keepMap(x => x)
  }
  found->Belt.Array.forEach(tag =>
    if !(allowed->Belt.Array.some(a => a == tag)) {
      raise(
        BatchError(
          r.jobId ++
          ": creative uses " ++
          tag ++
          " which is not bound to this job. Bind it in the job record or fix the tag.",
        ),
      )
    }
  )
}

/* A Latin-spelled character name sitting next to a Russian line gets SPOKEN in
   English phonetics — the clip where Папа said "Frosha" was generated from a
   prompt that was 2.4% Cyrillic and spelled her name "FROSYA" twice against
   «Фрося» once. The dominant spelling wins. Character names in the choreography
   are Cyrillic; the Latin form survives only as the @TAG handle, which is bound
   to the Cyrillic name inside the tag line itself. */
let latinCastNames = ["FROSYA", "VASYA", "MAMA", "PAPA", "YAGA", "Frosya", "Vasya", "Mama", "Papa", "Yaga"]

/* Tags are exempt: since 2026-08-26 the choreography is REQUIRED to refer to
   actors as @VASYA_MAMA etc., so the scan runs on the creative with every
   @TAG removed. What remains must be Cyrillic. */
let assertCyrillicNames = (r: shotRecord): unit => {
  let detagged = Js.String2.unsafeReplaceBy0(r.creative, %re("/@[A-Z_]+/g"), (_, _, _) => "")
  latinCastNames->Belt.Array.forEach(n =>
    if Js.String2.includes(detagged, n) {
      raise(
        BatchError(
          r.jobId ++
          ": choreography spells a character name in Latin (\"" ++
          n ++
          "\") — next to a Russian line that gets spoken in English phonetics. Use the Cyrillic name (tags like @VASYA_MAMA are exempt).",
        ),
      )
    }
  )
}

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
/* THE BANNED-WORD SCAN RUNS ON THE FINISHED PROMPT, NOT ONLY THE CREATIVE.
   2026-08-26: v09rescue take 4 was rejected nsfw and charged 35 credits on the
   words "mid-thigh" — written not in the creative, which the gate scans, but in
   the castScale table, which it never saw. Any assembly path can smuggle a word
   in, so the last check before money runs on the exact string the model gets. */
/* Shots DELIVERED before a word joined this list are not re-judged by it —
   the same precedent as emotionGateGrandfathered. "thigh" (singular) joined
   2026-08-26 after v09rescue take 4; v07table, already rendered and in the
   cut, says "planted on his thigh" and stays as shot. */
let bodyStateGrandfathered = ["v07table", "v08babies"]

let bodyStateWords = [
  "barefoot", "bare feet", "bare legs", "bare arms", "bare skin", "naked", "undressed",
  "thigh", "thighs", "belly", "diaper", "nappy", "bare chested", "shirtless",
]

let assertEmittedClean = (jobId: string, prompt: string): unit => {
  let lower = Js.String2.toLowerCase(prompt)
  bodyStateGrandfathered->Belt.Array.some(j => j == jobId)
    ? ()
    : bodyStateWords->Belt.Array.forEach(w =>
    if Js.String2.includes(lower, w) {
      raise(
        BatchError(
          jobId ++
          ": the EMITTED prompt contains \"" ++
          w ++
          "\" — it reached the final text through a table or template, not the creative. This is the class of word that gets a job rejected nsfw and still charged.",
        ),
      )
    }
  )
}

/* B7 — a NEGATED SCREEN DIRECTION. "at no point does she turn to the LEFT of
   frame" hands the model the word LEFT and asks it not to think of it, which is
   the one thing it cannot do. A direction is stated as the RANGE the movement
   covers — where it starts, how far it goes, where it stops — never as the side
   it stays off. Author, 2026-08-26. See also the sheet-beats-negation law: a
   reference image outranks a prohibition, and a positive instruction of the same
   kind is what displaces one. */
let negatedDirection = %re("/\b(never|not|no|nobody|nothing|at no point)\b[^.;—]{0,60}\b(left|right)\b[ -]*(of frame|of the frame|edge|side of frame|hand side)/i")

/* B8 — a NEGATED PERFORMANCE. "she does not giggle" is the only thing in a
   prompt that puts giggling anywhere near it: the model never saw the shot this
   language was inherited from, so the negation supplies the very idea it means
   to exclude. Author, 2026-08-28: "are you putting negative statements into your
   prompt based on the context of the previous prompt? Are you doing this stuff
   when the model has no idea what the previous prompt was?"

   This happens because creatives are copied from the shot before — the right
   thing to do — and a behaviour that belonged there gets negated instead of
   replaced. The fix is always to write what she IS doing in that space.

   THIS WARNS, IT DOES NOT REFUSE — and that is a finding, not a compromise.
   Fire-testing it as a blocker flagged THIRTEEN shipped creatives, including the
   shot it was written for. "she is never angry, never crying and never smiling
   at the end" is the same grammatical shape as "she does not giggle", and it is
   the established EMOTION LOCK: the gate that demands a declared emotion also
   expects its contradictions named, and МАК, v09 and v10 all carry a version of
   it. Those shots delivered. The difference between a negated inherited
   behaviour and a bounded emotion lock is intent, and intent is not in the text.

   So this prints and a person decides. A blocker here would refuse thirteen
   creatives that demonstrably work in order to catch one that probably did no
   harm. */
let negatedPerformance = %re("/\b(?:does not|doesn't|never|is not|isn't|no longer)\s+(?:[a-z]+ly\s+)?(giggl\w*|laugh\w*|smil\w*|grin\w*|cry\w*|cries|frown\w*|shout\w*|scream\w*|blink\w*|nod\w*|wave\w*|point\w*|dance\w*|jump\w*|clap\w*)/i")

let assertNoNegatedPerformance = (jobId: string, prompt: string): unit =>
  switch Js.Re.exec_(negatedPerformance, prompt) {
  | Some(m) =>
    let hit = switch Js.Nullable.toOption(Js.Array2.unsafe_get(Js.Re.captures(m), 0)) {
    | Some(t) => t
    | None => "a negated performance"
    }
    Js.log(
      "  WARN  " ++
      jobId ++
      ": the prompt negates a performance — \"" ++
      hit ++
      "\". If that behaviour was inherited from the shot this creative was copied from, the model never saw it, and this line is the only place the idea appears. Write what she IS doing in that space. If it is the emotion lock naming a declared emotion's contradictions, it is fine.",
    )
  | None => ()
  }

let assertNoNegatedDirection = (jobId: string, prompt: string): unit =>
  switch Js.Re.exec_(negatedDirection, prompt) {
  | Some(m) =>
    let hit = switch Js.Nullable.toOption(Js.Array2.unsafe_get(Js.Re.captures(m), 0)) {
    | Some(t) => t
    | None => "a negated direction"
    }
    raise(
      BatchError(
        jobId ++
        ": the prompt forbids a screen direction — \"" ++
        hit ++
        "\". Naming the side she must avoid puts that side in front of the model. State the RANGE instead: where the turn starts, how far it goes, and where it stops.",
      ),
    )
  | None => ()
  }

let assertEmittedBudget = (jobId: string, prompt: string): unit =>
  /* v08babies was shot at 9279 chars; the 2026-08-26 tagline rewrite grew its
     re-emission past the ceiling. It is delivered and will not be resubmitted. */
  if jobId != "v08babies" && Js.String2.length(prompt) > 9400 {
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
        /* A SPELLING-OUT IS NOT A WORD. «М-А-Ш-И-Н-А» is six letters named one
           at a time, exactly as «С-О-К» and «М-А-К» were in the delivered shots.
           There is no stress in it to mark, because it is never pronounced as a
           word — the word follows it, separately, and that one does get marked.
           Detected as: every hyphen-separated piece is a single letter. */
        let isSpellingOut = {
          let parts = Js.String2.split(w, "-")
          Belt.Array.length(parts) >= 2 &&
            parts->Belt.Array.every(p => Js.String2.length(p) == 1)
        }
        if vowels >= 2 && !marked && !hasYo && !isSpellingOut {
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

let assertNoBodyState = (r: shotRecord): unit =>
  bodyStateGrandfathered->Belt.Array.some(j => j == r.jobId)
    ? ()
    : bodyStateWords->Belt.Array.forEach(w =>
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

/* WHETHER THE CALL ACTUALLY CARRIES REFERENCE IMAGES. 2026-08-30.
   Kling and Veo take none. Handing them an ACTIVE REFERENCES block describes a
   face in prose and then tells the model to match a sheet it was never sent —
   which is an invitation to invent one, and pure noise on a shot that never
   shows the face at all. Seedance gets the block because Seedance gets the
   images. */
let emitPrompt = (r: shotRecord, ~refsSent: bool=true, ()): string => {
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
  /* @TWO_MAMAS is a relation card, not a thing standing in the room — calling
     it "the set and props" produced a nonsense sentence in the constraints
     (caught in the 2026-08-26 review pass). Cards are excluded here. */
  let physicalProps = r.props->Belt.Array.keep(t =>
    switch t {
    | TwoMamas => false
    | _ => true
    }
  )
  let propRoster = physicalProps->Belt.Array.map(propTag)->Js.Array2.joinWith(", ")
  let propClause = switch Belt.Array.length(physicalProps) {
  | 0 => ""
  | _ => " The set and props are " ++ propRoster ++ ", and each matches its reference exactly."
  }
  let matchClause = refsSent ? " Every character matches their reference exactly." : ""
  /* IT RESTATED THE REFERENCE LIST IN LONGHAND, directly under the reference list.
     "Every character matches their reference exactly" says nothing the "100% matches
     the reference" on each line above has not already said. What only this block adds
     is the closed roster and the no-text rule. */
  /* "No text" IN A SHOT WHOSE SUBJECT IS LETTERS. The clause is meant to keep captions
     and watermarks out, but on the tile shots it points straight at the one thing that
     has to survive — and the author is not repainting them. Dropped wherever the
     choreography has a GLYPHS block.
     And an empty roster printed "ONLY ." on a job with no cast, only hands. */
  let hasGlyphs = Js.String2.includes(r.creative, "\nGLYPHS")
  /* A CLOSED ROSTER AND A WARNING AGAINST TWINS ARE BOTH POINTLESS WITH ONE CHARACTER.
     Author, 2026-09-03, reading it on a shot that shows nothing but forearms: "what the
     hell is that?" Fair — it guards against a problem that cannot arise. The subtitle
     clause stays: models do burn captions in, and on the tile shots that lands on top
     of the letters. */
  let single = Belt.Array.length(r.cast) <= 1
  let tail =
    (single ? "" : " No duplicates.") ++
    (hasGlyphs ? " No subtitles, no watermarks." : " No text, no subtitles, no watermarks.")
  let constraints =
    (roster == "" || single ? "" : "ONLY " ++ roster ++ ".") ++
    /* IT NAMED THE BABIES IN EVERY PROMPT THE SHOW HAS EVER SENT, including every
       shot they are nowhere near. Author, 2026-09-02: "you cannot just attach
       something about no additional babies." Right — by the rule @ROAD just proved,
       naming a thing you do not want is how you get it, and the roster clause above
       already says exactly who is in the shot and nobody else. */
    tail
  /* A SCALE LINE MAY NOT ANCHOR TO SOMEBODY WHO IS NOT IN THE SHOT. 2026-08-26.
     Most of these lines are written against Фрося, because she is the unit of
     the scale registry. That is production knowledge; it is useless to a model
     that cannot see her, and it is worse than useless when it competes with an
     anchor that IS visible. v09rescue told the model that the two women match
     each other AND that Мама is "a little taller than Фрося" — two anchors, one
     of them invisible, and the pair came out different heights. So any cast
     scale line naming an absent character is dropped. */
  let presentNames = r.cast->Belt.Array.keepMap(castRuName)
  let allNames = [
    "Фрося", "Вася", "Мама", "Папа", "Руся", "Муся", "Яга", "Вася-мама",
  ]
  let absentNames = allNames->Belt.Array.keep(n =>
    !(presentNames->Belt.Array.some(p => p == n))
  )
  let keepScale = (line: string) =>
    !(absentNames->Belt.Array.some(n => Js.String2.includes(line, n)))
  /* THE FILTER HAS TO COVER PROPS AS WELL. 2026-08-30. It was written for cast
     lines after v09rescue sized Мама against an invisible Фрося and the two
     women came back different heights — but props were never passed through it,
     so @SCOOTER went out sized against @VASYA in a shot he is not in. A prop
     measured against somebody the model cannot see is a prop with no size at
     all. Author caught it: "is there a chance that it's gonna render a tiny
     scooter?" */
  let scaleLines = Belt.Array.concat(
    r.cast->Belt.Array.keepMap(castScale)->Belt.Array.keep(keepScale),
    r.props->Belt.Array.keepMap(propScale)->Belt.Array.keep(keepScale),
  )
  /* A SCALE BLOCK WITH NOTHING TO COMPARE IS DEAD WEIGHT. 2026-08-30. These
     lines exist so two things in one frame come out the right size relative to
     each other. One character alone with no prop in shot has no second thing,
     so the block says only how many centimetres she is — which the model cannot
     act on and which SH144 spent 108 words carrying. */
  /* AND A BLOCKOUT CARRIES SCALE BETTER THAN A SENTENCE CAN. Author, 2026-09-02:
     "you cannot attach the scale line. The scale line does not apply here. The
     blocking carries the scale." A previz frame shows both children standing in the
     set at their built heights; centimetres in prose can only argue with it. */
  let hasBlockout =
    (Js.String2.includes(r.creative, "\nBLOCKOUT") || Js.String2.includes(r.creative, "\nVIDEO REFERENCE")) || Belt.Option.isSome(r.startImage)
  let nothingToCompare =
    hasBlockout || (Belt.Array.length(r.cast) <= 1 && Belt.Array.length(r.props) == 0)
  let scaleBlock = switch (Belt.Array.length(scaleLines), nothingToCompare) {
  | (0, _) | (_, true) => ""
  | _ => "SCALE\n" ++ scaleLines->Js.Array2.joinWith("\n") ++ "\n\n"
  }
  /* AND NO EMPTY HEADER. A job driven by a start frame and a motion reference binds no
     image references at all, and the block printed its title over nothing. */
  let refBlock = refsSent && Belt.Array.length(Belt.Array.concat(castLines, propLines)) > 0
    ? "ACTIVE REFERENCES\n" ++
      Belt.Array.concat(castLines, propLines)->Js.Array2.joinWith("\n") ++
      "\n\n"
    : ""
  /* SOURCE IS PROVENANCE, NOT DIRECTION. 2026-08-30. It carries a script line
     number and a shot code so the gates and the author can trace a prompt back
     to the page. The model has no script and no shot list; the block is pure
     noise to it, and when it carried a stage direction it destroyed SH144. It
     stays in the creative file and never reaches the call. */
  let body = {
    let c = r.creative
    let padded = "\n" ++ c
    if Js.String2.includes(padded, "\nSOURCE") {
      let after = Belt.Array.getExn(Js.String2.split(padded, "\nSOURCE"), 1)
      switch Js.String2.split(after, "\n\n")->Belt.Array.get(1) {
      | Some(_) =>
        let parts = Js.String2.split(after, "\n\n")
        Js.Array2.joinWith(Belt.Array.sliceToEnd(parts, 1), "\n\n")
      | None => c
      }
    } else {
      c
    }
  }
  let assembled =
    refBlock ++
    scaleBlock ++
    body ++
    "\n\n" ++
    constraints
  /* The tag has to go everywhere or nowhere. POSITIVE CONSTRAINTS is built from
     the roster, not from the choreography, so substituting only the body left
     "@FROSYA" sitting in the last line of a call that carries no references. */
  let prompt = refsSent
    ? assembled
    : r.cast->Belt.Array.reduce(assembled, (acc, t) =>
        Js.String2.replaceByRe(acc, Js.Re.fromStringWithFlags("@" ++ castName(t), ~flags="g"), castPlainNoun(t))
      )
  assertEmittedBudget(r.jobId, prompt)
  assertEmittedClean(r.jobId, prompt)
  assertNoNegatedDirection(r.jobId, prompt)
  assertNoNegatedPerformance(r.jobId, prompt)
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
