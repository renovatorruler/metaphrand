/* कुकु और अक्षर — build Ep6's edit decision list from the manifest and the shot list.

   REWRITTEN after the first review cut failed. What that cut got wrong, and the
   rules that replace it:

   1. MIMICRY WAS BURIED. तानसेन's echoes were placed 0.35s into the segment of the
      line they follow — i.e. SIMULTANEOUS with the next spoken line. The whole
      episode sounded like people talking over each other, and the parrot never
      audibly echoed anything. Now every mimicry beat is ITS OWN SEGMENT, after the
      line, over a shot of the parrot, with nothing else speaking.
   2. EFFECTS WERE BURIED the same way (the shriek echo at 0.15s under the shriek
      line). Rule: an effect either OPENS a shot (0.0 — ambience beds, arrivals) or
      starts AFTER the line's speech ends. Nothing in between.
   3. CUTAWAYS WERE BEAT-BLIND. A fixed stride dropped story shots and clips onto
      arbitrary lines — wrong face for the voice. Now: every dialogue line shows its
      SPEAKER; the only exceptions are the scene-opening establisher, the parrot
      segments, and clips HAND-ANCHORED to the exact line they depict.
   4. Cues with after < the scene's first line (scene-opening ambience) were being
      silently dropped. They attach to the first line at 0.0 now.

   Run from studio/:  node src/Kuku_BuildEdlEp6.res.mjs */

open Cinema_Backends

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep6prod"

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
let asArr = o => o->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])

type ev = {idx: int, scene: int, who: string, text: string}
type cue = {scene: int, after: int, cue: string}

let slug = (who: string): string =>
  switch who {
  | "KUKU" => "kuku"
  | "FYURIA" => "fyuria"
  | "VESPER" => "vesper"
  | "DADI" => "dadi"
  | "PAPA" => "papa"
  | "MITASUR" => "mitasur"
  | "CASTOR" => "castor"
  | "LEDA" => "leda"
  | "CHORUS_ALL" => "group"
  | _ => "group"
  }

/* ambience beds: they open a shot at 0.0 and sit quietly under everything.
   Everything NOT in this list is an event and must land after the line. */
let beds = [
  "morning_birds_pond", "pond_water_calm", "day_crickets", "evening_crickets",
  "leaves_rustle", "wind_only_silence", "reeds_wind", "stream_bridge_ropes",
]
let isBed = (n: string): bool => Belt.Array.some(beds, b => b == n)

/* THE LETTER GOES ON SCREEN, AND SO DOES THE THING THE WORD MEANS.

   Ep5 composited its letter onto five shots. Ep6 rendered `glyphs/fx_t.png` and
   attached it to nothing — the letter the episode is named after appeared nowhere
   in fourteen minutes, and the word pictures existed only in the closing recap,
   so a child answering «तोता!» was looking at a picture of दादी.

   The preflight check that should have caught this — no-paid-orphans — printed
   "37 generated assets the cut never uses" on every single build and was read as
   noise. It is blocking now.

   Both tables are keyed on the SPEECH INDEX the segment carries, never on a
   segment position, so re-cutting a scene cannot silently detach an overlay from
   the line it belongs to.

   During the «त से…?» game the letter shrinks to the top-left and the picture
   sits top-right, so the child sees the letter and the thing AT THE SAME TIME —
   which is the whole point of the game — without either covering the faces. */
let letterOn: array<(int, float, float, string)> = [
  /* line idx, fade-in at, scale (fraction of frame width), corner */
  (68, 0.60, 0.30, "tc"), /* कुकु names the letter: «आज का अक्षर — त!» */
  (70, 0.15, 0.30, "tc"), /* सब: «त!» — the chorus says it */
  (72, 0.10, 0.16, "tl"), /* …and it stays up through the whole word game */
  (74, 0.10, 0.16, "tl"),
  (76, 0.10, 0.16, "tl"),
  (90, 0.20, 0.34, "tc"), /* कुकु: «त बन गया!» — it has just been forged */
  (100, 0.30, 0.26, "tc"), /* कैस्टर: «बैठ गया!» — तानसेन is perched on it */
]

let picOn: array<(int, string)> = [
  (72, "tota"), /* लेडा: «तोता!» */
  (74, "talab"), /* कैस्टर: «तालाब!» */
  (76, "tana"), /* वैस्पर: «तना।» */
]

