# कुकु और अक्षर — Title + Ending Songs — SUNO v2 (2026-07-26)

*Supersedes SONGS_SUNO_v1.md. The v1 renders were made before the series laws existed and violate
four of them (audit, 2026-07-26): the chorus sings the retired «साँस-टोपी-अक्षर» chant, the chorus
and the lullaby both teach the banned टोपी rule, verse 2 uses «मैं पहले» instead of «पहले मैं!»,
and the spoken outro names क — wrong from Episode 2 onward.*

**Interim fix already shipped ($0):** the title in every episode is now trimmed to intro + verse 1
(26.1s, fades before the first chorus). Lawful, and verse 1 states the premise cleanly. Full-length
title returns when these v2 lyrics are rendered.

---

## 1) TITLE SONG v2 — «कुकु और अक्षर» (~45–60s)

**STYLE (Suno)** — unchanged from v1:
Upbeat playful kids TV theme song, Bollywood children's chorus, Hindi lyrics, bright ukulele,
hand claps, glockenspiel, dhol-tasha accents, tempo 118 bpm, cheerful female lead with kids
chorus call-and-response, short intro, big singalong hook, clean ending. No EDM drop, not slow.

**LYRICS:**

```
[Intro - kids shouting]
कुकु! फ्यूरिया! वैस्पर!

[Verse 1]
हरी घाटी में एक ड्रैगन है
सबसे छोटा, सबसे प्यारा है
आग नहीं, कुछ और ही आता
वो तो अक्षर है बनाता!

[Chorus]
कुकु, तुम कर सकते हो!
(कुकु, तुम कर सकते हो!)
कुकु और अक्षर!
हर साँस में एक नया अक्षर
आओ सीखें क ख ग!

[Verse 2]
फ्यूरिया बोले, पहले मैं!
वैस्पर बादलों में खोया है
तीनों मिलकर ढूँढते हैं
आज का अक्षर कौन सा है?

[Chorus]
कुकु, तुम कर सकते हो!
(कुकु, तुम कर सकते हो!)
कुकु और अक्षर!
हर साँस में एक नया अक्षर
आओ सीखें क ख ग!

[Outro - spoken, warm grandmother voice]
आज का अक्षर है...?
```

**What changed and why**
- **Chorus hook** is now the team's real encouragement line — the phrase that replaced the chant in
  the episodes themselves (law 5). Same call-and-response shape, same singability.
- **Chorus line 4** teaches the breath-makes-letters mechanic instead of the hat rule (law 6).
- **Verse 2** carries फ्यूरिया's correct catchphrase «पहले मैं!» and her correct spelling (laws 7, 8).
- **Outro asks and does not answer.** दादी's question hands straight off to the «आज का अक्षर — X»
  card that opens every episode, so one render serves the whole series forever.

---

## 2) ENDING LULLABY v2 — «अक्षर घाटी सो गई है» (~40s)

**STYLE (Suno)** — unchanged from v1:
Gentle Hindi lullaby, lo-fi warm vintage radio texture, soft female voice, slow 70 bpm, music
box and soft strings, sleepy and tender, like an old transistor radio at night, fades out.

**LYRICS (complete v2; paste as-is):**

```
[Verse]
अक्षर घाटी सो गई है
तारे जले हैं ऊपर
कालू सोया कंबल ओढ़े
सपनों में है अक्षर

[Verse 2]
सुनहरे अक्षर सारे
बादल ओढ़ के सोए
कल सुबह फिर नया अक्षर
कुकु की साँस से आए

[Outro - spoken, soft grandmother voice]
शुभ रात्रि, वैस्पर.
```

This carries the lawful v1 lines forward and replaces the retired hat-rule line,
so v2 no longer depends on a reader reconstructing lyrics from the superseded file.

---

**Workflow when rendering:** 2–3 Suno takes each, pick the best, drop into `stories/kuku/titles/`.
Then rebuild `ep*/out/title24.mp4` + `credits24.mp4` (fps 24, 1280×720) and re-cut every episode's
head and tail — the assembler picks them up automatically, so it is one rebuild per episode and
no re-render of any scene.
