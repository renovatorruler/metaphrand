/* Still-frame records: JSON-object prompts (the director's proven format),
   emitted from typed records — style is ONE constant, cast/props resolve
   through the same registry as video. No freehand still prompts, ever. */
open Drakosha_SeedanceBatch

type stillRecord = {
  frameId: string,
  cast: array<castToken>,
  props: array<propToken>,
  setting: string,
  action: string,
  camera: string,
}

let styleConstant = "Stylized low-poly 3D render, faceted geometry, warm hearth lighting, cinematic film still, 16:9. Every character matches their reference image with 100% fidelity."

let emitJsonPrompt = (r: stillRecord): string => {
  let d = Js.Dict.empty()
  Js.Dict.set(d, "style", Js.Json.string(styleConstant))
  Js.Dict.set(
    d,
    "characters",
    Js.Json.array(r.cast->Belt.Array.map(t => Js.Json.string((castEntry(t)).tagLine))),
  )
  Js.Dict.set(d, "setting", Js.Json.string(r.setting))
  Js.Dict.set(d, "action", Js.Json.string(r.action))
  Js.Dict.set(d, "camera", Js.Json.string(r.camera))
  Js.Dict.set(
    d,
    "constraints",
    Js.Json.string(
      "Only the listed characters, exactly as referenced. Barefoot tiny house-spirits. No shoes, no open fireplace, no storybook-illustration style, no text.",
    ),
  )
  Js.Json.stringifyWithSpace(Js.Json.object_(d), 2)
}

let emitStillRefs = (r: stillRecord): array<string> =>
  emitRefPaths({
    jobId: r.frameId,
    shots: "",
    cast: r.cast,
    props: r.props,
    startImage: None,
    durationSec: 8,
    creative: "",
    carriesLines: [],
  })