let fxFor = (takes: array<Kuku_Edl.take>): array<Kuku_Edl.fx> => {
  let out = []
  takes->Belt.Array.forEach(t =>
    switch t {
    | Kuku_Edl.Speech({idx}) => {
        letterOn->Belt.Array.forEach(((i, at, scale, pos)) =>
          if i == idx {
            let _ = Js.Array2.push(out, {Kuku_Edl.png: "glyphs/fx_t.png", at, scale, pos})
          }
        )
        picOn->Belt.Array.forEach(((i, w)) =>
          if i == idx {
            let _ = Js.Array2.push(
              out,
              {Kuku_Edl.png: "glyphs/pic_" ++ w ++ ".png", at: 0.10, scale: 0.30, pos: "tr"},
            )
          }
        )
      }
    | Kuku_Edl.Effect(_) => ()
    }
  )
  out
}

/* Each clip was designed for ONE specific beat. It plays on the line that speaks
   that beat, or not at all — the stride-placement that scattered them across
   arbitrary lines is what made faces disagree with voices. The fragment must
   appear in the line's text, within the clip's own scene. */
let clipAnchors = [
  ("c6_tansen_dal_se_dal", "उड़ता ही रहता"),
  ("c6_maha_cheekh_udaan", "वैस्पर चीख़ा"),
  ("c6_race", "एक, दो, तीन"),
  ("c6_tansen_drops_into_reeds", "हार पक्की"),
  ("c6_tansen_lands_on_door", "तानसेन मिटासुर के घर"),
  ("c6_mitasur_walks_away", "रोया नहीं"),
  ("c6_t_settles_into_mud", "त बन गया"),
  ("c6_tansen_flyby_refusal", "बैठा ही नहीं"),
  ("c6_tansen_utarta", "बैठ गया! बैठ गया"),
  ("c6_saathi_handclasp", "पूरा बल लगाऊँगा"),
  ("c6_two_sleepers_breathe", "तने से टिककर सो गया"),
]

/* Which generated effect a Hindi cue plays. First match wins. A cue matching
   nothing is reported, never silently dropped. */
let effectFor = (c: string): option<string> => {
  let has = (s: string) => Js.String2.includes(c, s)
  if has("महाचीख़") || has("चीख़") {
    Some("valley_echo_scatter")
  } else if has("ताली") {
    has("सबसे बड़ी") || has("ज़ोरदार") ? Some("clap_big") : Some("clap_group")
  } else if has("खर्राटे") {
    Some("snore_soft_boy")
  } else if has("जम्हाई") {
    Some("yawn_boy")
  } else if has("दाना") && has("कटोरी") {
    Some("seed_into_bowl")
  } else if has("दाना चुगने") || has("चुगने") {
    Some("seed_peck")
  } else if has("फूँक") || has("सुनहरी चमक") {
    Some("forge_whoosh_land")
  } else if has("दरवाज़ा") && (has("बंद") || has("धीरे से बंद")) {
    Some("door_close_soft")
  } else if has("दरवाज़े") || has("चरमराहट") && has("दरवाज़") {
    Some("door_creak_small")
  } else if has("नरकुल") {
    Some("reeds_wind")
  } else if has("धारा") || has("पुल की रस्सियों") || has("रस्सी") {
    Some("stream_bridge_ropes")
  } else if has("लकीर खींचने") {
    Some("line_drawn_dirt")
  } else if has("दौड़ते क़दम") && has("भारी") {
    Some("race_footsteps")
  } else if has("छपाक") {
    Some("splash_arrive")
  } else if has("दौड़ते क़दम") {
    Some("running_steps_arrive")
  } else if has("छड़ी") {
    Some("dadi_stick_steps")
  } else if has("भारी क़दम") && has("पापा") {
    Some("papa_heavy_steps")
  } else if has("मिटासुर के धीमे") {
    Some("mitasur_slow_heavy")
  } else if has("लेडा के नन्हे") {
    Some("leda_small_steps")
  } else if has("सबके क़दम") || has("क़दम मैदान") {
    Some("group_steps_field")
  } else if has("हँसी") && has("तीनों") {
    Some("three_laugh")
  } else if has("हँसी") {
    Some("group_laugh")
  } else if has("बत्तख") {
    Some("ducks_flap_off")
  } else if has("क़दम दूर जाते") {
    Some("dadi_stick_steps")
  } else if has("उड़ता है") || has("उड़ती है") {
    Some("parrot_wingbeat")
  } else if has("पंखों की") || has("फड़फड़ाहट") {
    if has("उतर") || has("उतरता") {
      Some("parrot_land_perch")
    } else if has("दूर") || has("ऊपर चली") {
      Some("parrot_flutter_away")
    } else if has("समेटता") {
      Some("parrot_settle_feathers")
    } else {
      Some("parrot_wingbeat")
    }
  } else if has("पत्तों") || has("सरसराहट") {
    Some("leaves_rustle")
  } else if has("सन्नाटा") || has("चुप्पी") {
    Some("wind_only_silence")
  } else if has("झींगुर") {
    has("शाम") || has("गहरी") ? Some("evening_crickets") : Some("day_crickets")
  } else if has("सुबह के पक्षी") {
    Some("morning_birds_pond")
  } else if has("तालाब का") || has("पानी") {
    Some("pond_water_calm")
  } else if has("खेलते क़दम") {
    Some("kids_playing_steps")
  } else {
    None
  }
}

