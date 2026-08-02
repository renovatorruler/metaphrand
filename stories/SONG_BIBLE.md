# Metaphrand song bible

Status: standing source map and writing contract, 2026-08-02.

This file answers two questions: which song document is active, and what must be
present before a new song is ready for Suno. The linked source document owns the
full lyrics. This bible owns status and precedence, so lyrics are not copied into
multiple files and allowed to drift.

## Status words

- **LOCKED** — use as-is unless the author explicitly reopens it.
- **STANDING** — the current working direction; it may still receive deliberate revisions.
- **DRAFT — NATIVE EAR** — structurally usable, but dialect wording is not approved.
- **PLANNED** — a commissioned direction with no complete lyric packet yet.
- **SUPERSEDED** — retained as history or reference; do not render it.
- **LOCAL-ONLY AUDIO** — present on this machine but not recoverable from Git.

## The writing law

A lyric is drama, not an inventory of images or completed events.

Before drafting, state in plain language:

1. Who is singing?
2. Who are they singing to?
3. What do they want that listener to do, admit, remember, or promise?
4. What makes the request difficult?
5. Where does the address turn?

The working grammar is address, command, question, persuasion, or vow. Description
may support the action, but it cannot replace it. A refrain must keep applying
pressure; it must not merely summarize the theme.

Dialect is a production constraint, not decoration. Use the project's register
document, keep uncertain words visibly flagged, and treat the author's native ear
as final. Do not silently blend Gujarati, Marathi, Rajasthani, standard Hindi, or
film-Hindi forms to make a line look regional.

## A complete Suno packet

A song is not ready to render until one source document contains all of these:

1. Status and version precedence.
2. A one-paragraph dramatic design: singer, listener, want, resistance, and turn.
3. Paste-ready lyrics with performance and structure tags.
4. A paste-ready **Style** field.
5. A paste-ready **Exclude** field.
6. A voice-continuity decision: new voice, or the exact saved Suno Persona to reuse.
7. A plain-language gloss when the lyric is not in standard English or Hindi.
8. Native-ear flags and any words awaiting a ruling.
9. The selected audio filename after rendering, recorded in
   [SUNO_ASSET_MANIFEST.md](SUNO_ASSET_MANIFEST.md).

Generate two or three takes when voice or pronunciation matters. Selection is a
creative decision, not an automatic score: keep the take whose performance serves
the dramatic action and whose language survives the native-ear check.

## Active catalog

