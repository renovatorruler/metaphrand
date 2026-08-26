# कुकु का अक्षर आँगन — acceptance thresholds

- Landscape design reference: `1280 × 720`; runtime layout uses CSS-pixel coordinates and reflows for portrait screens. Canvas backing resolution has a device-pixel-ratio cap of `1.5`.
- Performance target: `60 fps`; fixed update step `16.67 ms`; no unbounded particles or per-frame collection growth.
- Input: touch/pointer, physical `KeyboardEvent.code`, and standard gamepad. Answer targets are at least `104 × 104` logical pixels on standard layouts; height-constrained phone layouts keep full-width cards at least `64` pixels tall so all three remain on-screen.
- Session: exactly `10` correct answers; expected duration `4–7 minutes`; no timer pressure.
- Choices: exactly `3` answer cards; only one correct answer.
- Assistance: no penalty on a miss; pulse the right answer after `2` misses on one prompt.
- Feedback timing: tap response immediately; correct-answer transition after about `1050 ms`; input debounce at least `180 ms`.
- Audio: the first bundled prompt starts from the child’s Start gesture and reuses one persistent media element thereafter; all retained questions resolve a versioned MP3; synthesized cue gain stays at or below `0.12`; sound-off mode remains fully understandable.
- Learning: missed items return before session completion; mastery is stored per question in versioned `localStorage`.
- Accessibility: all child-facing prompts are simultaneously visible; speech is a convenience, never the only channel.
- Character guides: the opening and completion screens show canonical Kuku, Furia, and Vesper art; every session assigns glyphs to Kuku, pictures to Vesper, and words to Furia; portrait prompts never overlap a guide portrait or name tab; only Kuku's success reward originates at the character.
- Determinism: question order uses a seeded shuffle; replay creates a new seed without changing content.
- Lifecycle: pause updates and speech when the tab loses focus; resume cleanly.
- Completion: start → ten answers → celebration → replay works without reload.
- Packaging: ZIP root contains `index.html`, the Higgsfield-required solo `logic.js` rules shim, `assets/`, and `design/assets.csv`; all runtime paths are relative. The packager normalizes ReScript's grouped ESM export block to the host validator's required direct-export form.