let frames: array<stillRecord> = [
  {frameId: "f24", cast: [Mama, Frosya, Vasya], props: [RoomFront, Chest], setting: "The hall; MAMA has opened the hidden niche in the brick wall and set her small iron-bound chest of wooden letter tiles on the floor.", action: "FROSYA reluctantly lays the small worn pencil on the chest lid; VASYA presses his palm flat on the wood beside it; MAMA covers both their hands with hers; a ripple of golden light runs across the pencil and the boy's palm.", camera: "Overhead three-quarter on the chest lid and the three pairs of hands, warm lamplight."},
  {frameId: "f25", cast: [Mama, Vasya, Frosya], props: [RoomFront, Chest, Tiles], setting: "The hall floor beside the open letter chest.", action: "MAMA points at a row of eight wooden letter tiles laid out on the floorboards; VASYA names them one by one, concentrating hard; FROSYA stands with folded arms, indignant.", camera: "Low angle at floor level, the tile row sharp in the foreground."},
  {frameId: "f26", cast: [Mama, Vasya], props: [RoomFront, Pouch], setting: "The hall.", action: "MAMA ties a small cloth pouch of letter tiles to VASYA's shoelace belt at his hip; VASYA holds the pouch against his side with enormous pride, chest puffed.", camera: "Medium two-shot at child height."},
  {frameId: "f27", cast: [Frosya, Vasya], props: [RoomFront, Pencil, Tiles], setting: "The hall floor, letter tiles scattered on the boards.", action: "FROSYA kneels writing on a paper scrap with the magic pencil; a bright flash bursts beside the written word and a thimble of juice stands there; VASYA leans in open-mouthed.", camera: "Overhead close on the paper, the flash lighting both faces."},
  {frameId: "f28", cast: [Frosya, Vasya], props: [RoomFront, Pencil], setting: "The hall floor.", action: "FROSYA offers the thimble of juice with a grand gracious gesture; VASYA takes it, amazed; a small bowl of salad sits beside them and VASYA recoils from it in disgust.", camera: "Medium two-shot, low."},
  {frameId: "f29", cast: [Frosya, Mama], props: [RoomFront, Pencil], setting: "The hall by the banquet table.", action: "FROSYA shyly holds out a scarlet poppy on a long stem to MAMA; MAMA accepts it softly, deeply moved, one hand at her chest.", camera: "Warm medium two-shot."},
  {frameId: "f30", cast: [Vasya, Frosya], props: [RoomFront, Tiles], setting: "The hall floor.", action: "VASYA has laid four tiles in a row spelling MAMA and reads them aloud, mouth open mid-shout; FROSYA watches sideways with a wicked grin.", camera: "Low over the tile row."},
  {frameId: "f31", cast: [Mama, Frosya], props: [RoomFront], setting: "The hall.", action: "A SECOND MAMA stands in the room, identical to the mother in every way except for enormous shaggy dark eyebrows above her eyes and a panicked expression; the two babies cling to her skirts, one chewing her apron; the real MAMA stands opposite touching her own eyebrow; FROSYA has collapsed on the floor laughing.", camera: "Wide group shot, comic staging."},
  {frameId: "f32", cast: [Frosya, Vasya], props: [RoomFront, Tiles, Pencil], setting: "The hall floor, tiles spread out.", action: "FROSYA sorts through tiles with a frown, three empty gaps in the row in front of her; VASYA peers over her shoulder puzzled; she points at him with sudden fierce determination.", camera: "Over-shoulder onto the tile row."},
  {frameId: "f33", cast: [Frosya, Vasya], props: [RoomFront, Scooter], setting: "The hall.", action: "A gleaming kick scooter sized for FROSYA stands where the written word still glows on the floor; FROSYA grips the handlebars triumphantly, one foot on the deck; VASYA jumps up and down beside her, begging for a turn.", camera: "Medium wide, the scooter fully in frame."},
  {frameId: "f34", cast: [Frosya, Vasya], props: [Road, Scooter], setting: "The underfloor road: a long plank corridor beneath the giants' floor, brick foundation walls, a lantern far behind.", action: "FROSYA races past on the scooter, hair streaming, delighted; VASYA runs after her, arms out, shouting, left behind.", camera: "Low tracking angle down the plank road."},
  {frameId: "f35", cast: [VasyaCat, Frosya], props: [Road, Scooter], setting: "The underfloor road.", action: "A small ginger cat with enormous shaggy dark eyebrows lies stretched across the plank road, tail blocking the last gap, insolent; FROSYA has braked hard and stands over him with her hands on her hips, furious.", camera: "Ground-level side view along the road."},
  {frameId: "f36", cast: [VasyaCat, Frosya], props: [Road, Pencil, Tank], setting: "The underfloor road.", action: "A huge inverted metal container has dropped over the ginger cat, trapping him; FROSYA stands beside it with the pencil still pointed, arms crossed, unimpressed; a paw pokes out from under the rim.", camera: "Medium, the container dominating frame."},
  {frameId: "f37", cast: [VasyaWasp, Frosya], props: [Road, Scooter], setting: "The underfloor road.", action: "A striped wasp with enormous shaggy dark eyebrows dives through the air straight at FROSYA, who screams and abandons the scooter, running for the ramp.", camera: "Dynamic low angle, motion blur on the wasp."},
  {frameId: "f38", cast: [VasyaWasp, Frosya, Mama, Papa, YagaDomovoy], props: [RoomFront, Cake], setting: "The hall; the banquet table is set with a crumb-and-berry birthday cake and an open box of candles.", action: "FROSYA bursts in swatting at the diving wasp and crashes into the table; the table tilts, the candle box jumps, one thin candle rolls off the edge toward a narrow crack in the floorboards; the three adults spring up in alarm.", camera: "Wide, the tilting table centred."},
  {frameId: "f39", cast: [Frosya, Vasya], props: [RoomFront], setting: "The hall floor beside a narrow dark opening between the boards.", action: "FROSYA and VASYA lie flat on their stomachs side by side, chins on the boards, staring down into the dark hole; six candles remain in the open box behind them; both faces are stricken with guilt.", camera: "Low, level with the floor."},
  {frameId: "f40", cast: [Frosya, Vasya], props: [RoomFront, Thread], setting: "The hall floor by the opening.", action: "A ball of thread has appeared beside a freshly written word; FROSYA holds out the loose end to VASYA with sudden gentleness; VASYA takes a slow steadying breath.", camera: "Close two-shot at floor level."},
  {frameId: "f41", cast: [Frosya, Mama, Papa], props: [RoomFront, Thread], setting: "The hall floor by the opening.", action: "FROSYA lies with her ear pressed to the floorboards holding the ball of thread which disappears into the dark opening; MAMA holds PAPA back with one quiet hand on his arm; everyone waits.", camera: "Medium wide, tense stillness."},
  {frameId: "f42", cast: [Frosya, Vasya, Mama], props: [RoomFront], setting: "The hall floor by the opening.", action: "The rescued candle lies on the boards neatly tied with thread; VASYA stands dusty and rumpled and glowing with pride, still catching his breath; FROSYA beams beside him; MAMA looks them both over, arms folded, allowing the smallest smile.", camera: "Medium group at child height."},
  {frameId: "f43", cast: [Frosya, Vasya, Mama, Papa, YagaDomovoy, Babies], props: [RoomFront, Cake], setting: "The hall at evening, the banquet table.", action: "All seven candles burn on the crumb-and-berry cake; FROSYA has her eyes closed making a wish, cheeks full of held breath; the whole family is gathered close around the table, faces lit by the candlelight.", camera: "Warm wide across the table, candlelight as the key light."},
  {frameId: "f44", cast: [Frosya], props: [RoomFront, Pencil], setting: "The hall at night, everyone else asleep in the matchbox beds, the stove-plate wall glowing faintly.", action: "FROSYA sits alone on the floor by a paper scrap on which she has drawn a red car with headlights; beneath the drawing six boxes for letters, filled in only as M, A, three empty, A; she looks at the unfinished word with the pencil in her hand.", camera: "Intimate low angle, single warm light source, everything else in shadow."},
]

/* F23 reroll — the proof case for the JSON format. */
let f23: stillRecord = {
  frameId: "f23",
  cast: [YagaDomovoy, Frosya, Vasya, Mama],
  props: [RoomFront],
  setting: "The tiny family's hall inside the old bricked-up fireplace, exactly as the room reference: giant boulder-brick walls, dark riveted iron plate wall with warm light seeping at its edges, matchbox beds, colored garland bulbs.",
  action: "BABA YAGA chuckles slyly with one finger raised. FROSYA clutches her small worn pencil to her chest. VASYA pats the top of his own head. The two children exchange a puzzled look. MAMA watches the two gifts from the background with narrowed eyes.",
  camera: "Medium group shot at child height, warm lamplight, the iron plate wall behind.",
}

let () = {
  frames->Belt.Array.forEach(f => {
    Js.log("=====" ++ f.frameId)
    Js.log(emitJsonPrompt(f))
    Js.log("REFS\t" ++ emitStillRefs(f)->Js.Array2.joinWith("\t"))
  })
}
