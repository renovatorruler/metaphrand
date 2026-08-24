/* Bhopa_Thumb.res — the prompt law for BhopaMusic channel artwork.

   A thumbnail is not a frame from a film; it is a poster. This module renders
   poster prompts deterministically from a typed spec, the same discipline the
   Kuku pipeline uses, so the channel's look cannot drift from one upload to the
   next: one lamp-light source, folk-art palette, big graphic shapes, and a dark
   quiet zone reserved for the title that gets composited locally (never
   generated, so Devanagari is always correctly formed).

   Run from studio/: node src/Bhopa_Thumb.res.mjs [concept] [--go] */

@module("fs") external existsSync: string => bool = "existsSync"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

type titleZone = LowerLeft | LowerRight | UpperLeft | NoTitle_CircleSafe

type posterSpec = {
  concept: string, /* the one thing the poster is of */
  subject: string, /* who or what carries the frame */
  ground: string, /* what is behind them */
  keyLight: string, /* the single source */
  palette: string,
  graphic: string, /* how it reads at thumbnail size */
  zone: titleZone,
  extraRules: array<string>,
}

let zoneProse = z =>
  switch z {
  | LowerLeft => "the LOWER LEFT third of the frame is deliberately dark and empty — no detail, no bright shapes there; a title will be placed on it later"
  | LowerRight => "the LOWER RIGHT third of the frame is deliberately dark and empty — no detail, no bright shapes there; a title will be placed on it later"
  | UpperLeft => "the UPPER LEFT third of the frame is deliberately dark and empty — no detail, no bright shapes there; a title will be placed on it later"
  | NoTitle_CircleSafe => "SQUARE 1:1. This will be cropped to a CIRCLE and shown as small as a fingernail: centre the figure, keep every important shape well inside the middle circle, leave the four corners empty, and carry no text at all"
  }

/* laws every BhopaMusic poster obeys */
let thumbnailLaw = [
  "KEEP THE CHANNEL WIDE: never narrow it with a genre or subject label — no 'devotional', no 'deities', no 'songs for/about X'. The only approved line beneath the name is the author's: SONGS FROM THE FOLK, which describes where the music comes from rather than what it is about",
  "any type placed on this art must be LARGE: the main line at least a tenth of the frame height, set on a plainly darker or plainly lighter ground, legible at a glance on a phone",
  "it must read instantly at the size of a postage stamp: one clear subject, one light source, big simple shapes, no fussy detail",
  "strong tonal separation — the subject is clearly brighter or darker than everything behind it",
  "no letters, no words, no numbers, no script of any kind anywhere in the image; the title is added afterwards",
  "no borders, no frames, no vignetting drawn into the picture, no watermark, no logo",
  "no modern clothing, no plastic, no electric signage, nothing contemporary in shot",
  "not a photograph of a screen, not a collage, not a poster-within-a-poster",
]

let bullets = xs => Js.Array2.joinWith(Js.Array2.map(xs, x => "- " ++ x), "\n")

/* our singer's fixed identity — the shapes that make his outline HIS.
   The कलगी was lost from the first avatar because it was never named here. */
let safaLaw = "he wears the साफा — the Rajasthani turban, tall and wrapped in bands, with its long tail (शमला) falling and flying back from the nape — and rising from the FRONT of its crown stands the कलगी: an upright plume ornament, a narrow spray that springs up and arcs slightly back, clearly separated against the light so it is unmistakable in outline. The kalgi is never omitted."

let posterPrompt = (p: posterSpec) =>
  Js.Array2.joinWith(
    [
      p.zone == NoTitle_CircleSafe
        ? "A single striking channel emblem. SQUARE 1:1, full-bleed."
        : "A single striking piece of cover artwork. LANDSCAPE 16:9, full-bleed, the camera is inside the world.",
      "CONCEPT: " ++ p.concept,
      "SUBJECT: " ++ p.subject,
      "BEHIND: " ++ p.ground,
      "LIGHT: " ++ p.keyLight,
      "PALETTE: " ++ p.palette,
      "HOW IT READS: " ++ p.graphic,
      "COMPOSITION: " ++ zoneProse(p.zone),
      "THE SINGER: " ++ safaLaw,
      "HARD RULES:\n" ++ bullets(Js.Array2.concat(thumbnailLaw, p.extraRules)),
    ],
    "\n",
  )

