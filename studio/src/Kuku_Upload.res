/* कुकु और अक्षर — upload the finished episodes to YouTube (UNLISTED, via the
   Cinema_Upload device-flow machinery; token already cached). Prints one
   VIDEO_ID per episode for the akshar app's show shelf to embed.
   Run from studio/: node src/Kuku_Upload.res.mjs */
let episodes = [
  (
    "/Users/dusty/kuku-public/KUKU_EP1.mp4",
    "कुकु और अक्षर — क से कालू (Episode 1)",
    "अक्षर घाटी की पहली कड़ी: आज का अक्षर क। कुकु को एक कुत्ता चाहिए — और कुएँ से आता है कालू। A papercraft Hindi letter show made for our kids.",
  ),
  (
    "/Users/dusty/kuku-public/KUKU_EP2_V2.mp4",
    "कुकु और अक्षर — म से माँ (Episode 2)",
    "अक्षर घाटी की दूसरी कड़ी: आज का अक्षर म। मिटासुर म चुरा लेता है — और अक्षर वीर उसे वापस लाते हैं। A papercraft Hindi letter show made for our kids.",
  ),
]

let main = async () => {
  let results = []
  for i in 0 to Belt.Array.length(episodes) - 1 {
    switch Belt.Array.get(episodes, i) {
    | Some((file, title, desc)) =>
      try {
        let Cinema_Upload.VideoId(id) = await Cinema_Upload.upload(
          ~file=Cinema_Upload.Path(file),
          ~title=Cinema_Upload.VideoTitle(title),
          ~desc=Cinema_Upload.VideoDesc(desc),
        )
        Js.log("EPISODE " ++ Belt.Int.toString(i + 1) ++ " -> " ++ id)
        Belt.Array.push(results, id)->ignore
      } catch {
      | Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED (ep " ++ Belt.Int.toString(i + 1) ++ "): " ++ m)
      }
    | None => ()
    }
  }
  Js.log("DONE " ++ Belt.Int.toString(Belt.Array.length(results)) ++ "/2")
}
main()->ignore
