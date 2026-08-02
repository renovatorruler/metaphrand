/* कुकु और अक्षर — upload Ep6 «त से तोता» to YouTube, UNLISTED, via the
   Cinema_Upload device-flow machinery (tokens already cached at
   ~/.youtube_tokens.json). Prints the VIDEO_ID for the akshar app's show shelf.
   Run from studio/: node src/Kuku_UploadEp6.res.mjs */

let file = "/Users/dusty/kuku-public/KUKU_EP6.mp4"

let title = "कुकु और अक्षर — त से तोता (Episode 6)"

let desc = "अक्षर घाटी की छठी कड़ी: आज का अक्षर त। घाटी में एक हरा तोता आता है — तानसेन — जो सबकी आवाज़ में बोलता है। पर जो सुनता है, वही दोहराता है… त से तोता, त से तालाब, त से तना, त से तीन, त से ताली, त से तानसेन।

A papercraft Hindi letter show made for our kids."

let main = async () => {
  switch await Cinema_Upload.upload(
    ~file=Cinema_Upload.Path(file),
    ~title=Cinema_Upload.VideoTitle(title),
    ~desc=Cinema_Upload.VideoDesc(desc),
  ) {
  | Cinema_Upload.VideoId(id) => {
      Js.log("EP6 VIDEO_ID -> " ++ id)
      Js.log("watch: https://www.youtube.com/watch?v=" ++ id)
    }
  | exception Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED: " ++ m)
  }
}

main()->ignore
