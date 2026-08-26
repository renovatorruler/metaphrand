# कुकु का अक्षर आँगन — build contract

## Audience and goal

An untimed, solo browser game for children who already watch *कुकु और अक्षर*. A short session reviews the letters and picture-words lived in Episodes 1–10, then gives extra practice with standalone `आ` and attached `ा`.

## Core loop

1. Kuku, Furia, or Vesper presents one large, spoken-and-written prompt. Kuku leads letter questions, Vesper leads picture and first-sound questions, and Furia leads whole-word questions.
2. The child chooses one of three large cards by touch, keyboard, or gamepad.
3. A correct card lights one bracelet jewel and advances after a short celebration.
4. A missed card stays playable, receives a gentle visual cue, and returns later in the same session. After two misses, the correct card pulses.
5. Ten correct answers complete the bracelet. The child can replay immediately.

There is no timer, score penalty, life counter, or game-over state.

## Question families

- **अक्षर सुनो:** hear and see a request such as “क कहाँ है?” and select the named letter.
- **तस्वीर पहचानो:** see a familiar object, hear its name, and select its starting letter.
- **शब्द देखो:** see a picture and select the correctly formed `आ`/`ा` word. A मात्रा is only shown attached to a consonant or inside a complete word, never as its own letter-house.

The first release uses only the approved chronology through `ग`: `क म र न प त आ/ा च ब ग`. Question words come from `stories/kuku/LETTER_MAP.md` and the produced Episode 10 vocabulary.

## Child-facing language

Use short home-register Hindustani: “क कहाँ है?”, “यह क्या है?”, “फिर से देखो”, “शाबाश!”, “एक बार और”. Avoid schoolbook exposition, action directions, and grammar terminology in spoken prompts.

## Presentation

One fixed game-board view: a bright layered-paper valley, one active guide beside the prompt, and three answer cards along the bottom. The opening and completion screens show Kuku, Furia, and Vesper together. During play their canonical generated portraits sit inside cream paper frames, with a short Hindi name tab; wide layouts use the full-body art and narrow or portrait layouts use a closer crop. Feedback happens in place; there are no camera moves or expensive generated shots. Object prompts use one original versioned early-reader illustration atlas; the board, particles, and feedback cues stay procedural. Only Kuku breathes an earned letter. When Furia or Vesper leads, the correct letter rises from the selected card instead. Hindi prompts use bundled native-speaker MP3 clips, with the browser’s local voice only as a load-failure fallback. Every spoken prompt also remains visible in writing.

## Persistence and privacy

Only versioned mastery counts and sound preference are stored in local browser storage. No child name, account, microphone recording, analytics, network gameplay, ads, or purchase flow.