let cueFor = (scene: int): string =>
  switch scene {
  | 1 => "score/cueT1_morning.mp3"
  | 2 => "score/cueT2_play.mp3"
  | 3 => "score/cueT3_race.mp3"
  | 4 => "score/cueT4_hurt.mp3"
  | 5 => "score/cueT5_teach.mp3"
  | 6 => "score/cueT6_words.mp3"
  | _ => "score/cueT7_night.mp3"
  }

type sceneShots = {dialogue: array<string>, story: array<string>, clipNames: array<string>}

let loadSceneShots = (): Js.Dict.t<sceneShots> => {
  let j = Js.Json.parseExn(readText(Path(dir ++ "/ep6_scene_shots.json")))
  let o = j->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
  let out = Js.Dict.empty()
  Js.Dict.entries(o)->Belt.Array.forEach(((k, v)) => {
    let names = key => fld(v, key)->asArr->Belt.Array.keepMap(Js.Json.decodeString)
    Js.Dict.set(out, k, {dialogue: names("dialogue"), story: names("story"), clipNames: names("clips")})
  })
  out
}

let main = () => {
  let mj = Js.Json.parseExn(readText(Path(dir ++ "/ep6_manifest.json")))
  let events =
    fld(mj, "events")
    ->asArr
    ->Belt.Array.map(e => {
      idx: fld(e, "idx")->asNum->Belt.Float.toInt,
      scene: fld(e, "scene")->asNum->Belt.Float.toInt,
      who: fld(e, "who")->asStr,
      text: fld(e, "text")->asStr,
    })
  let cues =
    fld(mj, "sfx")
    ->asArr
    ->Belt.Array.map(c => {
      scene: fld(c, "scene")->asNum->Belt.Float.toInt,
      after: fld(c, "after")->asNum->Belt.Float.toInt,
      cue: fld(c, "cue")->asStr,
    })

  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/ep6_durs.json"))
  let haveStill = (n: string) => exists(Path(dir ++ "/stills/" ++ n ++ ".png"))
  let haveClip = (n: string) => exists(Path(dir ++ "/clips/" ++ n ++ ".mp4"))

  let unmatched = []
  let scenes = []
  let anchoredClips = ref(0)
  let parrotBeats = ref(0)
  let inventory = loadSceneShots()

  for s in 1 to 8 {
    let mine = events->Belt.Array.keep(e => e.scene == s && !Js.String2.endsWith(e.who, "_SFX"))
    if Belt.Array.length(mine) > 0 {
      let inv = Js.Dict.get(inventory, Belt.Int.toString(s))
      let story = inv->Belt.Option.map(i => i.story)->Belt.Option.getWithDefault([])
      let clipList = inv->Belt.Option.map(i => i.clipNames)->Belt.Option.getWithDefault([])

      /* clip lengths, probed once */
      let clipLen = Js.Dict.empty()
      clipList->Belt.Array.forEach(c =>
        if haveClip(c) {
          let Seconds(l) = probeDuration(Path(dir ++ "/clips/" ++ c ++ ".mp4"))
          Js.Dict.set(clipLen, c, l)
        }
      )

      /* the parrot's own cutaway for this scene, and the scene establisher */
      let parrotStill =
        story->Belt.Array.getBy(n => Js.String2.includes(n, "tansen") && haveStill(n))
      let establisher =
        story->Belt.Array.getBy(n => !Js.String2.includes(n, "tansen") && haveStill(n))

      let firstIdx =
        mine->Belt.Array.get(0)->Belt.Option.map(e => e.idx)->Belt.Option.getWithDefault(0)
      let nLines = Belt.Array.length(mine)
      let segments = []

      mine->Belt.Array.forEachWithIndex((li, e) => {
        let lineDur = Kuku_Edl.takeDur(durs, e.idx)
        let own = "e6_d" ++ Belt.Int.toString(s) ++ "_" ++ slug(e.who)
        let grp = "e6_d" ++ Belt.Int.toString(s) ++ "_group"
        let dialoguePic = haveStill(own) ? own : haveStill(grp) ? grp : own
        let isRecap = Js.String2.includes(e.text, "त से तोता")
        let need = 0.3 +. lineDur +. 0.38

        let anchored =
          clipAnchors->Belt.Array.getBy(((c, frag)) =>
            Belt.Array.some(clipList, x => x == c) &&
            Js.String2.includes(e.text, frag) &&
            switch Js.Dict.get(clipLen, c) {
            | Some(l) => need <= l +. 0.05
            | None => false
            }
          )
        switch anchored {
        | Some(_) => anchoredClips := anchoredClips.contents + 1
        | None => ()
        }

        let src = if isRecap {
          Kuku_Edl.Seq
        } else {
          switch anchored {
          | Some((c, _)) => Kuku_Edl.Clip(c)
          | None =>
            li == 0
              ? switch establisher {
                | Some(st) => Kuku_Edl.Still(st)
                | None => Kuku_Edl.Still(dialoguePic)
                }
              : Kuku_Edl.Still(dialoguePic)
          }
        }
        let cards = isRecap ? ["t3", "t4", "t5", "t6", "t7", "t8"] : []

        let takes = [Kuku_Edl.Speech({idx: e.idx, at: None})]
        let postAt = 0.3 +. lineDur +. 0.25
        let maxEnd = ref(0.0)
        let pendingMimic = []

        cues
        ->Belt.Array.keep(c => c.scene == s && (c.after == e.idx || (li == 0 && c.after < firstIdx)))
        ->Belt.Array.forEach(c => {
          /* A cue is mimicry when THE CUE ITSELF is तानसेन speaking (his name plus a
             quoted line). Detecting it by filename-at-this-index was wrong: any
             OTHER cue sharing the same index (a सन्नाटा beat, a wing flap) also
             found the mimic files and pushed the echo AGAIN — the door-scene echo
             played twice and the closing trio would have played six times. */
          /* mimicry cues carry a quoted line plus either «हूबहू», his name, or just
             «तोता» — early in s2 he echoes before he has even been named */
          let isMimicCue =
            Js.String2.includes(c.cue, "«") &&
            (Js.String2.includes(c.cue, "हूबहू") ||
            Js.String2.includes(c.cue, "तानसेन") ||
            Js.String2.includes(c.cue, "तोता"))
          let mimicNames = isMimicCue
            ? Js.Dict.keys(durs.sfx)->Belt.Array.keep(k =>
                Js.String2.startsWith(
                  k,
                  "mimic_" ++ (c.after < 10 ? "0" : "") ++ Belt.Int.toString(c.after) ++ "_",
                )
              )
            : []
          if Belt.Array.length(mimicNames) > 0 {
            mimicNames->Belt.Array.forEach(m => {
              if !Belt.Array.some(pendingMimic, x => x == m) {
                let _ = Js.Array2.push(pendingMimic, m)
              }
            })
          } else {
            switch effectFor(c.cue) {
            | Some(fx) => {
                /* opening sounds (pre-scene cues, ambience beds) start the shot;
                   everything else lands AFTER the line and may ring into the next
                   shot — that is what a reaction sound is */
                let opening = c.after != e.idx || isBed(fx)
                let at = opening ? 0.0 : postAt
                if !opening {
                  let e2 = postAt +. Kuku_Edl.sfxDur(durs, fx)
                  if e2 > maxEnd.contents {
                    maxEnd := e2
                  }
                }
                let _ = Js.Array2.push(takes, Kuku_Edl.Effect({name: fx, at: Some(at), duck: false}))
              }
            | None => {
                let _ = Js.Array2.push(
                  unmatched,
                  "s" ++ Belt.Int.toString(s) ++ ": " ++ Js.String2.slice(c.cue, ~from=0, ~to_=60),
                )
              }
            }
          }
        })

        /* the scene's last shot must hold its own reaction sound */
        let segDur = if li == nLines - 1 && maxEnd.contents > need && !isRecap {
          switch src {
          | Kuku_Edl.Still(_) => Some(maxEnd.contents +. 0.3)
          | _ => None
          }
        } else {
          None
        }

        let _ = Js.Array2.push(
          segments,
          {
            Kuku_Edl.src: src,
            dur: segDur,
            inPoint: None,
            fadeout: None,
            bridge: false,
            cards,
            fx: fxFor(takes),
            takes,
            stillWas: None,
          },
        )

        /* THE PARROT'S BEAT: his echo is a shot of HIM, after the line, alone.
           Multiple takes (the closing trio) cycle with air between them. */
        if Belt.Array.length(pendingMimic) > 0 {
          parrotBeats := parrotBeats.contents + 1
          let t = ref(0.3)
          let mtakes = []
          pendingMimic->Belt.Array.forEach(m => {
            let d = Kuku_Edl.sfxDur(durs, m)
            let _ = Js.Array2.push(mtakes, Kuku_Edl.Effect({name: m, at: Some(t.contents), duck: true}))
            t := t.contents +. d +. 0.5
          })
          let total = t.contents -. 0.5 +. 0.38
          let pic = parrotStill->Belt.Option.getWithDefault(dialoguePic)
          let _ = Js.Array2.push(
            segments,
            {
              Kuku_Edl.src: Kuku_Edl.Still(pic),
              dur: Some(total),
              inPoint: None,
              fadeout: None,
              bridge: false,
              cards: [],
              fx: [],
              takes: mtakes,
              stillWas: None,
            },
          )
        }
      })

      let _ = Js.Array2.push(
        scenes,
        {
          Kuku_Edl.name: "s" ++ Belt.Int.toString(s),
          cue: cueFor(s),
          scoreVol: 0.45,
          cueIn: 0.0,
          segments,
        },
      )
    }
  }

  let cardScene = {
    Kuku_Edl.name: "s0_card",
    cue: cueFor(1),
    scoreVol: 0.4,
    cueIn: 0.0,
    segments: [
      {
        Kuku_Edl.src: Kuku_Edl.Card("t1"),
        dur: Some(3.2),
        inPoint: None,
        fadeout: None,
        bridge: true,
        cards: [],
        fx: [],
        takes: [],
        stillWas: None,
      },
    ],
  }

  /* ACT BREAKS.

     The race is its own act, so the episode turns over on the way into it and
     again on the way out. The device is one card carrying the letter and one
     chime — long enough to register as "that part is finished", short enough that
     a four-year-old does not start wandering off.

     The card is `tsep`, NOT `t1`: t1 says «आज का अक्षर» and opens the episode, so
     repeating it mid-story would read as starting over rather than moving on.

     The break carries the score cue of the act it is leading INTO, so the music
     has already turned over by the time the picture comes up on the new act. It
     is held slightly longer than the chime (2.0s) so the note rings out instead
     of being cut off at the scene boundary — the scene's audio is trimmed to the
     scene's length, so a card shorter than its chime would clip it. */
  let actBreak = (name: string, leadingInto: int): Kuku_Edl.scene => {
    Kuku_Edl.name: name,
    cue: cueFor(leadingInto),
    scoreVol: 0.3,
    cueIn: 0.0,
    segments: [
      {
        Kuku_Edl.src: Kuku_Edl.Card("tsep"),
        dur: Some(2.4),
        inPoint: None,
        fadeout: None,
        bridge: true,
        cards: [],
        fx: [],
        takes: [Kuku_Edl.Effect({name: "chime_act", at: Some(0.0), duck: false})],
        stillWas: None,
      },
    ],
  }

  /* keyed on the scene NAME, not its index, so re-ordering scenes later cannot
     silently move the act breaks somewhere else */
  let withBreaks = []
  scenes->Belt.Array.forEach(sc => {
    if sc.name == "s3" {
      let _ = Js.Array2.push(withBreaks, actBreak("s2_break", 3))
    }
    let _ = Js.Array2.push(withBreaks, sc)
    if sc.name == "s3" {
      let _ = Js.Array2.push(withBreaks, actBreak("s3_break", 4))
    }
  })
  if Belt.Array.length(withBreaks) != Belt.Array.length(scenes) + 2 {
    raise(
      BackendError(
        "act breaks not placed — expected to find a scene named s3 (the race) exactly once",
      ),
    )
  }

  let edl = {Kuku_Edl.scenes: Belt.Array.concat([cardScene], withBreaks)}
  Kuku_Edl.save(Path(dir ++ "/ep6_edl.json"), edl)

  let segCount = Belt.Array.reduce(edl.scenes, 0, (n, s) => n + Belt.Array.length(s.segments))
  Js.log(
    "EDL written: " ++
    Belt.Int.toString(Belt.Array.length(edl.scenes)) ++
    " scenes, " ++
    Belt.Int.toString(segCount) ++
    " segments — " ++
    Belt.Int.toString(parrotBeats.contents) ++
    " parrot beats, " ++
    Belt.Int.toString(anchoredClips.contents) ++ " anchored clips",
  )
  if Belt.Array.length(unmatched) > 0 {
    Js.log("\nUNMATCHED SOUND CUES (" ++ Belt.Int.toString(Belt.Array.length(unmatched)) ++ "):")
    unmatched->Belt.Array.forEach(u => Js.log("  " ++ u))
  }
}

main()
