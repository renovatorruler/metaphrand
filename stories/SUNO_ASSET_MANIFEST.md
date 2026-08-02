# Suno audio asset manifest

Inventory date: 2026-08-02.

This manifest identifies the selected or production-relevant Suno audio currently
present in the repository workspace. Durations come from `ffprobe`; SHA-256 hashes
come from `shasum -a 256`.

The repository now ignores new MP3 files. **Tracked** below means the binary is an
older exception already recoverable from Git history. **Local-only** means the file
is present on this Mac but is not recoverable from Git. A second folder on the same
disk is not counted as a backup.

| Asset | Role | Duration | Bytes | SHA-256 | Protection |
| --- | --- | ---: | ---: | --- | --- |
| `amal/audio/uth-re-jhujhar_invocation_suno_2026-07-25.mp3` | Selected `उठ रे जुझार` album invocation | 7:59.400 | 10,481,142 | `5cfd25e6dc166d786f7df0f10fbfd13d51ac5b2d8aee2a8324ecd072ef3e18d9` | **LOCAL-ONLY — external backup required** |
| `amal/audio/jhujhar_charan-song_rajasthani_v1_2026-06-21.mp3` | Earlier full Jhujhar series ballad | 4:18.040 | 5,928,774 | `cd202c8632e095ab392c28340f4ac31690ea7f9a2af1af695a4b7be198ef7ee3` | Tracked legacy asset |
| `amal/audio/amal_title_saka_suno_v1.mp3` | AMAL instrumental saka title direction | 3:03.480 | 4,266,726 | `c5dccb44ef3c9130fa19f9d5ad1e5a236ac4c69030371a981e51a900475a0311` | Tracked legacy asset |
| `amal/audio/amal_score_rudaali_indian_suno.mp3` | Earlier Rudaali-related Suno source; use the locked processed/library direction instead | 0:36.960 | 720,774 | `caccabc9380bc4d4f45200b678e0bfef3ad8d9adcdb0831c9e2dee799e4deb71` | Tracked legacy asset |
| `kuku/titles/title_song.mp3` | Kuku v1 title render; superseded by v2 lyrics | 1:07.400 | 1,635,144 | `33424e11dd558e743d7f1e55834009ec11d33fd25cb6f9f29f3a4cd5aefd4b45` | **LOCAL-ONLY; superseded but preserve as production history** |
| `kuku/titles/end_credits.mp3` | Kuku v1 ending render; superseded by v2 lyric correction | 0:39.800 | 839,094 | `5a8ddd3bf1209d750bc407cc755019fdb0a07191c8de9bb5212f5ae3bec0b323` | **LOCAL-ONLY; superseded but preserve as production history** |

## Backup state

Proposed external target: `iCloud Drive/Metaphrand/Suno Backup 2026-08-02`.
The folder has been created, but **no audio has been copied**. Copying private
recordings into cloud storage requires the author's explicit approval of this
destination.

The minimum backup set is the three local-only assets named above. Once the
iCloud destination is explicitly approved, copy them preserving their filenames.
After copying, run SHA-256 on the destination files and compare the results with
this manifest. Record the destination and verification date here; do not record
credentials or private share links.

## Relationship to the writing sources

- The selected invocation's exact sung text is transcribed in
  [amal/2026-07-22_ALBUM_maati-maange.md](amal/2026-07-22_ALBUM_maati-maange.md).
- The full earlier Jhujhar lyric is in [amal/CHARAN_SONG.md](amal/CHARAN_SONG.md).
- The AMAL title direction is in [amal/TITLE_SEQUENCE.md](amal/TITLE_SEQUENCE.md).
- The Kuku renders are superseded by [kuku/SONGS_SUNO_v2.md](kuku/SONGS_SUNO_v2.md).

## Verification command

Run from `stories/` after restoring or copying an asset:

```bash
shasum -a 256 <path-to-audio-file>
```

Matching the full 64-character value proves the copied bytes match the asset that
was inventoried here.
