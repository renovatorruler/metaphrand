#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/titles
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
> shot_jobs.txt
while IFS= read -r line; do
  n="${line%%|||*}"; prompt="${line#*|||}"
  id=$(higgsfield generate create gemini_omni --prompt "$prompt" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin)
print(d[0] if isinstance(d,list) and d and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id')))")
  echo "$n $id" >> shot_jobs.txt
done < shot_prompts.txt
echo "SUBMIT_DONE" >> shot_jobs.txt
