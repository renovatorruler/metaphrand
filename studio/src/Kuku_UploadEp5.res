/* कुकु और अक्षर — upload Ep5 «प से पुल» to YouTube, UNLISTED, via the
   Cinema_Upload device-flow machinery (tokens already cached at
   ~/.youtube_tokens.json). Prints the VIDEO_ID for the akshar app's show shelf.
   Run from studio/: node src/Kuku_UploadEp5.res.mjs */

let file = "/Users/dusty/kuku-public/KUKU_EP5_LIPSYNC.mp4"

let title = "कुकु और अक्षर — प से पुल (Episode 5)"

let desc = "अक्षर घाटी की पाँचवीं कड़ी: आज का अक्षर प। पुल टूट जाता है, और कुकु को एक सुनहरा प बनाना है — पर अक्षर तभी खड़ा होता है जब नीचे मज़बूत पत्थर हो। प से पुल, प से पत्थर, प से पैर, प से पतंग, प से पेड़, प से पापा।

A papercraft Hindi letter show made for our kids."

let main = async () => {
  switch await Cinema_Upload.upload(
    ~file=Cinema_Upload.Path(file),
    ~title=Cinema_Upload.VideoTitle(title),
    ~desc=Cinema_Upload.VideoDesc(desc),
  ) {
  | Cinema_Upload.VideoId(id) => {
      Js.log("EP5 VIDEO_ID -> " ++ id)
      Js.log("watch: https://www.youtube.com/watch?v=" ++ id)
    }
  | exception Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED: " ++ m)
  }
}

main()->ignore
