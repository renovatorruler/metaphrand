/* Re-authorize YouTube uploads (device flow): prints VERIFICATION_URL + USER_CODE,
   then polls until approved on the phone; tokens re-cache at ~/.youtube_tokens.json.
   Run from studio/: node src/Kuku_UploadAuth.res.mjs */
let main = async () => {
  let pending = await Cinema_Upload.authStart()
  switch await Cinema_Upload.authPoll(pending) {
  | () => ()
  | exception Cinema_Upload.UploadError(m) => Js.log("AUTH FAILED: " ++ m)
  }
}
main()->ignore