| World | Song | Status | Register | Authoritative source |
| --- | --- | --- | --- | --- |
| AMAL album | `उठ रे जुझार` | **LOCKED** — actual selected Suno text | Marwari–Malwi bardic address | [माटी माँगे, track 1](amal/2026-07-22_ALBUM_maati-maange.md#track-1--उठ-रे-जुझार-canonical-sung-text--the-authors-actual-suno-take-transcribed-from-his-paste-2026-07-25) |
| AMAL album | `बोल दे` | **DRAFT — NATIVE EAR** | conservative Malvi, intimate persuasion | [माटी माँगे, बोल दे](amal/2026-07-22_ALBUM_maati-maange.md#track--बोल-दे-you-tell-her--fake-kartavya--draft-v1-native-ear-verdict-pending) |
| AMAL album | Tejaji song | **PLANNED** | song of Malwa's soil; duty kept at bodily cost | [rebuilt roster](amal/2026-07-22_ALBUM_maati-maange.md#roster-rebuilt-author-2026-07-26--the-album-argues-duty-kept-at-an-unbearable-price-vs-worn-as-a-costume) |
| AMAL album | Ahilyabai song | **PLANNED** | Malwa folk memory; justice summoned into the present | [rebuilt roster](amal/2026-07-22_ALBUM_maati-maange.md#roster-rebuilt-author-2026-07-26--the-album-argues-duty-kept-at-an-unbearable-price-vs-worn-as-a-costume) |
| AMAL series | Full `झूझार / Jhujhar` leitmotif | **STANDING**, separate from the short album invocation | Malwi–Rajasthani veer-ras | [CHARAN_SONG.md](amal/CHARAN_SONG.md) |
| AMAL series | Post-rock Jhujhar variant | **STANDING v4**; v1–v3 are history | active-address Malvi/Rajasthani | [active-address rewrite](amal/2026-07-16_CHARAN_BALLAD_SUNO_v1.md#post-rock-anthem--active-address-rewrite-v4-standing-authors-law-no-passive-inventory-lyrics) |
| AMAL titles | Instrumental saka main-title score | **LOCKED direction** | instrumental Rajput/Malwa folk-noir | [TITLE_SEQUENCE.md](amal/TITLE_SEQUENCE.md) |
| AMAL titles | Sung `अमल` world-anthem | **STANDING candidate**, not the locked title-sequence score | dark Malwi folk-noir | [TITLE_TRACK.md](amal/TITLE_TRACK.md) |
| Kuku | `कुकु और अक्षर` title | **STANDING v2, not yet rendered**; v1 audio is superseded | Hindi children's theme | [SONGS_SUNO_v2.md](kuku/SONGS_SUNO_v2.md) |
| Kuku | `अक्षर घाटी सो गई है` ending | **STANDING v2, not yet rendered**; v1 audio is superseded | Hindi lullaby | [SONGS_SUNO_v2.md](kuku/SONGS_SUNO_v2.md) |
| Bhopal | `दस्तक` | **STANDING v1** | courteous, Urdu-inflected Bhopali Hindi; explicitly not Malvi | [2026-07-29_SONG_dastak.md](bhopal/2026-07-29_SONG_dastak.md) |
| Фрося и Вася | Series title song | **STANDING v3** | Russian children's television song | [2026-07-27_TITLE_SONG.md](drakosha/2026-07-27_TITLE_SONG.md) |

## AMAL precedence and register

For new `माटी माँगे` work, read in this order:

1. The rebuilt album direction in
   [2026-07-22_ALBUM_maati-maange.md](amal/2026-07-22_ALBUM_maati-maange.md).
2. The Malvi register in [MALWA.md](amal/MALWA.md).
3. Charan's quarantine and earned-eloquence rules in
   [VOICE_CARDS.md](amal/VOICE_CARDS.md#charan--charan--the-bard-the-only-earned-eloquence).
4. The active-address correction in
   [2026-07-16_CHARAN_BALLAD_SUNO_v1.md](amal/2026-07-16_CHARAN_BALLAD_SUNO_v1.md#post-rock-anthem--active-address-rewrite-v4-standing-authors-law-no-passive-inventory-lyrics).

The initial eight-track AMAL roster is historical. It was replaced on 2026-07-26
by songs drawn from the soil rather than songs that perform errands for the plot.
Jhujhar stands; Tejaji, Ahilyabai, and fake duty (`बोल दे`) are the named active
directions. The abstract Father, Coward, and Kartavya-as-topic tracks are off.

The short `उठ रे जुझार` album invocation and the longer `झूझार / Jhujhar` series
leitmotif are related but distinct works. Do not merge their lyrics merely because
they share the warrior, bard, and melodic world.

## Non-Suno music that must not be confused with song drafts

- [Ratan's six-part theme](amal/audio/ratan_theme/README.md) is an approved
  instrumental leitmotif transformation, originally generated with ElevenLabs.
- [The Rudaali library](amal/audio/rudaali/README.md) contains user-selected source
  recordings. It is locked for treatment and placement; do not regenerate it.

## Current writing queue

1. Resolve the native-ear flags in `बोल दे` before rendering it.
2. Write the Tejaji packet: dramatic design, lyrics, style, exclude, gloss, flags,
   and Persona decision.
3. Write the Ahilyabai packet to the same standard.
4. Decide whether the sung `अमल` title anthem remains a separate release or is
   retired behind the locked instrumental title sequence.
5. Render the Kuku v2 title and ending songs; the local v1 audio must not return
   to the finished episodes as if it were current.

## Preservation

Generated media is intentionally not added to Git. The text sources above are the
recoverable creative record. Audio identity and backup status live in
[SUNO_ASSET_MANIFEST.md](SUNO_ASSET_MANIFEST.md). A checksum proves that a copied
file is identical; it is not itself a backup.
