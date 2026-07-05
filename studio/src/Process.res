/* Implementation. The shapes are the contract (Process.resi); the bodies here
   are stubs for now — enough to compile and to prove the type story holds. */

@unboxed type idea = Idea(string)
@unboxed type characterName = CharacterName(string)
@unboxed type actionLine = ActionLine(string)
@unboxed type dialogue = Dialogue(string)
@unboxed type heldCard = HeldCard(string)
@unboxed type want = Want(string)
@unboxed type wall = Wall(string)
@unboxed type turn = Turn(string)
@unboxed type lineNo = LineNo(int)
@unboxed type reasonText = ReasonText(string)
@unboxed type sentenceShape = SentenceShape(string)
@unboxed type vocabulary = Vocabulary(string)
@unboxed type sampleLine = SampleLine(string)
@unboxed type noteText = NoteText(string)
@unboxed type question = Question(string)
@unboxed type episodeTitle = EpisodeTitle(string)

type offer<'a> = Show('a) | Ask(question)

type sign =
  | Aries | Taurus | Gemini | Cancer | Leo | Virgo
  | Libra | Scorpio | Sagittarius | Capricorn | Aquarius | Pisces

type natalChart = {
  sun: sign, moon: sign, mars: sign, mercury: sign, jupiter: sign,
  venus: sign, saturn: sign, rahu: sign, ketu: sign,
}

type eloquence = Earned | Plain
type voice = {
  sentence: sentenceShape,
  vocabulary: vocabulary,
  eloquence: eloquence,
  sample: sampleLine,
}

/* concrete here, abstract in Process.resi — the memo cell lives inside, where no
   one outside can set it to anything but the derivation of this chart. */
type character = {
  name: characterName,
  chart: natalChart,
  mutable cachedVoice: option<voice>,
}

let make = (~name: characterName, ~chart: natalChart): character => {
  name,
  chart,
  cachedVoice: None,
}
let name = (c: character) => c.name
let chart = (c: character) => c.chart

let signName = (s: sign): string =>
  switch s {
  | Aries => "Aries" | Taurus => "Taurus" | Gemini => "Gemini" | Cancer => "Cancer"
  | Leo => "Leo" | Virgo => "Virgo" | Libra => "Libra" | Scorpio => "Scorpio"
  | Sagittarius => "Sagittarius" | Capricorn => "Capricorn" | Aquarius => "Aquarius" | Pisces => "Pisces"
  }

let renderChart = (c: natalChart): string =>
  "Sun in " ++ signName(c.sun) ++ ", Moon in " ++ signName(c.moon) ++ ", Mars in " ++ signName(c.mars) ++
  ", Mercury in " ++ signName(c.mercury) ++ ", Jupiter in " ++ signName(c.jupiter) ++ ", Venus in " ++ signName(c.venus) ++
  ", Saturn in " ++ signName(c.saturn) ++ ", Rahu in " ++ signName(c.rahu) ++ ", Ketu in " ++ signName(c.ketu)

let voicePrompt = (chart: natalChart): string =>
  "Here is a character's Vedic natal chart (each graha in its sign):\n" ++ renderChart(chart) ++
  "\n\nDerive this character's SPEAKING VOICE from the chart - how they actually talk, so they sound like no one else. Output EXACTLY four lines:\n" ++
  "SENTENCE: <their sentence rhythm and shape, one phrase>\n" ++
  "VOCABULARY: <the words they reach for, one phrase>\n" ++
  "ELOQUENCE: <earned or plain: can they carry a polished line, or do they speak rough?>\n" ++
  "SAMPLE: <one line of dialogue only this character would say>"

let fieldFrom = (lines: array<string>, label: string): string =>
  switch Belt.Array.getBy(lines, l => Js.String2.startsWith(Js.String2.toUpperCase(Js.String2.trim(l)), label)) {
  | None => ""
  | Some(l) =>
    switch Js.String2.indexOf(l, ":") {
    | -1 => ""
    | i => Js.String2.sliceToEnd(l, ~from=i + 1)->Js.String2.trim
    }
  }

