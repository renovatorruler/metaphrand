/* The FULL cold-open video: the plane montage (mood-set) into the dialogue, cut
   to the table-read audio. Cockpit angles anchor the dialogue; scenic stills and
   the jet-reveal frame are cutaways. All assembled (no Sora beyond the 2 clips). */
open Cinema_Backends
module A = Cinema_Assemble

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let v = (p, k, w) => {A.src: Path(dir ++ "/" ++ p), kind: k, weight: A.Weight(w)}

let main = async () => {
  let shots = [
    /* --- mood-set montage (~0-43s, pure music) --- */
    v("clips/mood_plane_sora.mp4", A.Video, 8.0),
    v("frames/mood_land_gpt2.png", A.KbIn, 7.0),
    v("frames/mood_plane2_gpt2.png", A.KbOut, 7.0),
    v("frames/mood_mountain_gpt2.png", A.KbIn, 7.0),
    v("frames/mood_plane3_gpt2.png", A.KbOut, 7.0),
    v("clips/mood_plane4_sora.mp4", A.Video, 8.0),
    /* --- dialogue: cockpit anchors + cutaways --- */
    v("frames/mood_cockpit_birdy_gpt2.png", A.KbIn, 11.0), // establisher + "you there still" / "I'm here"
    v("frames/cockpit_birdy_profile.png", A.KbOut, 11.0), // "I wish you could see this... sky's gone gold"
    v("frames/mood_mountain_gpt2.png", A.Static, 8.0), // "pink on the tops of them"
    v("frames/cockpit_birdy_yoke.png", A.KbIn, 11.0), // "you're missing it... nobody up here but me"
    v("frames/jet_reveal.png", A.Static, 10.0), // "I got some company now... couple of jets"
    v("frames/cockpit_birdy_yoke.png", A.KbOut, 10.0), // "I can see one of the fellas in there"
    v("frames/cockpit_birdy_profile.png", A.KbIn, 10.0), // "those are escorts" / "they fly nice"
    v("frames/mood_land_gpt2.png", A.Static, 8.0), // "the light's going... easing her down"
    v("frames/mood_cockpit_birdy_gpt2.png", A.KbOut, 11.0), // "I don't think I can do that yet. I'm sorry"
    v("frames/jet_reveal.png", A.Static, 9.0), // closer — plane and jets holding
  ]
  let out = Path(dir ++ "/SKY-KING_coldopen.mp4")
  let _ = A.assemble(
    ~shots,
    ~audio=Path(dir ++ "/cold_open_tableread_engine_v1.mp3"),
    ~out,
    ~res={A.width: A.Px(1920), height: A.Px(1080)},
    ~fps=A.Fps(24),
    ~xfade=Seconds(0.7),
  )
  Js.log("COLD OPEN VIDEO -> " ++ dir ++ "/SKY-KING_coldopen.mp4  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
