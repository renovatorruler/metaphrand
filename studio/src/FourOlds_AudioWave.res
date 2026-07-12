/* THE FOUR OLDS audio play — the adaptation wave. One-way adaptation of
   the locked v14 screenplay corpus: each source scene rides into the
   engine with its AUDIOMAP directive + the audio laws, and comes out
   re-authored for the ear. Resumable; sc03 already done (a03 skips).
   Run per part: PART=1 CLAUDE_STUDIO_TURN_TIMEOUT_MS=360000 CLAUDE_STUDIO_BUDGET=40 node src/FourOlds_AudioWave.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@val @scope("process") external env: Js.Dict.t<string> = "env"

let srcDir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/v14/"
let outDir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/"

/* (part, sourceFile, sceneNumber, cast, audio-map directive) */
let units: array<(int, string, string, array<Seed.voiceCard>, string)> = [
  (1, "sc01_cold_open.scene.txt", "1", [V14Cast.marwani, V14Cast.hale, V14Cast.buck, V14Cast.earlene], "Broadcast collage — audio-native gold. Each transmission gets its own timbre (studio TV, arena PA, hearing-room mic, diner radio at near-zero volume). The chyrons and tickers become anchor speech, naturally. Ends on the fireworks-ban radio announcement, Buck's 'Huh.', a cup set down, CUT to the title spoken by nobody — just the show's theme sting."),
  (1, "sc02_bank.scene.txt", "2", [V14Cast.cricket], "Near-verbatim; the clerk already reads the screen aloud. Signature: fluorescent hum, keyboard, the date stamp's two thunks — the kindness is a SOUND. The officer is cast separately (his card is in the source)."),
  (1, "sc03_barn_net.scene.txt", "3", [V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny], "ALREADY DONE (a03) — skip."),
  (1, "sc04_accord.scene.txt", "4", [V14Cast.cricket, V14Cast.danny, V14Cast.marwani, V14Cast.dutch], "Phone call + broadcast + one pencil SNAP close-mic in an empty room. The rotary dial from memory is eleven digits of sound. Marwani's broadcast rides the parlor TV timbre; the white-rendering graphic becomes the ANCHOR's plain spoken description ('side by side with an artist's rendering of the same flag, boiled white'). Supper cleared for one — carried by a single plate sound and no second voice."),
  (1, "sc06_seizure.scene.txt", "6", [V14Cast.cricket, V14Cast.pell, V14Cast.wade, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny], "Holloway tinny on the dash mount; the visor-mirror gag becomes a beat of silence and the smile arriving in Pell's voice. The doorway stand is a SOUND PATTERN built to be quoted at the wall scene: boots planting on boards, Wade's two-hand cloth sound, the dolly rolling PAST. Keep every canon exchange verbatim."),
  (1, "sc07_fireworks.scene.txt", "7", [V14Cast.cricket, V14Cast.gunny, V14Cast.stitch, V14Cast.dutch, V14Cast.wade], "The proposal around the barn stove; mortars in open air are the show's first big pyro sound (Earth HAS air — let them thunder, the contrast with the silent Moon shells is the design); Wade's cruiser door; Judge Benning's gavel; the steps exchange. Benning is cast in-scene."),
  (1, "sc08_diner.scene.txt", "8", [V14Cast.buck, V14Cast.earlene, V14Cast.cricket, V14Cast.wade], "Establish the diner signature AND the carbon meter's tick as a character. The hummed anthem: one voice, the spatula keeping time on the grill edge, one verse, back to forks — pure audio. Wade's unfilled cup plays as the pot NOT pouring and two dollar bills on formica."),
  (1, "sc09_grave.scene.txt", "9", [V14Cast.cricket, V14Cast.dutch], "Wind, a canning jar set on stone, two old voices. Untouched — the show's quietest scene."),
  (1, "sc10_legion.scene.txt", "10", [V14Cast.mack, V14Cast.cricket, V14Cast.gunny, V14Cast.dutch, V14Cast.stitch], "The stove ticking, contract packets dealt like cards; the manifest and the procurement email READ aloud flat (Mack reads for a living). Cricket's walk-out and return: door bang, gravel, door bang, and 'When's Monday.'"),
  (1, "sc11_baytwo.scene.txt", "11", [V14Cast.vess, V14Cast.pell, V14Cast.tito, V14Cast.mack], "Vess over a PA to two hundred (crowd bed under); Tito's toolbox sounds; 'Keep your tools.' The news crew at the fence is one camera-shutter and walla."),
  (1, "sc12_promotion.scene.txt", "12", [V14Cast.pell, V14Cast.holloway], "Conference-room bed; the room's relief plays as chair creaks and calendar pages; the title spoken in full. The trophy-case beat becomes Pell's footsteps stopping and his lanyard clink in an empty corridor."),
  (1, "sc13_shop.scene.txt", "13", [V14Cast.mack, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.cricket, V14Cast.joss, V14Cast.tito], "Sodium lamps BANG on one by one — the shop signature is born here. The phone coffee can (two phones dropped in tin). Tito's pencil on the drawing. THE OVER-SPEC BEAT lands as written — four lines and the work resumes; the chalk outline becomes the sound of chalk dragged on concrete, long, then lights off breaker by breaker. PART ONE ENDS HERE."),
  (2, "sc14_seminar.scene.txt", "14", [FourOlds_V14_Act2A.facilitator, FourOlds_V14_Act2A.bayTwoMan, V14Cast.joss, V14Cast.mack, V14Cast.pell], "Projector fan, clicker clicks, the slide text READ by the facilitator (trainers read their slides — natural); Mack's pencil copying; the chained clipboard drags down a row. Keep the approved scaffold verbatim where the source has it."),
  (2, "sc15_rage1.scene.txt", "15", [V14Cast.wade, V14Cast.danny], "AUDIO-UPGRADED per the map: the church bell must RING under an earlier beat of this scene, then the hour strikes SILENT under the organ mid-hymn — absence as event. The Legion halyard unclipped, rope through a pulley. The worksheet beat: the BOY asks his dad how to spell 'cookout' — cast the boy in-scene; Danny's silence after is the beat."),
  (2, "sc16_build_repaint.scene.txt", "16", [V14Cast.vess, V14Cast.tito, V14Cast.gunny, V14Cast.dutch, V14Cast.cricket, V14Cast.buck, V14Cast.earlene], "Shop bed + the diner TV calling the repaint (anchor describes the white primer rolling over the stars, plainly); the Cook turning the set OFF — click, and the room tone after — is the beat; Vess's presser under press-room shutter clicks; Cricket's cold-shoulder plays as the pot not pouring and a ticket torn."),
  (2, "sc17_sky_king.scene.txt", "17", [V14Cast.stitch, V14Cast.cricket], "Two voices and a water cooler glug. Untouched."),
  (2, "sc18_anthem.scene.txt", "18", [V14Cast.buck, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny, V14Cast.danny], "The show's biggest crowd sound: one off-key voice against a synthesizer track, rows joining, the track buried alive. The compliance kid is one tablet-case snap shut. 'Not anymore, bud.' closes it."),
  (2, "sc19_lights_out.scene.txt", "19", [V14Cast.joss, V14Cast.tito, V14Cast.buck, V14Cast.earlene, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny], "The mockery arrives as tinny phone-speaker clips; the burrito courier: door bell + a delivery greeting + the kid's ring-light patter; the gift-list TV beat (suits added) lands mid-scene; the shortest Tuesday: coffee poured, cards NOT shuffled, the light cord's click and dark room tone."),
  (2, "sc20_decision.scene.txt", "20", [V14Cast.cricket, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.tito, V14Cast.joss, V14Cast.mack], "Pressure gauge hiss, two knocks answered from INSIDE a crate, bootlaces unlacing CLOSE mic. 'Somebody time me getting in. We'll want a number.' Assent as sound: a grease pencil marking a shelf edge, a man climbing into a crate, a hat set on a chest ('Snug.'), a binder opening. PART TWO ENDS HERE."),
  (2, "sc21_conversion.scene.txt", "21", [V14Cast.dutch, V14Cast.gunny, V14Cast.tito, V14Cast.joss, V14Cast.cricket, V14Cast.stitch], "The vet-counter bell and two lines, cash counted; drums rolling on a truck bed; welding oxygen bottles clinking on a legitimate pallet; Gunny's grease-pencil air math SPOKEN (the audience's one life-support lesson, his register); Tito's lathe on the canisters."),
  (2, "sc22a_mack.scene.txt", "22", [V14Cast.mack, V14Cast.cricket, V14Cast.gunny, V14Cast.dutch, V14Cast.stitch, V14Cast.joss, V14Cast.tito], "Freight sheet flips, a tarp pulled off in one drag, the table. All dialogue already; Cricket's plan statement is the scene's center — keep it verbatim from the source."),
  (2, "sc22b_tradecraft.scene.txt", "23", [V14Cast.mack, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.joss, V14Cast.tito, V14Cast.danny, V14Cast.cricket], "Morse as sound; mailbox flags' spring creak; the cipher drill spoken at a kitchen table; Valley Forge verbatim; the film camera's two frame-winds and a canister dropping into a half-full Folgers can — a very specific rattle."),
  (2, "sc23_physicals.scene.txt", "24", [V14Cast.dutch, V14Cast.cricket, V14Cast.stitch, V14Cast.gunny, V14Cast.joss, V14Cast.tito], "Step-box rhythm as a beat under dialogue; the knee crack — one dry pop, cadence unchanged; the wind-up timer's ring; the crate-test lid lifting; 'It's mine now, son.'"),
  (2, "sc24_proof.scene.txt", "25", [V14Cast.mack, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny], "Air brakes, a clipboard, 'Says non-functional.' / 'It does say that.'; the reassembly as breakers clicking in the practiced order and the trainer hum returning — the sound of the church rebuilt. The driver is cast in-scene."),
  (3, "sc25_suits.scene.txt", "26", [V14Cast.mack, V14Cast.stitch, V14Cast.gunny], "Warehouse forklift; the soapy leak check taught in dialogue ('Hear that? That's a leak. …That's none.'); the wrist tags turning on wire — a tiny metallic tick the scene names once."),
  (3, "sc26_inspection.scene.txt", "27", [V14Cast.pell, V14Cast.mack, V14Cast.dutch, V14Cast.tito, V14Cast.joss], "Pell's espresso sip; the pen tapping a tarp once; 'Floor absorbent.'; the SUV out the gravel and the shop's held breath released as three exhales and a dropped wrench."),
  (3, "sc27_vess.scene.txt", "28", [V14Cast.vess, V14Cast.hale], "Hearing-room bed with gavel and gallery; Hale's draft post is keys clicking then a held backspace — deletion as sound; the panelist button rides a TV timbre over his dark office room tone."),
  (3, "sc28_sendoffs.scene.txt", "29", [V14Cast.cricket, V14Cast.danny, V14Cast.tito, FourOlds_V14_Act2B.lita], "Danny's county line and 'I am a farmer.'; the ZINNIA plays under the self-talk law in Cricket's plain register — the pocketknife through old stitches, the paper-dry rustle, and his few words of spoken discovery, his way, never gushing; Lita's Singer, scissors, the pin through cloth, a kiss, a screen door — nearly wordless and fully audible."),
  (3, "sc29_weigh_in.scene.txt", "30", [V14Cast.pell, V14Cast.mack, V14Cast.joss, FourOlds_V14_Act2B.scaleTech], "The scale's servo hum; numbers read flat; cell three tapped twice with two knuckles; Pell savoring kilograms (his sacrament); the tag dropped into the holder and one camera shutter."),
  (3, "sc30_loadout.scene.txt", "31", [V14Cast.cricket, V14Cast.gunny, V14Cast.joss, V14Cast.tito, V14Cast.mack, V14Cast.danny, FourOlds_V14_Act2B.dockworker], "4 AM gate; torque guns; knock checks down the line; THE DOCKWORKER's three seconds = breath, a latch, held air, and a man muttering block letters as he writes: 'All… clear.' — may be stronger blind than on film. Gate guard cast in-scene."),
  (3, "sc31_launch.scene.txt", "32", [V14Cast.marwani, V14Cast.cricket, V14Cast.buck, V14Cast.vess, V14Cast.pell], "IMPACT LAW governs: inside the crate the launch is structure-borne — hum to shudder to weight, dust ticking off the lid seam. THE PRIMER BURN is a described image: the gala's toast dying under Marwani's live mic, the diner coming off its stools as one sound, an anchor's clinical voice cracking into plain speech. The booster's return lands as one line of ground-crew radio and silence — no tarp, no comment."),
  (3, "sc32_crate_life.scene.txt", "33", [V14Cast.gunny, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen], "Knock-morse with pencil scratch as Dutch transcribes; the sock-footed rotation (fabric, penlight click, a thermos passed — 'Obliged.' whispered); Lindqvist's flashlight sweep is boots on deck plating and a hatch pushed flush; SHEN'S PALM = the glove seal peeling, then EIGHT SECONDS of nothing but Cricket's held breath — the show's second spent silence; Brandt's call breaks it."),
  (3, "sc33_offer.scene.txt", "34", [V14Cast.marwani, V14Cast.danny, V14Cast.joss, V14Cast.cricket], "The aide's phone at porch distance (small warm speaker timbre); wind in the shelterbelt; Ridge Road morse under night sounds; the pad filling rendered as Cricket's pencil and his few muttered copy-words; 'Dawes out.' and the sky."),
  (3, "sc34_tli.scene.txt", "35", [V14Cast.cricket, V14Cast.stitch, V14Cast.dutch, V14Cast.pell, V14Cast.vess], "The burn as one long structural push, straps creaking; NO ABORT FROM HERE muttered as he boxes it (men mutter what they write); the Sky King payoff untouched; the act closes on Cricket's thumb on a knuckle — carried by the line before it and held room tone. PART THREE ENDS HERE."),
  (4, "sc35_landing.scene.txt", "36", [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny], "The slam INSIDE the bay: rack strain, a hinge complaining ONCE (plant the sound — it pays at the departure); the sound-off with the gap where Stitch should be; the rover theft heard ONLY on the olds' private loop while Brandt's loop stays routine — dual-channel montage, the audio version of cross-cutting."),
  (4, "sc36_empty_sites.scene.txt", "37", [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, FourOlds_V14_Act3.streamer, V14Cast.buck, V14Cast.earlene], "Cue-card paper in glove fingers; 'The artifact is… not present.'; the streamer's donation chimes and caps-lock joy; Buck's slow smile arrives purely in his voice."),
  (4, "sc37_reveal.scene.txt", "38", [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.buck, V14Cast.earlene, V14Cast.gunny, FourOlds_V14_Act3.streamer], "THE CENTERPIECE — the described image: Brandt's climb as breath and boot-crunch on comms; the loop silent one beat too long; then Earth sees it FOR us in this order — a controller's half-sentence dying, Roy's ('Where's Earl and them?…' / 'There they are.'), the panelist identifying the suits, BRANDT reading the four crate stencils aloud on the open loop (the title landing by voice), Warsaw clapping around one phone. Nobody describes prettily; every voice in its own register."),
  (4, "sc38_standoff.scene.txt", "39", [V14Cast.brandt, V14Cast.cricket, V14Cast.stitch, V14Cast.gunny, V14Cast.shen, FourOlds_V14_Act3.lawyer1, FourOlds_V14_Act3.lawyer2], "Natively audio: an argument on an open loop the world is on. The lawyers on speakerphone timbre. Stitch's line lands from a seated voice — lower, effortful, and the ear can tell. 'We came in the mail.' verbatim."),
  (4, "sc39_wall.scene.txt", "40", [V14Cast.brandt, V14Cast.cricket, V14Cast.gunny, V14Cast.marwani, V14Cast.shen, V14Cast.buck], "The wall QUOTES the seizure's sound pattern: boots planting in sequence on regolith-silent comms (breath and suit servos carry it). 'Come through us.' The USA-USA montage as layered crowd beds (diner, fairground carousel organ, overpass horns). Marwani patched in warm; 'NASA's civilian…' verbatim; the loop hangs empty after."),
  (4, "sc40_hale.scene.txt", "41", [V14Cast.hale, V14Cast.vess, V14Cast.buck], "The office laugh alone in the dark — a man laughing with no words is pure audio; the presser: paper folded twice CLOSE to the mic, 'I can't read this one.', the detonation, bedlam of shutters; the Cook's burners clicking on one by one, all of them."),
  (4, "sc41_vess_pell.scene.txt", "42", [V14Cast.vess, V14Cast.pell], "Pages laid down one at a time on a desk blotter, counted by sound; her heels leaving unhurried; Pell alone with the HVAC — the show's loneliest room tone."),
  (4, "sc42_look_up.scene.txt", "43", [V14Cast.hale, V14Cast.danny, V14Cast.joss, V14Cast.stitch, V14Cast.gunny, V14Cast.buck, V14Cast.earlene], "THE WAVE AS RADIO: the post read aloud off the register phone ('Two words. Look up.'); Danny keys two clicks; one far station answers; then ten; then the band BLOOMS — hams relaying city names like a roll call, static thick with two-twos on every frequency until the noise floor of the planet is the knock code; on the Moon, seven breaths listening to it through one earpiece; Gunny turns the burner down — a valve, a smaller flame hiss."),
  (4, "sc43_fourth.scene.txt", "44", [V14Cast.gunny, V14Cast.cricket, V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.stitch, V14Cast.tito, V14Cast.buck], "'…is that a burger?' and the world's laughter in cutaway beds; the plated burger set at the empty chair is one plate-on-table sound the scene names; Adams read slow, the bells line landing; THE SHELLS UNDER THE IMPACT LAW: no bang, ever — sub-bass concussion through boots and suits, in the chest, and THE REQUIRED EXCHANGE: Earth-side flags the silence thinking the feed dropped ('There's no sound—') and an old answers plainly ('No air up here. You feel 'em.'), surface voices confirm ('You feel that?' / 'In the boots.'); then 'It's Independence Day.' / 'God bless America.' and the third concussion rolling through everything like weather."),
  (4, "sc44_coda.scene.txt", "45", [V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny, V14Cast.brandt, V14Cast.shen, V14Cast.lindqvist, V14Cast.danny, V14Cast.buck, V14Cast.earlene], "The optimism beat (European worry in checklists, 'Don't worry. We'll get home.' flat); THE JAM: the planted hinge complaint returns, latches refusing, the window in minutes — Dutch states the price plainly; Cricket's pry bar, boots planting, latches walking shut under his weight, 'GO.', the ascent as felt force fading to nothing; two-two through the glass answered from the ground; the cabin: foil unwrapping, Shen eating, a pencil on foil; MONTHS ON: the diner (meter gone — four screws backing out is its exit), Danny's net with the three-second lag, the grandson-denier exchange verbatim, the pay stub half-muttered; the Ranger's walk as suit servos and one glove striking each staff; his two clicks into the worldwide bloom, three seconds, and the planet answers. Final sound: the knock code as the noise floor of the Earth, then one steady carrier tone, out."),
]

