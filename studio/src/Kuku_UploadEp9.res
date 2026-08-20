/* कुकु और अक्षर — upload Ep9 «ब से बड़ा» to YouTube, UNLISTED, via the
   Cinema_Upload device-flow machinery (tokens already cached at
   ~/.youtube_tokens.json). Prints the VIDEO_ID for the akshar app's show shelf.
   Run from studio/: node src/Kuku_UploadEp9.res.mjs */

let file = "/Users/dusty/kuku-public/KUKU_EP9_BA_SE_BADA.mp4"

let title = "कुकु और अक्षर — ब से बड़ा (Episode 9)"

let desc = "अक्षर घाटी की नौवीं कड़ी: ब से बच्चा, ब से बड़ा — और ब से बचाना। चील की टूटी चोरी की गूँज गुरुकुल के पुराने द्वार तक पहुँचती है, और द्वार का घिसा हुआ हिस्सा गिर पड़ता है। अधखुला द्वार अब हवा खींचता है — जैसे खुला दरवाज़ा। पर्वत-ऋषि अपनी छड़ी से उसे कुछ देर थाम सकते हैं, पर पत्थर फिर टूटेगा; द्वार की खाली जगह हमेशा के लिए वही भर सकता है जो कभी न टूटे — कुकु की साँस से बना अक्षर। लेडा एक पैटर्न पहचानती है, कुकु एक विशाल ब गढ़ता है, और पाँचों पहली बार अपने बड़े रूप में उड़ते हैं। पर सही ताल के बिना उड़ान द्वार की दरार बढ़ा देती है — और खिंचती हवा उस बादल को ऊपर ले जाती है जिस पर बकरी का बच्चा सो रहा था। आज के शब्द — बच्चा, बड़ा, बादल, बकरी, बचाना।

A papercraft Hindi letter show made for our kids."

let main = async () => {
  switch await Cinema_Upload.upload(
    ~file=Cinema_Upload.Path(file),
    ~title=Cinema_Upload.VideoTitle(title),
    ~desc=Cinema_Upload.VideoDesc(desc),
  ) {
  | Cinema_Upload.VideoId(id) => {
      Js.log("EP9 VIDEO_ID -> " ++ id)
      Js.log("watch: https://www.youtube.com/watch?v=" ++ id)
    }
  | exception Cinema_Upload.UploadError(m) => Js.log("UPLOAD FAILED: " ++ m)
  }
}

main()->ignore