let deriveVoice = async (chart: natalChart, ask: string => promise<string>): voice => {
  let lines = Js.String2.split(await ask(voicePrompt(chart)), "\n")
  {
    sentence: SentenceShape(fieldFrom(lines, "SENTENCE")),
    vocabulary: Vocabulary(fieldFrom(lines, "VOCABULARY")),
    eloquence: Js.String2.includes(Js.String2.toLowerCase(fieldFrom(lines, "ELOQUENCE")), "earn") ? Earned : Plain,
    sample: SampleLine(fieldFrom(lines, "SAMPLE")),
  }
}

/* memoized: derive once via the asker, cache on the (immutable-chart) character. */
let voice = async (c: character, ask: string => promise<string>): voice =>
  switch c.cachedVoice {
  | Some(v) => v
  | None => {
      let v = await deriveVoice(c.chart, ask)
      c.cachedVoice = Some(v)
      v
    }
  }

type bible = {cast: array<character>, secrets: array<heldCard>}

type brief = {
  want: want,
  wall: wall,
  turn: turn,
  present: array<characterName>,
  live: array<heldCard>,
}

type conceptGate = Drama | HumanReaction | Heart | Structure | SecretsBuried | Cultural
type finding =
  | Concept(conceptGate, reasonText, lineNo)
  | Language(Gate.violation, lineNo)
type verdict = Passed | Failed(array<finding>)

let describeFinding = (f: finding): string =>
  switch f {
  | Language(v, _) => Gate.describe(v)
  | Concept(g, ReasonText(r), _) =>
    let name = switch g {
    | Drama => "drama"
    | HumanReaction => "human-reaction"
    | Heart => "heart"
    | Structure => "structure"
    | SecretsBuried => "secrets-buried"
    | Cultural => "cultural"
    }
    name ++ ": " ++ r
  }

type conceptCleared = ConceptCleared
type approval = Approval
type languageClean = LanguageClean

type draft = {brief: brief, action: array<actionLine>, lines: array<dialogue>, ordered: array<string>}

type scene =
  | Briefed(brief)
  | Drafted(draft)
  | ConceptReady(draft, conceptCleared)
  | Approved(draft, conceptCleared, approval)
  | Shippable(draft, languageClean)

let scenePrompt = (b: brief, voiceGuide: string): string => {
  let Want(w) = b.want
  let Wall(wl) = b.wall
  let Turn(t) = b.turn
  let present = Js.Array2.joinWith(Belt.Array.map(b.present, (CharacterName(n)) => n), ", ")
  let secrets = Js.Array2.joinWith(Belt.Array.map(b.live, (HeldCard(h)) => h), "; ")
  let voices = voiceGuide == "" ? "" : "\n\nWrite each character STRICTLY in their own voice, so no two sound alike:\n" ++ voiceGuide
  "Write a short screenplay scene.\n" ++
  "WANT: " ++ w ++ "\nWALL: " ++ wl ++ "\nTURN: " ++ t ++ "\n" ++
  "Characters present: " ++ present ++ "\n" ++
  "Secrets to keep BURIED (never state on the page, only imply): " ++ secrets ++ voices ++ "\n\n" ++
  "Rules: action lines describe ONLY what a camera sees and a mic hears - no thoughts, no backstory, no explaining. " ++
  "Dialogue is \"NAME: line\" with NAME in capitals. Write plainly: no literary or fancy sentences, no fragment-stacking, no em-dash. " ++
  "Dramatize the want hitting the wall and turning.\n\n" ++
  "Output the scene, one element per line. Nothing else."
}

/* a line is dialogue if it opens with a CAPS speaker cue ("RAY:"); else it's action. */
let isDialogue = (line: string): bool =>
  switch Js.String2.indexOf(line, ":") {
  | -1 => false
  | i => {
      let prefix = Js.String2.slice(line, ~from=0, ~to_=i)
      i > 0 && i <= 30 && Js.String2.toUpperCase(prefix) == prefix && Js.String2.trim(prefix) != ""
    }
  }

