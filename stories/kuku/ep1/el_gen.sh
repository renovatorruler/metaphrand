#!/bin/bash
# KUKU Ep1 — full cast render on ElevenLabs v3 with expression tags. 107 calls, 4 workers.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1
export $(grep ELEVENLABS ../../../.env)
mkdir -p el

python3 -c "
import json
for i,l in enumerate(json.load(open('el_plan.json'))):
    t=l['el_text'].replace('\t',' ').replace('\n',' ')
    print(f\"{i}\t{l['who']}\t{t}\")
" > el_lines.tsv

vid_for() {
  case "$1" in
    KUKU)        echo "NbvR1eY6Q8ivACdEO8PV";;  # Amit
    FURIA)       echo "FFmp1h1BMl0iVHA0JxrI";;  # Tarini
    VESPER)      echo "subIZc6skATBQ1Rbqpi7";;  # Mahira J
    "DADI MAYA") echo "nfMYisZqs1GOjTFllho3";;  # Gungun
    PAPA)        echo "5ycO0zpSCEkvR4Ri6gk9";;  # Shyam
    CHEEKU)      echo "nUX4UWK0Tf1qh5zvFZWR";;  # Mini
    MUKHIYA)     echo "THK4VmOwUWou6Ja9qSM4";;  # Manish
    RADIO)       echo "ocf4J1Vk0yOOFNBy3kNq";;  # Ranga
    *)           echo "5ycO0zpSCEkvR4Ri6gk9";;
  esac
}

gen_one() {
  local idx="$1" who="$2" text="$3"
  [ -s "el/$idx.mp3" ] && return 0
  local vid; vid=$(vid_for "$who")
  local payload; payload=$(python3 -c "import json,sys; print(json.dumps({'text': sys.argv[1], 'model_id': 'eleven_v3'}))" "$text")
  curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$vid?output_format=mp3_44100_128" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
    -d "$payload" -o "el/$idx.mp3"
  # sanity: JSON error responses are small text files
  if [ "$(wc -c < "el/$idx.mp3" | tr -d ' ')" -lt 2000 ]; then
    echo "FAIL $idx $who: $(head -c 120 "el/$idx.mp3")"
    rm -f "el/$idx.mp3"
  else
    echo "OK $idx $who"
  fi
}

worker() {
  local k="$1"
  while IFS=$'\t' read -r idx who text; do
    [ $((idx % 4)) -eq "$k" ] && gen_one "$idx" "$who" "$text"
  done < el_lines.tsv
}

for k in 0 1 2 3; do worker "$k" & done
wait

# retry pass
while IFS=$'\t' read -r idx who text; do
  [ -s "el/$idx.mp3" ] || { sleep 2; gen_one "$idx" "$who" "$text"; }
done < el_lines.tsv

echo "RENDERED: $(ls el | wc -l | tr -d ' ')/107"
