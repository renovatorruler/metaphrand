"""FREE ROSS S2 — "The Porch Light": the episode as a multi-voice audio drama.

Emits a performance JSON in the heir_elevenlabs format (cast map + segments).
Each SCENE is one (scene, frame) group, so heir_elevenlabs renders the whole
scene as one continuous ElevenLabs v3 dialogue take — natural multi-voice
interplay, no per-line drift. Narrator (N) carries the action; the cast plays
the scene.

    python -m examples.free_ross_audio          # write the performance JSON
    python -m examples.heir_elevenlabs stories/free-ross/performance/porch-light.performance.json \
        stories/free-ross/performance/porch-light.mp3
"""
import json
import os

CAST = {
    "N":      ("George",  "JBFqnCBsd6RMkjVDRZzb"),
    "ROSS":   ("Bill",    "pqHfZKP75CvOlQylNhV4"),
    "COLE":   ("Antoni",  "ErXwobaYiN019PkySvjV"),
    "SADIE":  ("Sarah",   "EXAVITQu4vr4xnSDxMaL"),
    "ENYA":   ("Domi",    "AZnzlk1XvdvUeBnXmlld"),
    "RUTH":   ("Matilda", "XrExE9yKIg1WjnnlVkGX"),
    "TOMAS":  ("Clyde",   "2EiwWnXFnvU5JabPnv8n"),
    "SURETY": ("Daniel",  "onwK4e9ZLuTAKqWW03F9"),
    "NERV":   ("Liam",    "TX3LPaxmHKxFdv7VOQHJ"),
}

