#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
VOICE=b0f766b7-8703-4bd1-b973-f857c36837b6

firstid() { python3 -c "import sys,json
d=json.load(sys.stdin)
print(d[0] if isinstance(d,list) and d and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id')))"; }

# --- videos: block 1 reused; submit 2..6 ---
echo "VIDEO_1 1ef98150-3555-41df-8e57-a1aaca48dacb" > video_jobs.txt
while IFS= read -r line; do
  n="${line%%|||*}"
  [ "$n" = "1" ] && continue
  prompt="${line#*|||}"
  id=$(higgsfield generate create gemini_omni --prompt "$prompt" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | firstid)
  echo "VIDEO_$n $id" >> video_jobs.txt
done < video_prompts.txt

# --- audio: regenerate trimmed 4,5,6 (originals ran long) ---
declare -A T
T[4]="कुकु ने आँखें बंद कीं, बड़ी साँस भरी, और फूँक मारी। आग नहीं आई। एक चमकता सुनहरा आकार आसमान में तैरा!"
T[5]="दादी माया मुस्कुराईं। देखो कुकु, ये तो अक्षर है! ये है क! आज का अक्षर है, क!"
T[6]="क से कुत्ता, क से कान, क से केला! बोलो मेरे साथ, क! सब बोले, कुकु का क! अलविदा!"
> audio_re.txt
for i in 4 5 6; do
  id=$(higgsfield generate create seed_audio --prompt "${T[$i]}" --voice_type preset --voice_id $VOICE --format mp3 --speech_rate 0 --json 2>/dev/null | firstid)
  echo "AUDIO_$i $id" >> audio_re.txt
done
echo "SUBMIT_DONE" >> video_jobs.txt
