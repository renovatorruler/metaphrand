#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/titles
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9

fetch() { # name id -> download when done
  local n="$1" id="$2"
  local url; url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "$n.mp4" "$url"; echo "GOT $n"; else echo "FAILED $n $id"; fi
}

# wait for the 8 running jobs (frees slots as they complete)
while read -r n id; do
  [ "$n" = "SUBMIT_DONE" ] && break
  [ -s "$n.mp4" ] || fetch "$n" "$id"
done < shot_jobs.txt

# now submit E2-E4 with free slots, retrying on rate limit
for n in E2 E3 E4; do
  [ -s "$n.mp4" ] && continue
  prompt=$(grep "^$n|||" shot_prompts.txt | sed 's/^[^|]*|||//')
  for try in 1 2 3 4 5; do
    id=$(higgsfield generate create gemini_omni --prompt "$prompt" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); print(d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id')))
except Exception: print('')")
    if [ -n "$id" ] && [ "$id" != "None" ]; then echo "$n $id" >> shot_jobs.txt; fetch "$n" "$id"; break; fi
    echo "$n submit retry $try (rate limit)"; sleep 45
  done
done

echo "SHOTS READY: $(ls T*.mp4 E*.mp4 2>/dev/null | wc -l | tr -d ' ')/11"
