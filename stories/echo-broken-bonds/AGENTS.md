# Echo and the Broken Bonds instructions

## Paid voice generation

- This is a standalone project. Do not inherit casting or voice choices from any
  other story, repository, provider example, or previous generation.
- Before any billable text-to-speech request, resolve the voice explicitly in this
  order: a voice named by the user, otherwise the project default in
  `audio/elevenlabs.config.json`.
- Never choose or substitute a voice based on genre words such as “storyteller,”
  “cinematic,” or “narrator.” An unspecified voice is not permission to improvise
  an accent.
- Do not rerender existing audio unless the user explicitly requests a rerender.
- Report the resolved voice name, voice ID, accent, model, and estimated billable
  character count before submitting a paid request.

