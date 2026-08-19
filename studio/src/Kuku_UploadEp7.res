/* कुकु और अक्षर — upload Ep7 «आ की रात» to YouTube, UNLISTED, via the
   Cinema_Upload device-flow machinery (tokens already cached at
   ~/.youtube_tokens.json). Prints the VIDEO_ID for the akshar app's show shelf.
   Run from studio/: node src/Kuku_UploadEp7.res.mjs */

let file = "/Users/dusty/kuku-public/KUKU_EP7.mp4"

let title = "कुकु और अक्षर — आ की रात (Episode 7)"

let desc = "अक्षर घाटी की सातवीं कड़ी: आज कोई नया व्यंजन नहीं — आज आती है आ की मात्रा। फ्यूरिया के जन्मदिन की रात, पापा दूर बाज़ार गए हैं, और बच्चे अपने हाथों से एक उपहार बनाते हैं: एक लिखा हुआ तारा। एक नन्ही साथी अक्षर के पास खड़ी होती है — और हर आवाज़ लंबी हो जाती है। क से का, त से ता, र से रा… और आ से आम।

A papercraft Hindi letter show made for our kids."

let main = async () => {
  switch await Cinema_Upload.upload(
    ~file=Cinema_Upload.Path(file),
    ~title=Cinema_Upload.VideoTitle(title),
    ~desc=Cinema_Upload.VideoDesc(desc),
  ) {
  | Cinema_Upload.VideoId(id) => {
      Js.log("EP7 VIDEO_ID -> " ++ id)
      Js.log("watch: https://www.youtube.com/watch?v=" ++ id)
    }
  | exception Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED: " ++ m)
  }
}

main()->ignore