/* pull each present character's voice (memoized, derived from their chart) as guidance. */
let rec gatherVoices = async (
  names: list<characterName>,
  cast: array<character>,
  ask: string => promise<string>,
  acc: array<string>,
): array<string> =>
  switch names {
  | list{} => acc
  | list{nm, ...rest} => {
      let acc' = switch Belt.Array.getBy(cast, c => name(c) == nm) {
      | None => acc
      | Some(c) => {
          let v = await voice(c, ask)
          let CharacterName(n) = nm
          let SentenceShape(s) = v.sentence
          let SampleLine(sa) = v.sample
          Belt.Array.concat(acc, [n ++ ": " ++ s ++ " (e.g. " ++ sa ++ ")"])
        }
      }
      await gatherVoices(rest, cast, ask, acc')
    }
  }

let parseScene = (b: brief, reply: string): draft => {
  let raw = Js.String2.split(reply, "\n")->Belt.Array.keep(l => Js.String2.trim(l) != "")
  let action = raw->Belt.Array.keepMap(l => isDialogue(l) ? None : Some(ActionLine(l)))
  let dialogue = raw->Belt.Array.keepMap(l => isDialogue(l) ? Some(Dialogue(l)) : None)
  {brief: b, action, lines: dialogue, ordered: raw}
}

let renderScene = (d: draft): string => Js.Array2.joinWith(d.ordered, "\n")

let draftScene = async (b: brief, bible: bible, ask: string => promise<string>): draft => {
  let voiceLines = await gatherVoices(Belt.List.fromArray(b.present), bible.cast, ask, [])
  parseScene(b, await ask(scenePrompt(b, Js.Array2.joinWith(voiceLines, "\n"))))
}

/* the repair the gate->repair loop calls: rewrite the scene to fix the findings. */
let repairScene = async (d: draft, findings: array<finding>, ask: string => promise<string>): draft => {
  let problems = Js.Array2.joinWith(Belt.Array.map(findings, describeFinding), "; ")
  let reply = await ask(
    "Rewrite this screenplay scene to fix these problems, keeping the same events and the want/wall/turn, and the format (action lines plain; dialogue as NAME: line).\nProblems: " ++
    problems ++ "\n\nScene:\n" ++ renderScene(d),
  )
  parseScene(d.brief, reply)
}
let sceneText = (d: draft): string => {
  let Want(w) = d.brief.want
  let Wall(wl) = d.brief.wall
  let Turn(t) = d.brief.turn
  let action = Js.Array2.joinWith(Belt.Array.map(d.action, (ActionLine(a)) => a), "\n")
  let lines = Js.Array2.joinWith(Belt.Array.map(d.lines, (Dialogue(l)) => l), "\n")
  "WANT: " ++ w ++ "\nWALL: " ++ wl ++ "\nTURN: " ++ t ++ "\n\nACTION:\n" ++ action ++ "\n\nDIALOGUE:\n" ++ lines
}

/* run the concept gates one at a time (never concurrently), collecting findings. */
let rec runConceptGates = async (
  gates: list<conceptGate>,
  text: string,
  judge: (conceptGate, string) => promise<option<reasonText>>,
  acc: array<finding>,
): array<finding> =>
  switch gates {
  | list{} => acc
  | list{g, ...rest} => {
      let acc' = switch await judge(g, text) {
      | Some(r) => Belt.Array.concat(acc, [Concept(g, r, LineNo(0))])
      | None => acc
      }
      await runConceptGates(rest, text, judge, acc')
    }
  }

