/* See Cinema_Frames.resi for the contract. Prompt assembly only; every external
   call (the image bytes, the PNG write) goes through Cinema_Backends.
   Standardized on gpt-image-2 (imageGpt2) — the chosen model for places + people. */

@unboxed type description = Description(string)
@unboxed type actorName = ActorName(string)

type register = Photoreal | Storyboard

let photoreal =
  "A photorealistic cinematic film still, naturalistic light, shallow depth of field, " ++
  "fine grain, the look of 35mm film. "
let storyboard =
  "Film storyboard illustration: loose confident graphite pencil and charcoal on " ++
  "off-white paper, monochrome, cinematic widescreen, expressive, NO text anywhere. "
let condition =
  " Use the attached reference images as canon: the character turnaround sheets fix each " ++
  "person's face, hair and wardrobe — reproduce them EXACTLY; any attached location frame " ++
  "or gray 3D clay fixes the geography and camera — match it precisely. Keep everything " ++
  "consistent. No drawing, no border."

/* Commercial-use face lock. Tight shots invent the most face pixels and drift to
   the nearest famous actor the model knows; this makes the original-likeness
   demand non-negotiable. */
let faceLockStr =
  " CRITICAL — COMMERCIAL LIKENESS: this person must be an ORIGINAL individual who matches " ++
  "the attached turnaround and wider frame EXACTLY — same age, same face shape, same " ++
  "hairline, same build. He must NOT resemble any real, famous or recognizable actor or " ++
  "public figure. If the rendered face reads as a known actor, it is WRONG and unusable. " ++
  "An original, clearable likeness is required."

let head = (r: register): string =>
  switch r {
  | Photoreal => photoreal
  | Storyboard => storyboard
  }

let locationMaster = async (
  ~description: description,
  ~out: Cinema_Backends.path,
  ~register: register,
): Cinema_Backends.path => {
  let Description(d) = description
  let prompt = head(register) ++ d ++ " Establishing wide of the empty location, no people."
  let bytes = await Cinema_Backends.imageGpt2(~prompt=Cinema_Backends.Prompt(prompt), ~refs=[])
  Cinema_Backends.writeBytes(out, bytes)
}

let shot = async (
  ~prompt: description,
  ~out: Cinema_Backends.path,
  ~refs: array<Cinema_Backends.path>,
  ~register: register,
  ~faceLock: bool,
  ~avoid: array<actorName>,
): Cinema_Backends.path => {
  let Description(p) = prompt
  let withCond = head(register) ++ p ++ (Array.length(refs) > 0 ? condition : "")
  let full = if faceLock {
    let av =
      Array.length(avoid) > 0
        ? " Specifically do NOT resemble: " ++
          Js.Array2.joinWith(Belt.Array.map(avoid, (ActorName(a)) => a), ", ") ++ "."
        : ""
    withCond ++ faceLockStr ++ av
  } else {
    withCond
  }
  let bytes = await Cinema_Backends.imageGpt2(~prompt=Cinema_Backends.Prompt(full), ~refs)
  Cinema_Backends.writeBytes(out, bytes)
}
