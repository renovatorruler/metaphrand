#!/bin/bash
# Ep4 score (3 new cues; cueE/cue6/cue7 reused) + SFX library (the drip is a character).
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep4prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p score sfx
python3 <<'PY'
import json, subprocess, os
def post(url,body,out):
    subprocess.run(['curl','-s','-X','POST',url,'-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}',
      '-H','Content-Type: application/json','-d',json.dumps(body),'-o',out],capture_output=True)
    print('OK' if os.path.getsize(out)>20000 else 'FAIL', out)
CUES={
 'cueF_play_70':(70000,"Sunny playful afternoon cue for a children's papercraft cartoon: skipping ukulele, hand percussion, a ball bouncing feeling, children racing by a river; carefree and bright; near the end it thins out and a single quiet dripping-clock feeling remains, gently unresolved. Instrumental, cohesive, never scary."),
 'cueG_worry_75':(75000,"Gentle worry cue for a children's cartoon: a muffled morning, a small character feeling unwell; soft minor music-box, slow woolly strings, a caring bedside feeling — concerned but always safe and warm, like a grandmother's hand on a forehead; ends with a small hopeful turn. Instrumental, cohesive."),
 'cueH_wash_75':(75000,"Bubbly washing-game romp for a children's cartoon: splashy playful rhythm, bouncy tuba and ukulele, counting-game energy with nine cheerful accents, soap-bubble sparkles, a joyful crowd of friends taking turns; big warm finish. Instrumental, cohesive."),
}
for n,(ms,p) in CUES.items():
    f=f'score/{n}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>50000: print('SKIP',n); continue
    post('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
         {'prompt':p,'music_length_ms':ms,'model_id':'music_v1','force_instrumental':True},f)
SFX={
 'drip_slow':(6.0,"A single old tap dripping slowly into a metal basin, tap... tap... tap..., quiet room echo"),
 'ball_play':(4.0,"Children playing outdoors, a paper ball bouncing, running feet on grass, distant birds"),
 'door_open':(1.5,"A wooden door opening with a soft creak"),
 'sneeze_build':(2.5,"A small boy's big comical sneeze build-up, three rising sharp inhales, aah aah aah"),
 'sneeze_blast':(2.5,"One colossal cartoon sneeze explosion from a small boy, huge comic achoo with a whoosh"),
 'windows_rattle':(2.0,"Wooden window shutters rattling hard once, then settling"),
 'birds_scatter':(2.0,"A flock of small birds startling and fluttering away quickly"),
 'kalu_scared':(1.2,"A small puppy's startled yelp-bark"),
 'kalu_call':(2.0,"A small puppy barking urgently twice, calling for help, bhau bhau"),
 'kalu_happy':(1.2,"One happy bouncy puppy bark"),
 'stick_steps':(3.5,"Slow gentle elderly footsteps with a wooden walking stick tapping, thak thak, on a wooden floor"),
 'tap_creak':(2.0,"An old stiff metal tap handle creaking as someone strains to turn it, kirrr"),
 'water_pour':(3.0,"Clean fresh water suddenly rushing joyfully from a tap into a basin, bright happy stream"),
 'magic_chime':(2.0,"A warm magical golden chime with a soft metallic clink at the end, like something snapping into place"),
 'soap_bubbles':(3.5,"Soap lather bubbling and squeaking between small hands, foamy playful scrubbing"),
 'splash_play':(3.0,"Small hands splashing water playfully, giggly splashes"),
 'sponge_lather':(3.0,"A big sponge squelching up a huge amount of foam, comic squelches building"),
 'towel_soft':(1.5,"A soft towel rubbing dry, gentle fabric sounds"),
 'soup_slurp':(1.5,"A small cozy spoonful of warm soup being sipped"),
 'snore_soft':(4.0,"A small boy's soft sweet rhythmic snores, peaceful"),
 'yawn_big':(2.0,"A small boy's big sweet sleepy yawn"),
 'crickets_eve':(5.0,"Gentle evening crickets, calm and warm, distant single bell"),
 'hush_room':(3.0,"A quiet room tone with soft slow breathing, deeply peaceful"),
}
for n,(s,p) in SFX.items():
    f=f'sfx/{n}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>2000: print('SKIP',n); continue
    post('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',
         {'text':p,'duration_seconds':s,'prompt_influence':0.5},f)
print("SCORE:",len([f for f in os.listdir('score') if f.endswith('.mp3')]),"/3 · SFX:",len([f for f in os.listdir('sfx') if f.endswith('.mp3')]),"/23")
PY
