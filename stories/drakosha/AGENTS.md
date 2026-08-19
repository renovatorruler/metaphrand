# Frosya and Vasya production instructions

For any Episode 1, Scene 1 production task, read these files completely before planning, prompting, generating, or editing assets:

1. `ep1prod/scene1/CURRENT.md`
2. `ep1prod/scene1/scene1.production.v1.json`

Those two files are the current operational authority for Scene 1. The spec script remains the story authority, but older shooting drafts, visual batches, and proposals are not production authority unless `CURRENT.md` explicitly promotes them.

Rules:

- Do not generate from chat memory alone.
- Do not silently reopen a closed decision.
- When the user changes or approves a production decision, update both current-state files in the same turn.
- Every generation must use the references declared for its shot in the manifest.
- Stop before generation when a shot has an unresolved blocking asset or contradictory state.
- Preserve rejected and superseded assets, but never treat them as current merely because they remain on disk.

## Table-read preflight

Before preparing or rendering any Frosya and Vasya table read, read
`2026-08-12_TABLE_READ_LANGUAGE_AND_VOICE_POLICY.md` completely.

- Ask the user whether the table read should be in Russian or English before doing any paid rendering. A bilingual screenplay does not answer this question.
- Do not infer that a voice is suitable for a language from a provider label such as “multilingual.”
- Do not use Anna Zub for English narration. Her heavily accented English was rejected by the user.
- Anna Zub is not approved for Russian narration either unless the user explicitly approves her after hearing a Russian audition.
