# Krea submission runbook

Written 2026-08-17 while submitting s5job2. Two things here are not in Krea's docs and cost an hour to find.

## Local files cannot be uploaded to Krea on this account

`krea upload <file>` exists in the CLI (v0.1.6) but the server answers `MCP error -32602: Tool upload_asset not found`. Base64 data URIs are not a way round it either: the input schema caps every image URI at `maxLength: 1024`, which is about 750 bytes of image, so the "base64 data URI" the docs mention is unusable for real plates.

**Use Higgsfield as the file host.** `higgsfield upload create <file>` costs nothing, returns a UUID, and the asset is served publicly from CloudFront. Verify with a HEAD before submitting — a 200 and the right byte count.

```
ID=$(higgsfield upload create path/to.png)
URL=https://d2ol7oe51mr4n9.cloudfront.net/user_37I5NaFzvjAFORcmzIOL6HHcIPZ/$ID.png
curl -s -o /dev/null -w '%{http_code} %{size_download}\n' "$URL"
```

`higgsfield upload list --image --json` maps IDs to URLs. **The Higgsfield account is shared** — that listing contains the co-user's uploads too. Only ever use IDs returned by your own `create` call in the same session. Fetching by timestamp is how another user's work got pulled into this project once already.

## The CLI sends a deprecated field name

`krea generate video --start-image ...` serialises to `startImage`, which the API retired on 2026-06-19. It returns 422 with `deprecated_field / replacement: start_image`. Nothing is charged.

Do not use the named flags for anything the schema names in snake_case. Pass raw fields with `-i`:

```
krea generate video -m bytedance/seedance-2-5 \
  -p "$(cat emitted/<job>.prompt.txt)" \
  -i start_image="$START" \
  -i reference_images="$REFS_JSON_ARRAY" \
  -i duration=20 \
  -i resolution=720p \
  -i generate_audio=true \
  -i seed=20260817 \
  --json
```

`reference_images` is a JSON array string. `generate_audio` should be **true** even though we dub in Russian afterwards: the model's own generated speech is what marks where it animated each mouth, and that is how dub placement is measured. Guessing placement cost three wrong passes on an earlier shot.

Set a `seed`. A near-miss can then be re-rolled with one variable changed instead of rolling the dice again.

## The limits belong to the MODEL, not the vendor

Krea and Higgsfield both resell Seedance 2.5, so their ceilings are identical and there is no capability reason to prefer one. `higgsfield model get seedance_2_5` carries the rules explicitly:

- `at most 50 reference media items are allowed in total`
- `at most 30 images are allowed (counting start_image and end_image)`
- `duration` is a plain integer, no enum, no ceiling in the schema
- `start_image` / `end_image` only work with `mode: omni_reference`
- `t2v` accepts NO reference media at all
- `audio_references` exists on both

Do not describe one of these platforms as having a longer duration, more references, or a bigger asset budget than the other. The only real differences are billing, the CLI's own bugs, and which account is funded.

## Two things I had wrong about Higgsfield specifically

**Higgsfield does NOT cap Seedance 2.5 at 12 seconds.** `higgsfield model get seedance_2_5` shows `duration` as a plain integer, default 5, with no enum and no ceiling. The 5/8/12 figures that got repeated as a platform limit were just the durations the earlier EP1 jobs happened to use — an assumption promoted to a fact, which is the same failure as inferring anything else without checking the artefact.

**`higgsfield generate cost` exists**, so a job can be priced before it is run. There is no reason to submit an unpriced job. Measured 2026-08-17 for s5job2 (20s, omni_reference, start image + 8 image references):

| duration | resolution | credits |
|---|---|---|
| 20s | 480p / 720p | 130 |
| 20s | 1080p | 180 |
| 12s | 720p | 78 |

Costing requires the same media flags as the real call, and `--image-references` must be **repeated once per asset** — a comma-joined list is rejected as "neither a UUID nor an existing file path", and building the flags into an unquoted shell string trips "Too many positional args". Use a bash array.

```
REFARGS=(); while read -r id; do REFARGS+=(--image-references "$id"); done < ids.txt
higgsfield generate create seedance_2_5 --prompt "$P" --duration 20 --resolution 720p \
  --aspect-ratio 16:9 --mode omni_reference --generate-audio true \
  --start-image "$STARTID" "${REFARGS[@]}" --json
```

`--mode omni_reference` is required when passing references; `t2v` ignores them, and omni_reference errors if none are supplied. Media flags take a UUID **or a local path**, which is auto-uploaded — so for Higgsfield the separate upload step is optional.

## Status as of 2026-08-17

Krea: s5job2 validated and reached billing, then returned **402 INSUFFICIENT_BALANCE** despite the account being funded — so the problem is the API key's workspace or pay-as-you-go not being enabled, not the balance. Left unresolved; Higgsfield ran the job instead.

Higgsfield: 831.12 credits. s5job2 submitted as `5a220460-2a50-42a4-acbf-f35738789f06` at 130 credits.

Uploaded asset URLs for s5job2 are filed as `emitted/s5job2.uploaded_urls.tsv`. CloudFront links may expire; re-upload rather than trusting them after a long gap.
