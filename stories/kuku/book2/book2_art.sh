#!/bin/bash
# Ep2 book art: 16 square 4k illustrations (cover + 14 spreads + lesson).
cd /Users/dusty/Dev/metaphrand/stories/kuku/book2
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated. SQUARE children's picture-book page, full-bleed scene."
EN="NEGATIVE: no readable text, no letters, no captions, no watermark, no logos, no photorealism, no theater curtains, no stage, no frame-within-frame, nothing scary."
art() { local n="$1" refs="$2" desc="$3"
  [ -s "$n.png" ] && { echo "SKIP $n"; return; }
  local out url
  out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc $EN" --image "$STYLE" $refs --aspect_ratio 1:1 --resolution 4k --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
  [ -n "$url" ] && curl -s -o "$n.png" "$url" && echo "OK $n" || echo "FAIL $n"
  sleep 1
}
K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; M="--image $CS/mitasur.png"; L="--image $CS/kalu.png"
art b2cover "$K $F $V $L" "Kuku, Fyuria, Vesper and puppy Kalu tumbling joyfully into a bright paper fairground morning, bunting and stalls, peacock family parading."
art b201 "$K" "Kuku the small green baby dragon delightedly holding up a paper postcard at the bright fairground, bunting behind."
art b202 "$D" "Dadi Maya the grey spectacled grandmother dragon gesturing up at festive banners over her colorful sweets stall, bright fair morning."
art b203 "$M" "Mitasur the grey-purple goblin on a dusk hilltop sweeping one sponge-hand across the sky, golden light streaming up from the tiny fair below into his burlap sack."
art b204 "$D" "Dadi Maya dismayed at her sweets stall as bright paper sweets fade to grey; beside the stall a papercraft peacock's tail hangs flat and drooping."
art b205 "" "A tiny fuzzy peachick by a paper stream with its beak open but silent, looking lost; across the pond its mother peahen searches anxiously; pale still water."
art b206 "$D $K $F $V" "Dadi Maya at her flat teaching rock with a warm golden glow floating above it, the three dragon kids gathered close, morning light."
art b207 "$V $F" "Sleepy Vesper the soft blue dragon boy gazing up dreamily while Fyuria the pink-red dragon girl teases him fondly, teaching rock morning."
art b208 "$K $F $V $L $M" "The three dragon kids and puppy Kalu chasing Mitasur the grey-purple goblin through a faded grey paper fair, Kalu nose down on a trail, comic chase energy."
art b209 "$V" "Vesper the soft blue dragon boy standing very still in the grey fair, pointing toward a fat clay pot with a thread of golden light leaking from its lid, huge papercraft sound-rings beginning to burst outward from him."
art b210 "$M" "Mitasur the grey-purple goblin hugging his glowing burlap sack tightly by the stream, tearful defiant eyes, the whole valley frozen still around him."
art b211 "$K $F $V" "Kuku the small green baby dragon planting his feet at the stream bank drawing an enormous breath, Fyuria and Vesper cheering him on, a chick teetering at the water's edge across the stream, golden hour."
art b212 "" "A small curved boat of warm golden light carrying a tiny fuzzy peachick across a golden-hour paper stream toward its mother peahen whose wings open wide; golden letters streaming home across the sky above; color flooding back into the fair behind."
art b213 "$K $M" "Kuku the small green dragon kneeling with Mitasur the grey-purple goblin who cups a tiny wobbly golden glow in his sponge-hands, eyes enormous with wonder and joy, mud and grass."
art b214 "$K $D --image ../charsheets/papa.png" "Evening fair lights: Papa the big dark-green dragon kissing the top of Dadi Maya's grey head while small Kuku looks up wide-eyed." 
art b2lesson "$D" "Dadi Maya the grey grandmother dragon smiling warmly beside a large soft golden glow floating above her teaching rock, cozy evening, fireflies."
echo "ART: $(ls b2*.png 2>/dev/null | wc -l | tr -d ' ')/16"