/* --- the concepts ---------------------------------------------------------- */
let phadNight: posterSpec = {
  concept: "the bhopa — the bardic singer-priest of the folk deities — performing at night in front of his phad, the long painted cloth scroll that holds the god's whole story.",
  subject: "an old Rajasthani bhopa seen from the side, eyes closed, mouth open mid-song, holding up his डफ — a large round frame drum with a single skin head and a shallow wooden rim — in front of his chest, his other hand caught mid-strike against the skin; a worn red thread is knotted at his wrist. He is a dark rim-lit silhouette against the glowing cloth, and the two clearest shapes in the frame are his turban and the drum's big circle.",
  ground: "an enormous hand-painted phad scroll filling the whole background, its folk-art figures — horses, riders, small deities in flat vermillion, ochre, indigo and leaf-green — packed edge to edge and slightly out of focus, so it reads as a wall of colour rather than as pictures.",
  keyLight: "one small oil lamp held low and out of frame, throwing warm gold up onto the scroll and rimming the singer's face and hands; everything beyond that pool of light falls into deep indigo darkness.",
  palette: "deep indigo night against hot vermillion and turmeric gold, with a single note of the red thread; saturated folk-art colour, never pastel, never muted",
  graphic: "at a glance: a black singing profile with a big black circle held at its chest, standing on a burning wall of red and gold",
  zone: LowerLeft,
  extraRules: [
    "the instrument is a डफ / daf — a large round frame drum struck with the bare hand; there is NO bow, no strings, no neck, no violin, no sitar anywhere in the picture",
    "the phad's painted figures must stay abstract and blurred — never legible scenes, never readable panels",
  ],
}

let threadTree: posterSpec = {
  concept: "the vow-tree: a shrine tree so thickly bound with red threads that the bark has disappeared, one small hand tying another.",
  subject: "a single weathered hand at the moment of knotting a fresh red thread, lit hot against the dark, the fingers big in frame",
  ground: "the trunk behind, wrapped in thousands of red vow-threads, receding into darkness",
  keyLight: "a low warm lamp close to the hand; the depth of the tree unlit",
  palette: "near-black ground, one blaze of vermillion, warm skin tones",
  graphic: "at a glance: a burst of red thread with a hand in it",
  zone: LowerRight,
  extraRules: [],
}

let dafSilhouette: posterSpec = {
  concept: "the channel's emblem: our singer, in pure silhouette, striking his डफ — the round frame drum — inside a burning disc of evening light.",
  subject: "the singer from the attached photograph, rendered as a SOLID BLACK SILHOUETTE with no interior detail whatsoever — no face, no eyes, no fabric folds, only his outline. He is turned slightly to one side, chin lifted mid-song, the great round frame drum held up in front of his chest and his other hand caught mid-strike against its skin. His outline must be unmistakably his: the साफा with its कलगी standing up from the crown and its long tail flying back, the strong moustache in profile, the loose kurta, and the drum's small hanging pom-poms breaking its lower edge.",
  ground: "one enormous glowing disc filling most of the square — the low sun of a dust evening — its centre hot gold, its edge deepening to vermillion and then to a near-black surround. Nothing else: no landscape, no buildings, no crowd, no ground line.",
  keyLight: "the disc itself is the only light; the figure is entirely backlit so that not one detail of his front is visible, with a whisper of hot rim-light along the turban and the drum's rim",
  palette: "molten gold and vermillion against a near-black figure and a near-black surround; three tones only",
  graphic: "at a fingernail's size: a black man-shape with a black circle at his chest, on a burning orange disc — a single unmistakable emblem",
  zone: NoTitle_CircleSafe,
  extraRules: [
    "the drum is a डफ / daf — a large round frame drum with a single skin head and a shallow wooden rim, held upright in the hands; never a tabla, never a dholak, never a tambourine with jingles",
    "the silhouette is filled solid — no visible facial features, no printed pattern, no texture inside the black",
    "the drum's disc must stay clearly separate from the sun's disc — never overlapping its centre, so both circles read",
  ],
}

/* the channel banner. YouTube crops it viciously: TV sees the whole 2048x1152,
   desktop a middle band, phones only a 1235x338 strip through the centre. So the
   art is composed as a WIDE panorama whose centre band is deliberately quiet. */
