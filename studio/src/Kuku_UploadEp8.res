/* कुकु और अक्षर — upload Ep8 «च से चील» to YouTube, UNLISTED, via the
   Cinema_Upload device-flow machinery (tokens already cached at
   ~/.youtube_tokens.json). Prints the VIDEO_ID for the akshar app's show shelf.
   Run from studio/: node src/Kuku_UploadEp8.res.mjs */

let file = "/Users/dusty/kuku-public/KUKU_EP8.mp4"

let title = "कुकु और अक्षर — च से चील (Episode 8)"

let desc = "अक्षर घाटी की आठवीं कड़ी: च से चाँद, च से चम्मच — और च से चील। एक चालाक चील, जिसने घोर तपस्या से वरदान पाया है: आकाश में उसे कोई हरा न पाए। चमकीली चीज़ों की एक चाल बच्चों को ऊँची चट्टान तक ले जाती है — और वापसी का तख़्ता ग़ायब है। लेडा की गिनती, कैस्टर की दरार, कुकु का अक्षरों का पुल, फ्यूरिया की दौड़ और तानसेन की आवाज़ें — सब मिलकर दादी तक ख़बर पहुँचाते हैं। और उस शाम बच्चे पहली बार सुनते हैं वो पुरानी कथा: हम उड़ना भूल गए। आज के शब्द — चील, चाल, चक्कर, चुप, चाँद, चम्मच।

A papercraft Hindi letter show made for our kids."

let main = async () => {
  switch await Cinema_Upload.upload(
    ~file=Cinema_Upload.Path(file),
    ~title=Cinema_Upload.VideoTitle(title),
    ~desc=Cinema_Upload.VideoDesc(desc),
  ) {
  | Cinema_Upload.VideoId(id) => {
      Js.log("EP8 VIDEO_ID -> " ++ id)
      Js.log("watch: https://www.youtube.com/watch?v=" ++ id)
    }
  | exception Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED: " ++ m)
  }
}

main()->ignore