type job = {seed: Seed.sceneSeed, out: string}

let mkJob = ((_, srcFile, num, cast, note)): job => {
  let raw = readFileSync(srcDir ++ srcFile, "utf8")
  let firstLine = Belt.Array.getExn(Js.String2.split(raw, "\n"), 0)
  let srcSlug = switch Js.String2.split(firstLine, " — ") {
  | [_, s] => s
  | _ => firstLine
  }
  let base = Js.String2.replace(srcFile, ".scene.txt", "")
  let audioBase = "a" ++ Js.String2.sliceToEnd(Js.String2.replace(base, "sc", ""), ~from=0)
  {
    seed: {
      id: "audio-" ++ base,
      slug: "SCENE " ++ num ++ ". " ++ srcSlug,
      logline: "Faithful audio adaptation of the locked screenplay scene, per this directive: " ++ note,
      cast,
      layer: {
        peshat: "the same scene as the locked master, re-authored so every event reaches the listener through sound and speech alone",
        sod: "the master's meaning, comedy, and turns survive intact; what the camera carried, the ear now carries — nothing reverent added, nothing load-bearing lost",
      },
      beats: [
        {
          who: switch cast {
          | [] => "ENSEMBLE"
          | _ => (Belt.Array.getExn(cast, 0): Seed.voiceCard).name
          },
          want: "the scene to play for a blind listener exactly as the master plays for a viewer",
          wall: "everything the master carried visually",
          turn: "every visual beat re-carried per the audio laws — sound, self-talk, described image, felt force — and every kept line landing in its speaker's register",
          subtext: "adaptation, not summary: the scene's full dramatic footprint, for the ear",
        },
      ],
      rules: Belt.Array.concat(
        [
          "THE DIRECTIVE for this scene: " ++ note,
          "THE SOURCE — the locked screenplay master. Every event, every kept line of dialogue (verbatim where marked canon in spirit), and every turn must survive, re-authored for the ear. Dialogue may gain wrylies and placement tags; visual action MUST convert (sound, self-talk, described image, felt force) or be replaced per the laws; nothing may be summarized away:\n\n" ++ raw,
          "LENGTH: match the source's dramatic footprint — do not pad, do not compress the turns.",
        ],
        AudioRules.common,
      ),
    },
    out: outDir ++ audioBase ++ ".scene.txt",
  }
}