let bannerPanorama: posterSpec = {
  concept: "a wide panorama of the singer's world at dusk: the desert horizon, the burning sun, and the singer walking it with his डफ.",
  subject: "far to the RIGHT of frame, small against the sky, the singer walks in solid black silhouette with his round frame drum at his side and his कलगी and turban tail sharp against the light — a lone figure, never large, never centred",
  ground: "an immense flat dust-plain horizon running the full width of the frame under a vast graded sky; a huge low sun sits on the LEFT, its disc molten gold; a few tiny far-off shrine flags and one bare thorn tree break the horizon line",
  keyLight: "the setting sun on the left, throwing a long low wash across the plain and rimming everything it touches; the sky darkening to deep indigo at the top corners",
  palette: "molten gold and vermillion along the horizon, deep indigo above, everything on the ground reduced to black",
  graphic: "at a glance across a wide strip: a burning horizon with one small walking figure — calm, not busy",
  zone: NoTitle_CircleSafe,
  extraRules: [
    "the CENTRE of the frame must stay open and simple — plain sky and horizon only, no figure, no tree, no sun there; a channel name will be placed across it",
    "the composition must survive being cropped to a narrow horizontal strip through the middle: nothing important may sit near the top or bottom edges",
    "the drum is a डफ — a large round frame drum with a single skin; never a tabla, never a dholak",
  ],
}

let concepts = [("phad_night", phadNight), ("thread_tree", threadTree), ("daf_silhouette", dafSilhouette), ("banner", bannerPanorama)]

let outDir = "../stories/songbook/kark-mv/thumbs/"
let opts = {"encoding": "utf8", "timeout": 900000}

let retouchPrompt = change =>
  Js.Array2.joinWith(
    [
      "TASK: edit the attached artwork — apply ONLY the change below.",
      "CHANGE: " ++ change,
      "KEEP:\n" ++
      bullets([
        "the identical composition, framing and scale — nothing moves, nothing is re-posed",
        "the identical palette, glow and light direction",
        "the silhouette stays filled solid black with no interior detail",
        "the same drum, the same hands, the same turban tail",
      ]),
      "HARD RULES:\n" ++ bullets(thumbnailLaw),
    ],
    "\n",
  )

let which = Js.Array2.length(argv) > 2 ? argv[2] : "phad_night"
let go = Js.Array2.some(argv, a => a == "--go")

let retouch = Js.Array2.length(argv) > 3 && argv[3] == "--retouch"

if retouch {
  let src = outDir ++ "bhopa_" ++ which ++ ".png"
  let change = Js.Array2.length(argv) > 4 ? argv[4] : "Add the कलगी to the turban: an upright plume ornament rising from the FRONT of the crown of the safa, a narrow spray that springs upward and arcs slightly back, rendered in the same solid black as the rest of the silhouette and standing clear against the glowing disc so its shape is unmistakable. Change nothing else."
  let raw = execFileSync(
    "higgsfield",
    ["generate", "create", "nano_banana_pro", "--prompt", retouchPrompt(change), "--image", src,
     "--aspect_ratio", "1:1", "--resolution", "2k", "--wait", "--json"],
    opts,
  )
  switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(png|webp|jpg)")) {
  | Some(m) =>
    switch m[0] {
    | Some(url) => {
        let _ = execFileSync("cp", [src, outDir ++ "bhopa_" ++ which ++ "_PRE_KALGI.png"], opts)
        let _ = execFileSync("curl", ["-sL", "--retry", "3", "-o", src, url], opts)
        Js.log("retouched " ++ src)
      }
    | None => Js.log("no url")
    }
  | None => Js.log("FAIL retouch — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
  }
} else {
switch Js.Array2.find(concepts, ((n, _)) => n == which) {
| None => Js.log("unknown concept: " ++ which)
| Some((name, spec)) =>
  if !go {
    Js.log(posterPrompt(spec))
  } else {
    let dst = outDir ++ "bhopa_" ++ name ++ ".png"
    let singerRef = "../stories/songbook/kark-mv/atape/gpt_daf_mid.png"
    let square = spec.zone == NoTitle_CircleSafe && name != "banner"
    let refArgs = square && existsSync(singerRef) ? ["--image", singerRef] : []
    let raw = execFileSync(
      "higgsfield",
      Js.Array2.concat(
        Js.Array2.concat(
          ["generate", "create", "nano_banana_pro", "--prompt", posterPrompt(spec)],
          refArgs,
        ),
        ["--aspect_ratio", square ? "1:1" : "16:9", "--resolution", "2k", "--wait", "--json"],
      ),
      opts,
    )
    switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(png|webp|jpg)")) {
    | Some(m) =>
      switch m[0] {
      | Some(url) => {
          let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
          Js.log("saved " ++ dst)
        }
      | None => Js.log("no url")
      }
    | None => Js.log("FAIL — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
    }
  }
}
}
