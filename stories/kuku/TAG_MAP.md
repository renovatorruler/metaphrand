# कुकु और अक्षर — TAG MAP (Hindi performance parentheticals → ElevenLabs v3 English audio tags)

The script layer stays pure Hindi (series law). At recording, the pipeline translates each Hindi parenthetical to an English v3 audio tag via this table. Visual-only parentheticals (stage business, no vocal quality) map to NO TAG. Multi-part parentheticals: take the vocal part. Unknown/new Hindi tags: add here first, then record.

## Vocal tags

| हिंदी कोष्ठक | ElevenLabs tag |
|---|---|
| हँसते हुए / हँसकर | [laughing] |
| हँसी दबाते / हँसी दबाकर | [suppressing a laugh] |
| खिलखिलाकर | [giggling] |
| मुस्कुराकर | [warmly] |
| फुसफुसाकर | [whispers] |
| धीमे / धीरे से / धीमी आवाज़ में | [softly] |
| बहुत धीरे, लोरी जैसे | [soft lullaby voice] |
| ज़ोर से / चिल्लाकर | [shouting] |
| पूरी ताक़त से | [shouting at the top of his lungs] |
| ज़ोर से पुकारते हुए | [calling out loudly] |
| चहकते हुए / चहककर | [excited] |
| उछलते हुए / जोश से | [excited] |
| ख़ुशी से | [joyful] |
| ऊँची, ख़ुश आवाज़ में | [bright and happy] |
| घबराकर | [alarmed] |
| चिंता से | [worried] |
| बेचैन | [restless, uneasy] |
| डरते हुए | [scared] |
| हैरान / हैरानी से | [astonished] |
| सवालिया | [questioning] |
| उत्सुकता से | [curious] |
| शर्म से | [sheepish] |
| उदास | [sad] |
| भावुक / फूलकर, भावुक | [moved, emotional] |
| रोता-हँसता | [laughing through tears] |
| गर्व से | [proud] |
| शाबाशी से | [encouraging] |
| प्यार से / नरमी से / बिना डाँटे | [gently] |
| राहत से | [relieved] |
| गंभीर होकर / सीधे, साफ़ आवाज़ में | [serious and clear] |
| धीमी, सयानी आवाज़ में | [slow and wise] |
| सोचते हुए | [thoughtful] |
| लापरवाही से | [casual] |
| खोई हुई आवाज़ में / नींद में / उनींदा | [dreamy, half asleep] |
| सुकून भरी साँस | [contented sigh] |
| जम्हाई लेते हुए | [yawning] |
| हाँफते हुए | [out of breath] |
| साँस भरते हुए | [inhaling sharply] |
| साँस छोड़ते हुए | [exhaling] |
| ज़ोर लगाते हुए | [straining] |
| बंद नाक से | [stuffy nose] |
| कमज़ोर | [weak, tired] |
| तुतलाते हुए | [toddler babble] |
| नन्ही आवाज़ में / नन्ही किलकारी से | [tiny cute voice] |
| सिखाते हुए | [warm teaching voice] |
| गिनाते हुए / गिनती शुरू करते हुए | [rhythmic counting] |
| खेल की आवाज़ में | [playful] |
| चमकती आवाज़ में | [bright] |
| फुसफुसाते हुए, टोकते हुए | [gentle whispered correction] |
| गुनगुनाते हुए | [humming] |
| बयान करते हुए | [narrating with wonder] |

## Visual-only (NO audio tag — stage business)

माथा पकड़कर · हाथ हिलाते हुए · कान पकड़कर · भागकर पास जाते हुए · आँखें चमकाकर · किताब खोलकर · छपाके मारते हुए · नल की ओर बढ़कर · रुककर (alone) · दरवाज़े से · आदत से · एक साथ (direction, not tone — but keep lines synced in the mix)

## Rules

1. Multi-part parentheticals: translate the VOCAL half, drop the visual half — (कान पकड़कर, हैरान) → [astonished].
2. Sequenced states: (रुककर, नरम होकर) → [pausing, then gently].
3. Animal sounds (कालू, रीछ, नेवला) are SFX lines, not tagged speech.
4. New Hindi parenthetical in a script = add a row here BEFORE recording; the map is the contract.
5. Before the first full episode render, run a 5-line probe (one whisper, one shout, one stuffy-nose, one giggle, one lullaby) to confirm current v3 behavior — tags are open-vocabulary and English-documented; verify, don't assume.