let runOne = async (j: job) => {
  let path = Cinema_Backends.Path(j.out)
  let done_ = existsSync(j.out) && Write.verify(path) == Ok()
  if done_ {
    Js.log("SKIP " ++ j.seed.id)
  } else {
    let sc = await Write.writeScene(~seed=j.seed, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    let sc2 = await Write.liftDialogue(~path, ~maxTries=3)
    let _ = Write.emit(sc2, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("OK   " ++ j.seed.id)
    | Error(m) => Js.log("BAD  " ++ j.seed.id ++ " — " ++ m)
    }
  }
}

let main = async () => {
  let part = switch Js.Dict.get(env, "PART") {
  | Some(p) => Belt.Int.fromString(p)->Belt.Option.getWithDefault(1)
  | None => 1
  }
  let jobs = units->Belt.Array.keep(((p, _, _, _, _)) => p == part)->Belt.Array.map(mkJob)
  let failed = []
  let n = Belt.Array.length(jobs)
  let rec go = async i =>
    if i < n {
      let j = Belt.Array.getExn(jobs, i)
      switch await (async () => await runOne(j))() {
      | _ => ()
      | exception Write.WriteError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (gate): " ++ m)
        }
      | exception Session.SessionError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (session): " ++ m)
        }
      }
      await go(i + 1)
    }
  await go(0)
  Js.log(
    "PART " ++
    Belt.Int.toString(part) ++
    " DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
