#!/bin/bash
# Full-episode shot runner: keeps ≤7 jobs in flight (limit is 8; leave 1 slot slack),
# fetches completed jobs to free slots, retries rate-limits. 29 shots total.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/full
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
touch jobs.txt

submit() { # name -> id or empty
  local prompt; prompt=$(grep "^$1|||" prompts.txt | sed 's/^[^|]*|||//')
  higgsfield generate create gemini_omni --prompt "$prompt" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')"
}

fetch() { # name id
  local url; url=$(higgsfield generate wait "$2" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "$1.mp4" "$url"; echo "GOT $1"; else echo "FAILED $1 $2"; fi
}

declare -a INFLIGHT_N INFLIGHT_I
names=$(grep -oE "^[^|]+" prompts.txt)
for n in $names; do
  [ -s "$n.mp4" ] && continue
  # already submitted in a previous run?
  prev=$(awk -v n="$n" '$1==n{print $2}' jobs.txt | tail -1)
  if [ -n "$prev" ]; then INFLIGHT_N+=("$n"); INFLIGHT_I+=("$prev"); continue; fi
  while :; do
    if [ "${#INFLIGHT_N[@]}" -ge 7 ]; then
      fetch "${INFLIGHT_N[0]}" "${INFLIGHT_I[0]}"
      INFLIGHT_N=("${INFLIGHT_N[@]:1}"); INFLIGHT_I=("${INFLIGHT_I[@]:1}")
    fi
    id=$(submit "$n")
    if [ -n "$id" ] && [ "$id" != "None" ]; then
      echo "$n $id" >> jobs.txt
      INFLIGHT_N+=("$n"); INFLIGHT_I+=("$id")
      echo "SUBMITTED $n"
      break
    fi
    # rate limited: drain one and retry
    if [ "${#INFLIGHT_N[@]}" -gt 0 ]; then
      fetch "${INFLIGHT_N[0]}" "${INFLIGHT_I[0]}"
      INFLIGHT_N=("${INFLIGHT_N[@]:1}"); INFLIGHT_I=("${INFLIGHT_I[@]:1}")
    else
      sleep 30
    fi
  done
done
# drain remaining
for k in "${!INFLIGHT_N[@]}"; do fetch "${INFLIGHT_N[$k]}" "${INFLIGHT_I[$k]}"; done
echo "SHOTS: $(ls s*.mp4 2>/dev/null | wc -l | tr -d ' ')/29"
