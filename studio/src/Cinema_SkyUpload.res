/* Upload the montage to YouTube as UNLISTED and print the link. Tries the cached
   token first; if auth fails, reports it so we can run the device flow. */
open Cinema_Upload
@val @scope("process") external argv: array<string> = "argv"

let main = async () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(file), Some(title)) =>
    try {
      let VideoId(id) = await upload(
        ~file=Path(file),
        ~title=VideoTitle(title),
        ~desc=VideoDesc("SKY KING — unlisted preview (Sora 2 Pro + gpt-image-2, scored)."),
      )
      Js.log("LINK: https://youtu.be/" ++ id)
    } catch {
    | UploadError(m) => Js.log("UPLOAD ERROR: " ++ m)
    }
  | _ => Js.log("usage: Cinema_SkyUpload <file> <title>")
  }

main()->ignore
