# Uploading to YouTube — the studio process

How a finished episode or video gets from `out/` to an unlisted YouTube link. Everything runs through `studio/src/Cinema_Upload.res` (device-flow OAuth + resumable upload); per-video drivers are tiny ReScript files following one pattern. No Python, no youtube-dl, no manual browser uploads.

## Prerequisites (already in place on this machine)

Two files in the home directory, both created once and reused forever: `~/.youtube_oauth.json` holds the Google OAuth client (`client_id`, `client_secret`) for the device flow; `~/.youtube_tokens.json` holds the cached access/refresh tokens and is rewritten automatically (mode 0600) whenever auth succeeds. The channel is whichever Google account approved the device flow.

## The normal upload (tokens valid)

1. **Stage the file.** Finished deliverables are staged in `/Users/dusty/kuku-public/` (repo media stays out of git): `cp <repo>/…/out/FINAL.mp4 /Users/dusty/kuku-public/NAME.mp4`.
2. **Write the driver** — copy an existing one (`src/Kuku_UploadEp8.res` is the current template) and change three things: the `file` path, the `title`, and the Hindi `desc`. The driver calls `Cinema_Upload.upload(~file, ~title, ~desc)` and prints the video ID. Uploads are UNLISTED by default (set inside `Cinema_Upload`).
3. **Build and run** from `studio/`: `npx rescript && node src/Kuku_UploadEp8.res.mjs`. Output on success: the `youtu.be` watch URL, the studio edit URL, and `EP8 VIDEO_ID -> <id>`.
4. **Use the ID.** For कुकु episodes the ID goes into the akshar app's show shelf (`akshar/app/src/screens/AksharGhati.res`, `episodes` array, plus a 640×360 poster in `app/public/shows/`), committed and pushed — Vercel deploys it.

## When the upload fails with "token refresh failed"

The refresh token has expired or been revoked; re-run the device flow: `node src/Kuku_UploadAuth.res.mjs`. It prints `VERIFICATION_URL: https://www.google.com/device` and a `USER_CODE`, then polls. The author opens the URL on any device, enters the code, approves — the poller prints `AUTHORIZED` and re-caches tokens. Then re-run the upload driver. Notes from the 2026-08-10 EP8 upload: device codes expire if unused (a stale code dies silently — always relay the newest code); the auth driver now catches and prints the real failure reason instead of dying as an unhandled promise rejection; approval sometimes lands minutes later, so keep the poller running in the background rather than restarting it (restarting invalidates the shown code).

## Rules that apply every time

Deliverables are never committed to git (media is ignored); the staged copy in `kuku-public/` is also what the tailscale dailies shelf serves for review, so staging does double duty. Review cuts (no title/credits) are for approval only — the file that uploads is the full EPISODE cut with title and credits. Upload only after the author approves the final cut, and publish visibility changes (unlisted → public) are the author's manual decision in YouTube Studio, never the driver's. Titles/descriptions for कुकु follow the EP7/EP8 shape: Hindi title «कुकु और अक्षर — <episode>» + Hindi description ending with the English line "A papercraft Hindi letter show made for our kids."

## Existing drivers (as of 2026-08-13)

`Kuku_UploadEp5.res` · `Kuku_UploadEp6.res` · `Kuku_UploadEp7.res` (yt sMZCL1Jf_Jg) · `Kuku_UploadEp8.res` (yt 5VnXi4OPeGM) · `SkyKing_Upload.res` / `Cinema_SkyUpload.res` (SkyKing project). The कर्क music video will get `Kark_UploadMV.res` on the same pattern when its final cut is approved.
