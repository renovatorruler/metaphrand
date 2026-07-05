/* The SKY KING cast registry — each character's canonical turnaround sheet in ONE
   typed place, so scene generation pulls the right reference from the flow rather
   than ad-hoc per-shot. Birdy = the new gpt-image-2 sheet; Maya / Dez = their
   existing sheets; Bishop has no sheet yet (radio voice, not on screen in the
   cold open) — add one when he first appears. */

type character = {name: string, sheet: Cinema_Backends.path}

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let sheet = n => Cinema_Backends.Path(dir ++ "/sheets/" ++ n)

let birdy = {name: "BIRDY", sheet: sheet("birdy_sheet_gpt2.png")}
let maya = {name: "MAYA", sheet: sheet("maya_turnaround.png")}
let dez = {name: "DEZ", sheet: sheet("dez_turnaround.png")}

let cast = [birdy, maya, dez]

let sheetFor = (name: string): option<Cinema_Backends.path> =>
  cast->Belt.Array.getBy(c => c.name == name)->Belt.Option.map(c => c.sheet)

/* generate a scene still IN THE FLOW: every character present supplies their
   sheet as a canon reference; Cinema_Frames adds the face-lock + the original-
   likeness guard, and renders through gpt-image-2. */
let frame = async (~desc: string, ~present: array<string>, ~out: Cinema_Backends.path) => {
  let refs = present->Belt.Array.keepMap(sheetFor)
  await Cinema_Frames.shot(
    ~prompt=Cinema_Frames.Description(desc),
    ~out,
    ~refs,
    ~register=Cinema_Frames.Photoreal,
    ~faceLock=true,
    ~avoid=[Cinema_Frames.ActorName("Richard Russell")],
  )
}
