#!/bin/bash
# Theft-scene proof: 5 wordless shots (audio-first architecture: these are ACTION beats
# only; all dialogue is the OmniHuman talking take). Sequential submit, then fetch.
cd /Users/dusty/Dev/metaphrand/stories/kuku/talktest
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
S="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: any other attached image is a locked character design; match it EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo, no live-action."
E="NEGATIVE: no readable text, no captions, no watermark, no logos, no talking mouths, no lip-sync, no photorealism, no live action, no human figures, nothing scary."

declare -a NAMES PROMPTS REFS
NAMES=(w1_pov w2_erase w3_break_stall w4_break_chick w5_scoop_exit)
REFS=("" "--image $CS/mitasur.png" "--image $CS/dadi.png" "" "--image $CS/mitasur.png")
PROMPTS=(
"SCENE: High viewpoint from a paper hilltop at golden dusk, looking down on a joyful papercraft village fair: bunting, little stalls, tiny dragon villagers, a peacock family parading, soft golden glowing letter-shapes shimmering on the banners and stalls. MOTION: gentle festive bustle far below, banners swaying, warm glow pulsing. AUDIO: distant happy fair hubbub and music, no voice."
"SCENE: Mitasur, the roly-poly grey-purple cut-paper goblin with fat pink sponge-hands, stands on the hilltop and sweeps one sponge-hand across the sky in a great slow arc; below, the soft golden glow lifts OFF the entire fair like dust drawn to a magnet, streaming up through the air into his open burlap sack; the valley dims behind the stream of light. MOTION: the big sweeping arm arc, rivers of golden glow flowing up from the valley into the sack, the fair dimming. AUDIO: a great soft WHIFF and shimmering whoosh, the fair music faltering, no voice."
"SCENE: At the sweets stall, Dadi Maya the grey spectacled grandmother dragon watches in dismay as the bright colorful paper sweets on her stall fade to dull grey one by one; beside the stall a papercraft peacock tries to fan its tail but the feathers hang flat and drooping. MOTION: color visibly draining from the sweets, the tail lifting then flopping flat, Dadi's ears drooping. AUDIO: a sad little deflating sound, the hubbub gone quiet, no voice."
"SCENE: By a paper stream, a tiny fuzzy peachick opens its beak to call out but no sound comes; it looks around, lost; across the pond a mother peahen lifts her head and searches, unable to call back; the still water reflects them both, the fish beneath gone pale and motionless. MOTION: the small beak opening on silence, two heads searching for each other, stillness. AUDIO: near-silence, one tiny confused cheep, gentle sad wind, no voice."
"SCENE: Mitasur the grey-purple cut-paper goblin cinches his bulging burlap sack, now glowing warmly from inside, heaves it over his shoulder with both fat pink sponge-hands, and waddles away over the crest of the dim paper hill into the dusk, pleased with himself but small and alone against the sky. MOTION: the heavy heave, the self-satisfied waddle, the glow bobbing away over the hill. AUDIO: soft comic footsteps, a fading giggle-hum, dusk wind, no voice."
)
> scene_jobs.txt
for i in 0 1 2 3 4; do
  id=$(higgsfield generate create gemini_omni --prompt "$S ${PROMPTS[$i]} $E" --image "$STYLE" ${REFS[$i]} --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')")
  echo "${NAMES[$i]} $id" >> scene_jobs.txt
  echo "SUBMITTED ${NAMES[$i]} $id"
done
while read -r n id; do
  [ -z "$id" ] && { echo "NO-ID $n"; continue; }
  url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  [ -n "$url" ] && curl -s -o "$n.mp4" "$url" && echo "GOT $n" || echo "FAILED $n"
done < scene_jobs.txt
echo "CLIPS: $(ls w*.mp4 2>/dev/null | wc -l | tr -d ' ')/5"
