/* The opening MUSIC-VIDEO MONTAGE of the plane flying: the two Sora clips + the
   gpt-image-2 stills (Ken Burns), cross-dissolved and cut to the music. No more
   Sora spend. ~45s. */
open Cinema_Backends
module A = Cinema_Assemble

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  /* first 45s of the bed, faded out, as the montage soundtrack. */
  let music = dir ++ "/clips/montage_music.mp3"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", dir ++ "/cold_open_rs/music_outro.mp3",
    "-t", "45", "-af", "afade=t=out:st=43:d=2", "-codec:a", "libmp3lame", "-b:a", "160k", music,
  ])

  let shots = [
    {A.src: Path(dir ++ "/clips/mood_plane_sora.mp4"), kind: A.Video, weight: A.Weight(8.0)},
    {A.src: Path(dir ++ "/frames/mood_land_gpt2.png"), kind: A.KbIn, weight: A.Weight(7.0)},
    {A.src: Path(dir ++ "/frames/mood_plane2_gpt2.png"), kind: A.KbOut, weight: A.Weight(7.0)},
    {A.src: Path(dir ++ "/frames/mood_mountain_gpt2.png"), kind: A.KbIn, weight: A.Weight(7.0)},
    {A.src: Path(dir ++ "/frames/mood_plane3_gpt2.png"), kind: A.KbOut, weight: A.Weight(8.0)},
    {A.src: Path(dir ++ "/clips/mood_plane4_sora.mp4"), kind: A.Video, weight: A.Weight(8.0)},
  ]

  let out = Path(dir ++ "/SKY-KING_montage.mp4")
  let _ = A.assemble(
    ~shots,
    ~audio=Path(music),
    ~out,
    ~res={A.width: A.Px(1920), height: A.Px(1080)},
    ~fps=A.Fps(24),
    ~xfade=Seconds(0.7),
  )
  Js.log("MONTAGE -> " ++ dir ++ "/SKY-KING_montage.mp4  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
