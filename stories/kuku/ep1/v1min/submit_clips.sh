#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/v1min
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
> clip_jobs.txt
while IFS= read -r line; do
  n="${line%%|||*}"; prompt="${line#*|||}"
  id=$(higgsfield generate create gemini_omni --prompt "$prompt" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin)
print(d[0] if isinstance(d,list) and d and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id')))")
  echo "CLIP_$n $id" >> clip_jobs.txt
done < clip_prompts.txt
echo "SUBMIT_DONE" >> clip_jobs.txt