let gateConcept = async (
  d: draft,
  judge: (conceptGate, string) => promise<option<reasonText>>,
): result<conceptCleared, array<finding>> => {
  let findings = await runConceptGates(
    list{Drama, HumanReaction, Heart, Structure, SecretsBuried, Cultural},
    sceneText(d),
    judge,
    [],
  )
  Array.length(findings) == 0 ? Ok(ConceptCleared) : Error(findings)
}
let approve = (_d: draft, _proof: conceptCleared): approval => Approval
let gateLanguage = async (
  d: draft,
  _a: approval,
  judge: string => promise<array<Gate.violation>>,
): result<languageClean, array<finding>> => {
  let texts = Belt.Array.concat(
    Belt.Array.map(d.action, (ActionLine(t)) => t),
    Belt.Array.map(d.lines, (Dialogue(t)) => t),
  )
  /* the mechanical floor (free) */
  let floor = Belt.Array.reduce(texts, [], (acc, t) =>
    switch Gate.craftlint(Gate.raw(t)) {
    | Ok(_) => acc
    | Error(gfs) => Belt.Array.concat(acc, Belt.Array.map(gfs, gf => Language(gf.violation, LineNo(0))))
    }
  )
  /* the model judge (paid) over the whole prose — catches the subtle slop */
  let judged = await judge(Js.Array2.joinWith(texts, "\n"))
  let all = Belt.Array.concat(floor, Belt.Array.map(judged, v => Language(v, LineNo(0))))
  Array.length(all) == 0 ? Ok(LanguageClean) : Error(all)
}

