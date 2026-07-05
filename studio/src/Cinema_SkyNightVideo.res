/* Assemble scene 4 (night/home): the 11 frames (Ken Burns) cut to the 258s
   table-read audio - kitchen half, then the sim, weighting the flying and the
   cover longer. */
open Cinema_Backends
module A = Cinema_Assemble

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let v = (p, k, w) => {A.src: Path(dir ++ "/frames/" ++ p ++ ".png"), kind: k, weight: A.Weight(w)}

let main = async () => {
  let shots = [
    v("n1_kitchen", A.KbIn, 18.0),
    v("n2_dinner", A.Static, 12.0),
    v("n3_letter", A.Static, 10.0),
    v("n4_eat", A.KbIn, 22.0),
    v("n5_sink", A.KbOut, 14.0),
    v("n6_touch", A.KbIn, 16.0),
    v("n7_rig", A.Static, 14.0),
    v("n8_fly", A.KbIn, 34.0),
    v("n9_screen", A.Static, 14.0),
    v("n10_asleep", A.KbOut, 24.0),
    v("n11_cover", A.KbIn, 28.0),
  ]
  let out = Path(dir ++ "/SKY-KING_night.mp4")
  let _ = A.assemble(
    ~shots,
    ~audio=Path(dir ++ "/sky-king-night_audio.mp3"),
    ~out,
    ~res={A.width: A.Px(1920), height: A.Px(1080)},
    ~fps=A.Fps(24),
    ~xfade=Seconds(0.7),
  )
  Js.log("NIGHT VIDEO -> " ++ dir ++ "/SKY-KING_night.mp4  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