EPISODE = [
 ("s1", [
   ("N", "The Free Ross Detective Agency. A converted storefront — mismatched desks, a good coffee machine, the underdog shop. A nervous man clutches a receipt across the desk from Ross Underwood."),
   ("NERV", "I'm telling you, the watch was in the drawer when I left and gone when I came back. My brother-in-law was the only one in the house."),
   ("N", "Ross doesn't look at the receipt. He looks at the man's hands."),
   ("ROSS", "How long'd you rehearse that?"),
   ("NERV", "[confused] What?"),
   ("ROSS", "\"In the drawer when I left, gone when I came back.\" Clean. No ums. You said it to the mirror."),
   ("NERV", "I'm just trying to be—"),
   ("ROSS", "Your brother-in-law's broke and you're not. And you'd rather lose a watch than have a Tuesday where you ask him to his face. Go home. Ask him. He already wants to tell you."),
   ("N", "The man sits a moment, then goes. Ruth Marrow, the agency's in-house arbitrator, drops a file on the desk."),
   ("RUTH", "You could've taken his money."),
   ("ROSS", "He didn't have a case. He had a grudge with a coat on."),
   ("RUTH", "This one's a case. Showdown's Thursday. We're the defense."),
 ]),
 ("s2", [
   ("N", "Ross opens the file. A photo: a teenage girl, Sadie, in a wheelchair, with eyes that have decided not to need anyone."),
   ("RUTH", "Cole Vance is claiming against his neighbor. His sixteen-year-old went onto the man's lot at night. Empty in-ground pool, mid-construction, no fence. She fell in. Spinal. She'll need care the rest of her life."),
   ("ROSS", "And the neighbor's our client."),
   ("RUTH", "Tomas Reyes. Left a hole in the ground unsecured. On the facts, he's done. Cole's asking eleven thousand grams, lifetime surety. Tomas couldn't cover a tenth of it."),
   ("ROSS", "So why'd Tomas hire us instead of folding?"),
   ("RUTH", "Because he says the girl didn't fall. He won't explain. He just keeps saying it — \"you don't fall in that hole, Mr. Ross.\""),
   ("N", "Ross looks at the photo of Sadie a beat too long."),
 ]),
 ("s3", [
   ("N", "The Reyes kitchen. Tomas — a contractor's hands, a careful man — won't sit still."),
   ("TOMAS", "I fence it a week early, none of this. But you can't un-leave a hole open. I'm not saying the girl's lying. I'm saying somebody is — and it isn't the hole."),
   ("ROSS", "Walk me through the night."),
   ("TOMAS", "I was asleep. I heard nothing. That's the thing. A kid goes into a pit that deep, there's a sound. I sleep with the window open. Forty years. I'd have heard it."),
   ("N", "Ross writes nothing down. He files it away."),
 ]),
 ("s4", [
   ("N", "The Vance house. Immaculate. Cole Vance makes coffee he doesn't drink — a man holding himself together with both hands."),
   ("COLE", "She snuck out. Kids. She went over there in the dark, and that man left a grave open in his yard. The porch light was off — ours. She couldn't see the step."),
   ("ROSS", "Whose porch light?"),
   ("COLE", "Ours. It was off."),
   ("ROSS", "Why?"),
   ("COLE", "[too quickly] Bulb. We'd been meaning to."),
   ("N", "Ross nods, and lets it sit. Down the hall, Sadie appears in her doorway. She's heard her father say \"the porch light was off.\" Her face does something. She wheels out of sight."),
 ]),
 ("s5", [
   ("N", "Back at the agency. A woman waits across the bullpen — Enya Shore, Union-crisp, with a badge-holder's posture in a world that has no badges."),
   ("RUTH", "That's the claimant's investigator. Cole hired up. She built his whole file — pool unsecured, attractive nuisance, the medicals. It's airtight."),
   ("N", "Enya comes over. Even. A true believer."),
   ("ENYA", "Mr. Underwood. I've read about your method."),
   ("ROSS", "There's no method."),
   ("ENYA", "There's a hole in the ground, a man who left it open, and a child who can't walk. Three facts, all on the table. You're going to try to make a feeling outweigh that. I want to watch you try."),
   ("ROSS", "You built the cleanest case you've ever seen, you said."),
   ("ENYA", "I did."),
   ("ROSS", "That's what bothers me."),
 ]),
 ("s6", [
   ("N", "Ross, alone with two photos — Sadie's face, and Cole at his spotless counter. Ruth in the doorway."),
   ("ROSS", "Cole told me the porch light was off three times. Tomas told me his was off once, like it didn't matter — because it didn't. A man tells you twice the broken thing was the bulb, when you didn't ask? The bulb's not broken. He turned it off."),
   ("RUTH", "People turn off porch lights."),
   ("ROSS", "Not the night their kid's out. You leave it on so she can find the step — unless you don't want her coming back in yet."),
   ("RUTH", "[realizing] They fought."),
   ("ROSS", "She didn't sneak out. He put her out. Close enough that he can call it sneaking and still sleep. She went into the dark, mad, and found the only hole on the street. He's known since the sound he didn't hear, either."),
   ("RUTH", "You can't establish that. There's no witness. There's a porch light."),
   ("ROSS", "I don't have to establish it. I have to make him unable to bet on the lie. Seal the showdown. And put Sadie in the room."),
 ]),
 ("s7", [
   ("N", "The arbitration hall. Spare, almost sacred. A felt-topped table; a surety-master deals the claim like a hand. Cole and Enya on one side, Ross and Tomas on the other. Ruth, the neutral. Sadie at the back, in her chair."),
   ("SURETY", "Vance claims against Reyes. Eleven thousand grams, lifetime. Reyes' position."),
   ("ROSS", "We don't contest the hole. We don't contest the injury. We contest the cause. You established a path — steps, street, lot. You established everything except the one thing that pays: that she fell because Tomas left it open. So I'm going to ask the claimant to stake that. Just that. Raise on it, Cole. Put grams on \"my daughter fell.\""),
   ("ENYA", "He doesn't have to stake a fact you can't disprove."),
   ("ROSS", "He raised eleven thousand on it sight unseen. I'm asking him to raise one. One gram, Cole. On \"she fell.\""),
   ("N", "Silence. Cole's hand near his stack. Not moving."),
   ("ROSS", "[gently] You keep telling everyone the porch light was off. The bulb. You turned it off, Cole. She wanted out, and you let the door close behind her, and you killed the light so the house would feel like a thing she chose to leave. You've told it so clean there's no fight in it. No door. No dark. Just a hole, and a man who left it open. Stake the part where she fell. You can't — because the last thing you saw was her walking away from you, fast, into a yard you'd warned her about a hundred times. And going in anyway."),
   ("COLE", "[barely a whisper] Stop."),
   ("ROSS", "One gram."),
   ("N", "Cole doesn't move. And from the back of the room—"),
   ("SADIE", "I jumped."),
   ("N", "Everything stops."),
   ("SADIE", "I wasn't drunk. I wasn't lost. The light being off — Dad, the light was never the thing. We fought, and I went out there, and I sat on the edge of that stupid hole because it was the one place you'd never look. And I don't even know if I meant it. But I didn't fall."),
 ]),
 ("s8", [
   ("SURETY", "On the cause — unestablished. Reyes is released from the claim."),
   ("N", "Tomas exhales a breath he's held for two weeks. He doesn't gloat. He looks at Sadie."),
   ("TOMAS", "The care still happens. Coverage covers a child who needs it. It doesn't need a guilty man to pay for it. That's the whole point of the thing."),
   ("RUTH", "Community surety. She's covered. No one's in the program."),
   ("N", "The system didn't punish anyone. It just stopped a man from buying a lie with his neighbor's life. Cole crosses to Sadie and goes down to her eye level. For the first time, he doesn't have a clean sentence."),
   ("COLE", "I turned off the light."),
   ("SADIE", "I know, Dad. I always knew."),
 ]),
 ("s9", [
   ("N", "Outside, on the hall steps. Ross, just standing. Enya finds him."),
   ("ENYA", "You didn't establish anything. A girl confessed and you took credit for a feeling."),
   ("ROSS", "She didn't confess to me. She confessed to him. I just made the room quiet enough."),
   ("ENYA", "That's not detection. You decided he was guilty and bent a hearing until a child broke. If you're wrong next time, somebody innocent goes to Cainland on your mood."),
   ("ROSS", "I'm not wrong."),
   ("ENYA", "That's exactly what frightens me about you. I'm staying in Dallas, Mr. Underwood. I'm going to take every case you touch — and prove that what you do is just a prettier word for prejudice. I think we're going to know each other a long time."),
   ("N", "Ross looks at her offered hand. He doesn't take it. Not cruel — careful."),
   ("ROSS", "You read everything in that file except the one thing that mattered. You'd have buried an innocent man on the cleanest case you ever saw. You should be more frightened of that."),
   ("N", "He goes. Enya watches him — not anger. Resolve. The nemesis, born."),
 ]),
]


def write_perf():
    segs = []
    for sid, lines in EPISODE:
        for role, text in lines:
            segs.append({"scene": sid, "frame": sid, "speaker": role, "text": text})
    perf = {
        "title": "Free Ross — The Porch Light",
        "model_id": "eleven_v3",
        "output_format": "mp3_44100_128",
        "gaps_ms": {"group": 700},
        "cast": {r: {"voice": n, "voice_id": v,
                     "direction": "in-character, naturalistic, unhurried"}
                 for r, (n, v) in CAST.items()},
        "segments": segs,
    }
    out = "stories/free-ross/performance"
    os.makedirs(out, exist_ok=True)
    json.dump(perf, open(f"{out}/porch-light.performance.json", "w"), indent=1)
    print(f"{len(EPISODE)} scenes, {len(segs)} lines -> {out}/porch-light.performance.json")


if __name__ == "__main__":
    write_perf()
