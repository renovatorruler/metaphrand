/* ============================================================================
   Cinema_Frames — story-agnostic shot generation.

   A shot conditions on character TURNAROUND sheets (faces/wardrobe) and a
   LOCATION master (geography), in either register (photoreal or storyboard).
   Faces hold because every shot rides the same turnaround; the world holds
   because every shot rides the same location master. The image bytes come from
   Cinema_Backends; this module owns only the PROMPT assembly and the canon/
   face-lock conditioning strings.
   ============================================================================ */

@unboxed type description = Description(string) // what the shot/location depicts
@unboxed type actorName = ActorName(string)     // a real actor to negative-prompt away from

/* The visual register: a sum type, not a magic string — "storyboard" can never be
   misspelled into a silent pass-through. */
type register = Photoreal | Storyboard

/* One consistent establishing plate per location; every shot there conditions on
   it. Writes the PNG to `out`, returns it. */
let locationMaster: (
  ~description: description,
  ~out: Cinema_Backends.path,
  ~register: register,
) => promise<Cinema_Backends.path>

/* One shot. refs = [an already-good wider frame of the hero (cascade),
   location/clay, character turnaround sheets]. Set faceLock on any shot
   featuring a lead's face; pass avoid to negative-prompt a known drift target. */
let shot: (
  ~prompt: description,
  ~out: Cinema_Backends.path,
  ~refs: array<Cinema_Backends.path>,
  ~register: register,
  ~faceLock: bool,
  ~avoid: array<actorName>,
) => promise<Cinema_Backends.path>
