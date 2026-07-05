/* SKY KING — upload a finished cut to YouTube (UNLISTED). Refreshes the cached
   token and resumable-uploads. If the refresh token is dead, prints the device-
   flow code so the user can re-authorize on their phone.
   Run: node src/SkyKing_Upload.res.mjs <file> <title> <desc> */
@val @scope("process") external argv: array<string> = "argv"

let main = async () => {
  let file = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let title = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("untitled")
  let desc = Belt.Array.get(argv, 4)->Belt.Option.getWithDefault("")
  if file == "" {
    Js.log("usage: node src/SkyKing_Upload.res.mjs <file> <title> <desc>")
  } else {
    try {
      let Cinema_Upload.VideoId(id) = await Cinema_Upload.upload(
        ~file=Cinema_Upload.Path(file),
        ~title=Cinema_Upload.VideoTitle(title),
        ~desc=Cinema_Upload.VideoDesc(desc),
      )
      Js.log("UPLOADED (unlisted): https://youtu.be/" ++ id)
    } catch {
    | Cinema_Upload.UploadError(m) =>
      Js.log("UPLOAD FAILED: " ++ m)
      Js.log("If this is an auth error, the token needs re-authorizing (device flow, approve on phone).")
    }
  }
}
main()->ignore
