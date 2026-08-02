#!/bin/bash
# Scene 1 stills — built exactly like the Kuku pipeline.
# ONE hardcoded style key for the whole show. Short shot descriptions. Fixed preamble + negative block.
cd "$(dirname "$0")"
STYLE=856a99ee-5cc9-4fad-ad8d-998d79edb4f4
CS=../charsheets
A="--image plates/s1_underfloor_wide.png"
K="--image plates/prop_sock.png"
F="--image $CS/frosya_lowpoly_v2.png"
V="--image $CS/vasya_lowpoly.png"
mkdir -p stills

SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: when a place image is attached, match its floorboards, joists, back wall, cobwebs and shafts of light EXACTLY — same place, different angle. PROP REFERENCE: when the sock image is attached, it is the one and only sock — same stripes, same size, a limp empty sock dragged along the floor. Low poly 3D, faceted geometry, warm saturated colours, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon. Фрося is the taller older sister on the left; Вася is the shorter younger brother on the right."

EN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no readable text, no letters, no numbers, no captions, no watermark, no logos, no photorealism, no live action, no realistic humans, no shoes, no extra characters, no giant foot or leg in the tunnel, nothing scary, nobody in danger."

still() { local n="$1" refs="$2" desc="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local out url
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  raw=sys.stdin.read(); i=raw.find('[')
  d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
  d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 4; return; }
    echo "retry $t $n"; sleep 12
  done
  echo "FAIL $n"
}

still k1_haul     "$A $K $F $V" "Фрося and Вася dragging the huge striped sock leftward along THE SAME under-floor tunnel from the place reference, both leaning into the pull, bare feet braced, straining."
still k2_asks     "$A $K $F $V" "Вася turning his head to his sister while they drag the sock, mouth open asking a question, out of breath."
still k3_answers  "$A $K $F $V" "Фрося dragging the sock and answering matter-of-factly, chin up, not looking back."
still k4_hears    "$A $K $F $V" "Фрося stopping mid-drag, head tilted up, listening hard to a faint creak above, Вася not yet noticing."
still k5_zamri    "$A $K $F $V" "Фрося throwing one arm up in a sharp stop gesture, looking up at the ceiling, Вася jolting to a halt beside her."
still k6_dust     "$A $K $F $V" "THE SAME tunnel gone dim as the light from the gap above is blocked, pale dust pouring down onto the two frozen children looking up."
still k7_after    "$A $K $F $V" "The warm light returned to THE SAME tunnel, the two standing small and still beside the sock, last dust settling."

echo "STILLS: $(ls stills/k*.png 2>/dev/null | wc -l | tr -d ' ')/7"