type repairOutcome<'proof> =
  | Cleared('proof, draft)
  | Stuck(draft, array<finding>)

let rec repairToward = async (
  d: draft,
  gate: draft => promise<result<'proof, array<finding>>>,
  repair: (draft, array<finding>) => promise<draft>,
  gas: Gas.gas,
): repairOutcome<'proof> =>
  switch await gate(d) {
  | Ok(proof) => Cleared(proof, d)
  | Error(findings) =>
    switch Gas.burn(gas) {
    | Gas.Empty => Stuck(d, findings)
    | Gas.Fuel(left) => {
        let fixed = await repair(d, findings)
        await repairToward(fixed, gate, repair, left)
      }
    }
  }

type episode = {title: episodeTitle, scenes: array<scene>}

type spark = Spark(idea)
type developed = Developed(bible)
type shaped = Shaped(bible)
type inProduction = InProduction(bible, array<episode>)

let conceive = (i: idea): spark => Spark(i)

/* --- the room generates the world (cast with charts + secrets) from the idea --- */
let parseSign = (s: string): sign =>
  switch Js.String2.trim(s)->Js.String2.toLowerCase {
  | "taurus" => Taurus | "gemini" => Gemini | "cancer" => Cancer | "leo" => Leo
  | "virgo" => Virgo | "libra" => Libra | "scorpio" => Scorpio | "sagittarius" => Sagittarius
  | "capricorn" => Capricorn | "aquarius" => Aquarius | "pisces" => Pisces
  | _ => Aries
  }

let parseCharacter = (parts: array<string>): option<character> =>
  switch parts {
  | [_, name, signsStr] => {
      let signs =
        Js.String2.split(Js.String2.trim(signsStr), " ")
        ->Belt.Array.keep(x => x != "")
        ->Belt.Array.map(parseSign)
      let at = i => Belt.Array.get(signs, i)->Belt.Option.getWithDefault(Aries)
      Some(
        make(
          ~name=CharacterName(Js.String2.trim(name)),
          ~chart={
            sun: at(0), moon: at(1), mars: at(2), mercury: at(3), jupiter: at(4),
            venus: at(5), saturn: at(6), rahu: at(7), ketu: at(8),
          },
        ),
      )
    }
  | _ => None
  }

let startsWithTag = (line: string, tag: string): bool =>
  Js.String2.startsWith(Js.String2.toUpperCase(Js.String2.trim(line)), tag)

let parseWorld = (reply: string): bible => {
  let lines = Js.String2.split(reply, "\n")
  let cast =
    lines->Belt.Array.keepMap(l =>
      startsWithTag(l, "CHARACTER") ? parseCharacter(Js.String2.split(l, "|")) : None
    )
  let secrets =
    lines->Belt.Array.keepMap(l =>
      startsWithTag(l, "SECRET")
        ? switch Js.String2.split(l, "|") {
          | [_, s] => Some(HeldCard(Js.String2.trim(s)))
          | _ => None
          }
        : None
    )
  {cast, secrets}
}

let worldPrompt = (i: idea, note: option<string>): string => {
  let Idea(text) = i
  let revision = switch note {
  | Some(n) => "\n\nThe director's note on the last version: " ++ n ++ "\nRevise accordingly."
  | None => ""
  }
  "Design the world for this story idea:\n" ++ text ++ "\n\n" ++
  "Give 3 to 5 main characters. For each: a name, and a Vedic natal chart assigning each of the 9 grahas (Sun Moon Mars Mercury Jupiter Venus Saturn Rahu Ketu, IN THAT ORDER) a sign that fits their nature. Then 2 to 3 secrets the story keeps buried.\n\n" ++
  "Output one per line, EXACTLY this format, nothing else:\n" ++
  "CHARACTER | <name> | <9 signs space-separated, in graha order>\n" ++
  "SECRET | <the secret>" ++ revision
}

let generateWorld = async (i: idea, note: option<string>, ask: string => promise<string>): bible =>
  parseWorld(await ask(worldPrompt(i, note)))

/* serialize a world to disk text (and back) — so a project persists, and a
   reload re-generates nothing. */
let bibleToText = (b: bible): string => {
  let chars = Belt.Array.map(b.cast, c => {
    let CharacterName(n) = name(c)
    let ch = chart(c)
    "CHARACTER | " ++ n ++ " | " ++
    Js.Array2.joinWith(
      [signName(ch.sun), signName(ch.moon), signName(ch.mars), signName(ch.mercury), signName(ch.jupiter), signName(ch.venus), signName(ch.saturn), signName(ch.rahu), signName(ch.ketu)],
      " ",
    )
  })
  let secrets = Belt.Array.map(b.secrets, (HeldCard(s)) => "SECRET | " ++ s)
  Js.Array2.joinWith(Belt.Array.concat(chars, secrets), "\n")
}

let bibleFromText = parseWorld

/* the enforced back-and-forth, now METERED: the development carries its gas, each
   `respond` burns one, and at empty it Stalls — only your approval (approveMore)
   refuels it. It still converges to `shaped`, the penultimate. */
type development = Development(spark, Gas.gas, bible)   // carries the world it's proposing
type reaction = Approve | Revise(noteText)
type step = Continue(development) | Done(shaped) | Stalled(development)

let begin = async (s: spark, ask: string => promise<string>): development => {
  let Spark(i) = s
  let world = await generateWorld(i, None, ask)
  Development(s, Gas.perPhase, world)
}
let show = (Development(_s, _g, b): development): offer<bible> => Show(b)
let respond = async (
  Development(Spark(i), gas, world): development,
  r: reaction,
  ask: string => promise<string>,
): step =>
  switch Gas.burn(gas) {
  | Gas.Empty => Stalled(Development(Spark(i), gas, world))
  | Gas.Fuel(left) =>
    switch r {
    | Approve => Done(Shaped(world))
    | Revise(NoteText(note)) => {
        let revised = await generateWorld(i, Some(note), ask)
        Continue(Development(Spark(i), left, revised))
      }
    }
  }

let approveMore = (Development(Spark(i), _gas, world): development, a: Gas.approval): development =>
  Development(Spark(i), Gas.refuel(a), world)

/* stage 3 -> 4: the finishing-touches tools run here; stubbed as pass-through. */
let finish = (Shaped(b): shaped): promise<developed> => Js.Promise.resolve(Developed(b))

let breakInto = (Developed(b): developed, titles: array<episodeTitle>): inProduction =>
  InProduction(b, Js.Array2.map(titles, t => {title: t, scenes: []}))
let theBible = (Developed(b): developed) => b
let theEpisodes = (InProduction(_b, eps): inProduction) => eps
