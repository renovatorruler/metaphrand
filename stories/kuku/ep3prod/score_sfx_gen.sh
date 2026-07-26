#!/bin/bash
# Ep3 score (3 new cues; cue1/cue3/cue6/cue7 reused from Ep2) + the SFX library —
# this is the first SFX-forward episode; रीछ's growls ARE his voice.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep3prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p score sfx
python3 <<'PY'
import json, subprocess, os
def post(url, body, out):
    subprocess.run(['curl','-s','-X','POST',url,
      '-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
      '-d',json.dumps(body),'-o',out],capture_output=True)
    ok=os.path.exists(out) and os.path.getsize(out)>20000
    print('OK' if ok else 'FAIL', out, os.path.getsize(out) if os.path.exists(out) else 0)

CUES={
 'cueA_evening': (52000, "Warm gentle evening cue for a children's papercraft cartoon: soft ukulele and music box, contented humming feeling, a proud little character painting his new front door at dusk; crickets-and-lanterns coziness; ends with a hopeful lift. One cohesive instrumental cue, never scary."),
 'cueB_night': (75000, "Quiet night-mystery cue for a children's cartoon: hushed pizzicato and soft low woodwinds over cricket-time stillness; something big and gentle sniffs around in the dark; a rope strains; at the end a sudden lurch — tension rises but stays kid-safe, curious not frightening. Instrumental, cohesive."),
 'cueC_chase': (90000, "Night rescue cue for a children's cartoon: rolling urgent rhythm like cart wheels downhill, breathless chase energy; midway a clever calm regroup passage (a plan forms); builds to a held-breath hush, then one huge triumphant STOP hit followed by warm relieved release and a tender discovery ending. Instrumental, cohesive, never scary."),
}
for name,(ms,prompt) in CUES.items():
    f=f'score/{name}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>50000: print('SKIP',name); continue
    post('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
         {'prompt':prompt,'music_length_ms':ms,'model_id':'music_v1','force_instrumental':True}, f)

SFX={
 'brush_strokes': (3.0, "Wet paint brush strokes on wood, gentle rhythmic painting, close and soft"),
 'walkoff': (3.5, "A happy group of children walking away on a dirt path, footsteps and fading giggles, one small dog bark"),
 'sniff_steps': (4.0, "Heavy soft padded footsteps approaching slowly with big animal sniffing, snuffling curious nose sounds"),
 'creak_strain': (3.0, "Wood creaking under weight and a thick rope stretching and straining, tension building"),
 'rope_snap': (1.5, "A thick rope snapping with a sharp twang and whip crack"),
 'wheels_roll': (6.0, "Wooden cart wheels rumbling and rolling on a dirt path, gaining speed, rhythmic wooden clatter"),
 'wheels_fast': (4.0, "Wooden cart wheels rumbling very fast downhill, urgent rattling clatter"),
 'rope_catch': (1.8, "A taut rope twanging as it catches something heavy, deep musical twang plus wood groan"),
 'stop_splash': (4.0, "Wooden wheels screeching and grinding to a slow stop on gravel, then silence, then one tiny gentle water splash"),
 'soft_tumble': (2.0, "Something big, heavy and soft tumbling gently onto thick grass with a muffled flump"),
 'tummy_hungry': (2.8, "A long comical hungry stomach rumble, deep gurgling growl, cartoonish"),
 'tummy_happy': (2.5, "A satisfied happy stomach gurgle after a big meal, content and warm, cartoonish"),
 'big_bite': (3.0, "One enormous comical bite of bread followed by happy loud chewing, cartoonish"),
 'cheer_clap': (3.5, "A small village crowd of children and grown-ups cheering and clapping happily outdoors"),
 'brush_three': (3.5, "Three slow deliberate wet paint brush strokes on wood, careful and gentle, a pause between each"),
 'pencil': (2.0, "A pencil writing carefully on paper, soft scratching, close"),
 'growl_hungry': (3.5, "A big gentle bear's long low hungry growl, rolling rrr sound, deep but friendly, not scary"),
 'growl_scared': (2.0, "A big gentle bear's short worried yelping growl, rising in pitch, frightened but soft"),
 'growl_question': (1.5, "A big gentle bear's short questioning growl, curious rising tone, almost a purr"),
 'growl_shy': (1.8, "A big gentle bear's quiet shy embarrassed rumble, soft and low"),
 'growl_happy': (3.0, "A big gentle bear's long delighted contented purring growl, rolling rrr, joyful"),
 'growl_snore': (4.0, "A big bear snoring softly and rhythmically, each exhale a gentle rolling rrr purr"),
 'kalu_rrr': (2.0, "A small puppy doing a perfect playful rolling rrr growl, cute trilled growl, proud"),
 'kalu_bark': (1.2, "One small proud happy puppy bark"),
}
for name,(secs,prompt) in SFX.items():
    f=f'sfx/{name}.mp3'
    if os.path.exists(f) and os.path.getsize(f)>2000: print('SKIP',name); continue
    post('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',
         {'text':prompt,'duration_seconds':secs,'prompt_influence':0.5}, f)
print("SCORE:", len([f for f in os.listdir('score') if f.endswith('.mp3')]), "/3 new")
print("SFX:", len([f for f in os.listdir('sfx') if f.endswith('.mp3')]), "/24")
PY
