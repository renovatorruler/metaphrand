/* EP1 chapter 1 as game data. Emits game/main/episode1.lua. */
open Drakosha_GamePlan

let kot: spell = {
  spellId: "kot",
  word: [K, O, T],
  asker: "VASYA",
  askLine: "vasya_ask_kot",
  hintLines: ["frosya_hint_stroke_down", "frosya_hint_try_again", "vasya_hint_together"],
  praiseLines: ["vasya_praise_1", "frosya_praise_1", "vasya_praise_2"],
  revealAsset: "REVEAL-KOT_author",
  scaffold: TraceOverModel,
}

let sok: spell = {
  spellId: "sok",
  word: [S, O, K],
  asker: "FROSYA",
  askLine: "frosya_ask_sok",
  hintLines: ["frosya_hint_stroke_curve", "frosya_hint_try_again"],
  praiseLines: ["frosya_praise_1", "vasya_praise_2"],
  revealAsset: "REVEAL-SOK",
  scaffold: TraceOverModel,
}

let mama: spell = {
  spellId: "mama",
  word: [M, A, M, A],
  asker: "VASYA",
  askLine: "vasya_ask_mama",
  hintLines: ["frosya_hint_stroke_down", "vasya_hint_together"],
  praiseLines: ["vasya_praise_1", "frosya_praise_1"],
  revealAsset: "REVEAL-MAMA_author",
  scaffold: TraceOverDots,
}

let ep1: episode = {
  episodeId: "ep1_den_rozhdeniya_ch1",
  beats: [
    Story("line043_mama", "f24"),
    Story("line046_vasya", "f25"),
    Story("line050_vasya", "f26"),
    Spell(sok),
    Story("line053_frosya", "f28"),
    Spell(mama),
    Story("line065_mama", "f31"),
    Spell(kot),
  ],
}

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
type mkdirOpts = {recursive: bool}
@module("fs") external mkdirSync: (string, mkdirOpts) => unit = "mkdirSync"

let () = {
  let lua = emitLua(ep1)
  mkdirSync("../game/main", {recursive: true})
  writeFileSync("../game/main/episode1.lua", lua)
  Js.log("emitted game/main/episode1.lua")
  Js.log(lua)
}
