#!/bin/bash
# Ep2 score: six continuous cues (theft reuses the proof cue). EL Music, instrumental.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p score
cp ../talktest/scene_score.mp3 score/cue2_theft.mp3 2>/dev/null
python3 <<'PY'
import json, subprocess, os
CUES={
'cue1_mela': (62000, "Bright joyful village-fair opening for a children's papercraft cartoon: ukulele, glockenspiel, hand claps, dhol accents, bustling happy morning; at 40 seconds one comic POP and a huge cartoonish record-scratch freeze, then a beat of stunned silence and a warm chuckling resolution. One cohesive instrumental cue, consistent instruments, never scary."),
'cue3_lesson': (52000, "Gentle wonder teaching-moment cue for a children's cartoon: music-box and soft strings opening like a golden reveal, patient and warm; builds in the last 15 seconds into a rising heroic little rally with light drums, a team vowing to help. Instrumental, cohesive, gentle."),
'cue4_chase': (62000, "Playful comic chase cue for a children's papercraft cartoon: pizzicato strings, bassoon, light percussion, scampering; at 35 seconds everything CUTS to a long stunned silence beat, then resumes hushed and curious; final 12 seconds turn unexpectedly sad and tender, a small lonely confession. Instrumental, cohesive."),
'cue5_climax': (62000, "Heroic climax cue for a children's cartoon: tense but gentle peril over water, heartbeat pulse; at 20 seconds a brave gathering breath, a magical three-note chant motif; at 30 seconds a radiant triumphant bloom, golden and warm, wonder cascading as color returns to the world; ends on a tender reunion swell. Instrumental, cohesive, never scary."),
'cue6_heart': (58000, "Tender redemption cue for a children's cartoon: a small sad character learns to make his first thing; hesitant music-box notes that wobble, then bloom into quiet wonder; warm family embrace theme in the last 20 seconds, grandmother warmth, everyone is someone's child. Instrumental, cohesive."),
'cue7_night': (52000, "Cozy goodnight recap cue for a children's cartoon: soft lullaby textures, music box, warm night crickets feel, gentle call-and-response playfulness winding down to sleep; final 10 seconds settle to a single soft goodnight note. Instrumental, cohesive."),
}
for name,(ms,prompt) in CUES.items():
    f=f'score/{name}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>50000: print('SKIP',name); continue
    body=json.dumps({'prompt':prompt,'music_length_ms':ms,'model_id':'music_v1','force_instrumental':True})
    subprocess.run(['curl','-s','-X','POST','https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
      '-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json','-d',body,'-o',f],capture_output=True)
    print('OK' if os.path.getsize(f)>50000 else 'FAIL', name, os.path.getsize(f))
PY
ls -la score/