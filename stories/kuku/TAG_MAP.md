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


## Vocal tags — added for Ep5 «प से पुल» (2026-07-27)

*Per rule 4: new Hindi parentheticals are added here BEFORE recording.*

| हिंदी कोष्ठक | ElevenLabs tag |
|---|---|
| आदर के साथ | [respectfully] |
| आराम से | [calmly] |
| उछलकर | [excited] |
| उत्साह में | [enthusiastically] |
| उत्साह से | [enthusiastically] |
| उत्सुक होकर | [curious] |
| उदास होकर | [sad] |
| उस पार से | [calling across a distance] |
| ऊँची आवाज़ में | [loudly] |
| एक पल की चुप्पी — फिर हाँफते हुए | [a beat of silence, then out of breath] |
| एक पल रुककर — शर्मिंदा | [pausing, ashamed] |
| एक-एक करके | [one by one, deliberate] |
| और ज़ोर देकर | [emphatically] |
| और ज़ोर से | [louder] |
| काँपती आवाज़ में | [voice trembling] |
| काँपती आवाज़ में — फिर अचानक मज़बूती से | [trembling, then suddenly firm] |
| किलकारी से | [tiny cute voice] |
| ख़ुद से | [to himself, quietly] |
| ख़ुश होकर | [joyful] |
| ख़ुशी से चिल्लाकर | [shouting with joy] |
| ख़ुशी से चीख़कर | [shrieking with joy] |
| खेल शुरू करते हुए | [playful] |
| गहरी | [deep voice] |
| गहरी साँस भरकर | [inhaling deeply] |
| घबराहट में | [alarmed] |
| चिंता में | [worried] |
| चिढ़कर | [annoyed] |
| चीख़कर | [shouting] |
| चुपचाप | [quietly] |
| चौंककर | [startled] |
| जल्दी में | [hurried] |
| ज़बरदस्ती चहककर | [forced cheerfulness] |
| ज़बरदस्ती तेज़ आवाज़ में | [too brightly, forced] |
| ज़ोर से और साफ़ | [loud and clear] |
| जोश भरकर | [excited] |
| जोश में | [excited] |
| झटके से | [sharply] |
| ठहर-ठहरकर | [slowly, with pauses] |
| डरकर | [scared] |
| तुरंत | [immediately] |
| तोतली ख़ुशी में | [baby voice] [delighted] |
| दबी हुई आवाज़ में | [subdued] |
| दूर से | [calling from a distance] |
| दोहराते हुए | [repeating] |
| धीरे | [softly] |
| नई ताक़त से | [with fresh strength] |
| नरमी के साथ | [gently] |
| नरमी से हँसकर | [chuckling gently] |
| नरमी से — कोई डाँट नहीं | [gently] |
| पर शांत | [calm] |
| पर साफ़ | [clear] |
| पानी के शोर के ऊपर | [projecting over noise] |
| फिर गंभीर होकर | [then serious] |
| फिर ज़ोर लगाते हुए | [then straining] |
| फिर हँसकर | [then laughing] |
| बहुत धीरे | [very softly] |
| बहुत हल्की | [barely audible] |
| बात टालकर | [deflecting] |
| बिना ग़ुस्से के | [kindly, without anger] |
| बेख़बर | [oblivious and breezy] |
| भर्राई आवाज़ में | [choked up] |
| भागकर आते हुए | [arriving out of breath] |
| मज़बूती से | [firmly] |
| राहत की साँस लेकर | [sighing with relief] |
| रुँधे गले से | [choked with tears] |
| रोआँसा होकर | [tearful] |
| लय में | [rhythmically] |
| शर्माकर | [shyly] |
| शांति से | [calmly] |
| सच बोलते हुए | [plainly, telling the truth] |
| सपनीले अंदाज़ में | [dreamy, half asleep] |
| सपने में बोलते जैसे | [dreamy, half asleep] |
| समझकर | [understanding dawning] |
| साँस छोड़कर | [exhaling] |
| साफ़ | [clear] |
| साफ़ आवाज़ में | [clear voice] |
| साफ़ और मज़बूत | [clear and firm] |
| साफ़-साफ़ | [clear and precise] |
| स्थिर आवाज़ में | [steady voice] |
| हक़ जताते हुए | [claiming it proudly] |
| हर हिस्सा ज़ोर से बोलते हुए | [announcing each part] |
| हल्की आवाज़ में | [light voice] |
| हवा में चिल्लाते हुए | [shouting into the wind] |
| हारकर | [defeated] |
| हिचकिचाकर | [hesitantly] |
| हैरान और ख़ुश | [astonished and delighted] |
| हैरान होकर | [astonished] |
| हौसला देते हुए | [encouraging] |

## Visual-only, added Ep5 (NO audio tag)

अक्षर के मुड़े हुए पैर पर हाथ रखकर · आँखों पर हाथ रखकर देखते हुए · आगे बढ़कर · ऊपर देखते हुए · एक साथ · काम रुके बिना · कुकु की तरफ़ मुड़कर · कुकु से · घुटनों के बल बैठकर · चलते हुए · डोर खींचते हुए · दौड़ते हुए · पानी में हाथ डालते हुए · पानी में हाथ डाले हुए · पार करते हुए · पीछे हटकर · बेटी की तरफ़ · मिटासुर की तरफ़ · मिटासुर से · सबको इकट्ठा करते हुए · रुककर

## Animal-sound parentheticals, added Ep5 (SFX line, not tagged speech)

तेज़ भौंक · बहुत घबराई · दोस्ताना गुर्राहट · संतुष्ट गुर्राहट
