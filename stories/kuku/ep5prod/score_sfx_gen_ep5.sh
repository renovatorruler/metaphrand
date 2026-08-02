#!/bin/bash
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p score sfx
python3 <<'PY'
import json, subprocess, os
def post(url,body,out):
    subprocess.run(['curl','-s','-X','POST',url,'-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}',
      '-H','Content-Type: application/json','-d',json.dumps(body),'-o',out],capture_output=True)
    print('OK' if os.path.getsize(out)>20000 else 'FAIL', out)
CUES={
 'cueP1_kite':(70000,"Bright breezy kite-flying morning for a children's papercraft cartoon: skipping ukulele, glockenspiel, fluttering wind textures, carefree children running; near the end the music thins to a single held uneasy note, as if something small has gone wrong. Instrumental, cohesive, never scary."),
 'cueP2_break':(70000,"Afternoon unease for a children's cartoon: warm strings that keep glancing over their shoulder; at 30 seconds a wooden groan and a sudden drop into hush; then a steady, brave, problem-solving pulse — no danger, no menace, just a valley realising it has a problem. Instrumental, cohesive."),
 'cueP3_teach':(85000,"Teaching-across-the-water cue: patient music box and soft strings that stay UNDER a shouted lesson, leaving space for a voice calling over a river; playful call-and-response lifts, a warm golden reveal in the middle, unhurried throughout. Instrumental, cohesive."),
 'cueP4_search':(90000,"Dusk search cue for a children's cartoon: low patient pulse, hands working in shallow water, light draining from the sky; midway it turns tender and honest — a child telling the truth — then an adult's quiet confession, warm and steady, resolving into hope. Instrumental, cohesive, never sad-scary."),
 'cueP5_bridge':(75000,"Triumphant building cue for a children's cartoon: a golden letter locking into stone, two solid clunks, then a wide warm sunrise-like bloom as a bridge holds; celebration with dhol and glockenspiel, everyone crossing home; settles into a tender goodnight in the last 20 seconds. Instrumental, cohesive."),
}
for n,(ms,p) in CUES.items():
    f=f'score/{n}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>50000: print('SKIP',n); continue
    post('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
         {'prompt':p,'music_length_ms':ms,'model_id':'music_v1','force_instrumental':True},f)
SFX={
 'wind_gust':(4.0,"A strong gust of wind through an open valley, paper kite fluttering hard"),
 'kite_flutter':(3.5,"A paper kite flapping and rustling in the wind, high and light"),
 'string_snap':(1.2,"A taut kite string snapping with a sharp twang, then loose flapping"),
 'run_planks':(3.5,"Quick light footsteps running across old wooden planks of a small bridge, hollow knocking"),
 'rope_creak':(3.0,"Old rope bridge ropes creaking and straining slowly"),
 'two_foot_thud':(1.5,"Both feet landing hard together on a wooden plank, one solid thud"),
 'crack_kadak':(2.0,"A single loud sharp wood crack, a dry splitting KRAK, then silence"),
 'bridge_collapse':(4.5,"Old wooden bridge planks groaning, snapping and falling into rushing water, big splash"),
 'stream_loud':(6.0,"A fast shallow stream running loudly over stones, constant"),
 'stick_taps':(3.0,"An elderly walking stick tapping slowly on stony ground, thak thak"),
 'bear_wade_slip':(3.5,"A big heavy animal wading into a stream, paws slipping on mossy round stones, then a huge splash"),
 'letter_land_sink':(4.0,"A heavy wooden object settling into water then sinking into soft sand, water sucking, then a big splash"),
 'letter_bump':(3.0,"A large wooden object knocking gently and repeatedly against a river bank, hollow tock tock"),
 'hands_in_water':(4.0,"Hands searching in shallow water, sloshing and patting the riverbed"),
 'stone_knock':(1.2,"A knuckle knocking twice on a flat submerged stone, dull tok tok underwater"),
 'letter_lock_stone':(2.5,"A heavy object clamping onto stone with a solid metallic-wooden lock, one firm CLUNK"),
 'deck_tighten':(2.5,"Wooden planks pulling taut and locking into place, creaking then going firm"),
 'heavy_steps_bridge':(4.0,"Heavy deliberate footsteps walking across a solid wooden bridge, three slow steps"),
 'crowd_cheer_small':(3.5,"A small group of children and adults cheering and clapping outdoors, happy"),
 'kalu_scared_bark':(2.0,"A small puppy barking nervously twice then whining"),
 'kalu_relief':(1.5,"A small puppy whining with relief then a happy little yip"),
 'evening_crickets':(5.0,"Evening crickets by a stream, calm and warm, distant"),
 'snore_soft_boy':(4.0,"A small boy snoring softly and peacefully, gentle rhythm"),
 'birds_scatter2':(2.0,"A flock of small birds startling and flapping away in alarm"),
}
for n,(s,p) in SFX.items():
    f=f'sfx/{n}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>2000: print('SKIP',n); continue
    post('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',
         {'text':p,'duration_seconds':s,'prompt_influence':0.55},f)
print("SCORE:",len(os.listdir('score')),"| SFX:",len(os.listdir('sfx')))
PY
