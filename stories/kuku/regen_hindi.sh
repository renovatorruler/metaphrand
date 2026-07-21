#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku
VOICE="Riya (hi)"
declare -A T
T[2]="कुकु ने फूँक मारी। पर आग नहीं आई। बस थोड़ा धुआँ निकला। चीकू हँसने लगा। कुकु उदास हो गया।"
T[3]="दादी माया बोलीं, आग रहने दे। सोच, तुझे क्या अच्छा लगता है? कुकु ने सोचा, दोस्त और माँ।"
T[4]="कुकु ने आँखें बंद कीं, बड़ी साँस भरी, और फूँक मारी। आग नहीं आई। एक चमकता सुनहरा आकार आसमान में तैरा!"
T[5]="दादी माया मुस्कुराईं। देखो कुकु, ये तो अक्षर है! ये है क! आज का अक्षर है, क!"
T[6]="क से कुत्ता, क से कान, क से केला! बोलो मेरे साथ, क! सब बोले, कुकु का क! अलविदा!"
echo "RIYA_1 93d73ae9-20db-4f34-857d-70e1dfe1dd1d" > riya_jobs.txt
for i in 2 3 4 5 6; do
  out=$(higgsfield generate create inworld_text_to_speech --prompt "${T[$i]}" --voice "$VOICE" --wait --json 2>/dev/null)
  id=$(echo "$out" | python3 -c "import sys,json;d=json.load(sys.stdin);d=d[0] if isinstance(d,list) else d;print(d.get('id'))")
  url=$(echo "$out" | python3 -c "import sys,json;d=json.load(sys.stdin);d=d[0] if isinstance(d,list) else d;print(d.get('result_url') or '')")
  curl -s -o "/tmp/riya$i.wav" "$url"
  dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "/tmp/riya$i.wav")
  echo "RIYA_$i $id $dur" >> riya_jobs.txt
done
echo "REGEN_DONE" >> riya_jobs.txt
