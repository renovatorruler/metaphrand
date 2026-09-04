exception PronunciationTestFailure(string)

let check = (condition: bool, message: string): unit =>
  if !condition {
    raise(PronunciationTestFailure(message))
  }

let () = {
  check(Drakosha_Pronunciation.audioFor(`СОВА`) == `СА-ВА́`, "СОВА stress form")
  check(Drakosha_Pronunciation.audioFor(`ЛАВКА`) == `ЛА́В-КА`, "ЛАВКА stress form")
  check(Drakosha_Pronunciation.audioFor(`КОЛОКОЛ`) == `КО́-ЛА-КАЛ`, "КОЛОКОЛ stress form")
  check(Drakosha_Pronunciation.audioFor(`ОБВАЛ`) == `АБ-ВА́Л`, "ОБВАЛ stress form")
  let spelling = Drakosha_Pronunciation.audioInText(`СО-ВА. СОВА! ВЖУХ!`)
  check(spelling == `СО-ВА. СА-ВА́! ВЖУХ!`, "orthographic spelling must survive audio substitution")
  let lavka = Drakosha_Pronunciation.audioInText(`Л-А-В-К-А. ЛАВКА!`)
  check(lavka == `Л-А-В-К-А. ЛА́В-КА!`, "ЛАВКА spelling must stay separate")
  Js.log("Drakosha pronunciation registry: PASS")
}
