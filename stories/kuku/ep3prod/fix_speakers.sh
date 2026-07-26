#!/bin/bash
# Speaker-on-screen law: every take plays over a still that shows its speaker.
# Applies the 13 audit mismatches + de-bridges the long takes that spilled onto
# other characters' faces. Then rebuilds affected scenes and republishes the
# no-title review cut.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep3prod
python3 <<'PY'
import json
e = json.load(open('ep3_edl.json'))
sc = {x['name']: x for x in e['scenes']}

# s1b: Fyuria's 17s speech stays on her, full length; Mitasur reacts in his own beat
sc['s1b_utsav']['segments'][1] = {"src":"still:e3_fyuria_evening","takes":[{"i":12,"at":0.5}]}
sc['s1b_utsav']['segments'][2] = {"src":"still:e3_mitasur_paint","takes":[{"i":13,"at":0.5}]}

# s2a: chorus responses on the kids-group still; Dadi's shape lesson full-length on her
s2a = sc['s2a_lesson']['segments']
s2a[3] = {"src":"still:e3_kids_rock","takes":[{"i":18,"at":0.3}]}
s2a[5] = {"src":"still:e3_kids_rock","takes":[{"i":20,"at":0.3}]}
s2a[7] = {"src":"still:e3_kids_rock","takes":[{"i":22,"at":0.3}]}
s2a[8] = {"src":"still:s_dadi_rock","takes":[{"i":23,"at":0.5}],
          "fx":[{"png":"glyphs/fx_r.png","at":1.5,"scale":0.30,"pos":"tc"}]}
del s2a[9]  # the fyuria reaction cutaway
s2a[9] = {"src":"still:s_vesper_rock","takes":[{"i":24,"at":0.5}]}

# s2b: both long Dadi takes full-length on her
s2b = sc['s2b_game']['segments']
s2b[0] = {"src":"still:s_dadi_rock","takes":[{"i":27,"at":0.5}]}
s2b[1] = {"src":"still:e3_kuku_rock","takes":[{"i":28,"at":0.5}]}
s2b[8] = {"src":"still:s_dadi_rock","takes":[{"i":35,"at":0.5}]}
s2b[9] = {"src":"still:e3_mitasur_rock","dur":4.5}

# s5a: Kuku's stake line gets the forge frame (he's in it), rope pair keeps theirs
s5a = sc['s5a_rescue']['segments']
s5a.insert(3, {"src":"still:e3_forge_frame","takes":[{"i":56,"at":0.5}]})
s5a[4] = {"src":"still:e3_rope_team","takes":[{"i":57,"at":0.5},{"i":58}]}

# s5b: kids speak on frames that show them; the bear gets his own wordless beats
sc['s5b_bhookh']['segments'] = [
 {"src":"still:e3_forge_frame","takes":[{"i":64,"at":0.5}]},
 {"src":"still:e3_mitasur_night","takes":[{"i":65,"at":0.4}]},
 {"src":"still:e3_reechh_grass","dur":3.8,"takes":[{"sfx":"tummy_hungry","at":0.6}]},
 {"src":"still:e3_forge_frame","takes":[{"i":66,"at":0.5},{"i":67},{"i":68}]},
 {"src":"still:e3_reechh_grass","dur":3.0,"takes":[{"sfx":"growl_question","at":0.5}]},
 {"src":"still:e3_forge_frame","takes":[{"i":70,"at":0.4}]}]

# s6a: Fyuria presents the bear on her own feast still; Kuku's line over the crowd filler-take
s6a = sc['s6a_feast']['segments']
s6a[1] = {"src":"still:e3_fyuria_feast","takes":[{"i":72,"at":0.5},{"sfx":"growl_shy","at":6.4}]}
s6a.insert(2, {"src":"still:e3_feast_dadi","takes":[{"i":74,"at":0.5}]})
s6a[4] = {"src":"file:clips/c38_f2.mp4","in":0.0,"dur":6.0,
          "takes":[{"sfx":"growl_happy","at":0.2,"duck":False},{"i":76,"at":1.7}]}

# s6b: Dadi's call on her still; the name beat stays Mitasur's; chant over the crowd
sc['s6b_naam']['segments'] = [
 {"src":"still:e3_feast_dadi","takes":[{"i":77,"at":0.6}]},
 {"src":"still:e3_mitasur_name","takes":[{"i":78,"at":0.8}],
  "fx":[{"png":"glyphs/naam1.png","at":0.5,"scale":0.5,"pos":"bc"}]},
 {"src":"clip:c31_paint","in":2.5,"dur":4.5,"takes":[{"sfx":"brush_three","at":0.4,"duck":False}]},
 {"src":"still:e3_mitasur_name","takes":[{"i":79,"at":0.5}],
  "fx":[{"png":"glyphs/naam2.png","at":0.4,"scale":0.5,"pos":"bc"}]},
 {"src":"file:clips/c38_f2.mp4","in":6.2,"dur":3.8,
  "takes":[{"sfx":"cheer_clap","at":0.2,"duck":False},{"i":80,"at":0.5}]},
 {"src":"still:e3_fyuria_roti","takes":[{"i":81,"at":0.5},{"i":82},{"i":83}]}]

# s7b: Fyuria's whisper on her किताब still; Dadi's reply on hers
s7b = sc['s7b_neeti']['segments']
sc['s7b_neeti']['segments'] = s7b[:4] + [
 {"src":"still:s_dadi_night","dur":8.6},
 {"src":"still:s_fyuria_kitab","takes":[{"i":91,"at":0.5},{"sfx":"pencil","at":3.4,"duck":False}]},
 {"src":"still:s_dadi_night","takes":[{"i":92,"at":0.4}]}]

json.dump(e, open('ep3_edl.json','w'), ensure_ascii=False, indent=1)
print('surgery applied')
PY
setopt null_glob 2>/dev/null || true
rm -f build/s1b_utsav_* build/s2a_lesson_* build/s2b_game_* build/s5a_rescue_* build/s5b_bhookh_* build/s6a_feast_* build/s6b_naam_* build/s7b_neeti_* \
      out/s1b_utsav.mp4 out/s2a_lesson.mp4 out/s2b_game.mp4 out/s5a_rescue.mp4 out/s5b_bhookh.mp4 out/s6a_feast.mp4 out/s6b_naam.mp4 out/s7b_neeti.mp4 \
      out/KUKU_EP3_V1.mp4
bash assemble_ep3.sh 2>&1 | tail -6
python3 - <<'PY'
lines=open('out/ep_cat.txt').read().split('\n')
open('out/ep_review_cat.txt','w').write('\n'.join(l for l in lines if l and 'title24' not in l)+'\n')
PY
ffmpeg -y -v error -f concat -safe 0 -i out/ep_review_cat.txt -c copy /tmp/ep3_rv.mp4
ffmpeg -y -v error -i /tmp/ep3_rv.mp4 -c:v copy -af "volume=-2.5dB" -c:a aac -b:a 192k -movflags +faststart /Users/dusty/kuku-public/KUKU_EP3_V1.mp4
echo "review cut republished: $(ffprobe -v error -show_entries format=duration -of csv=p=0 /Users/dusty/kuku-public/KUKU_EP3_V1.mp4)s"
