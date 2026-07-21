#!/bin/bash
# Full book art: 14 spreads + cover + lesson vignette, 4k, sequential (CLI dislikes parallel).
cd /Users/dusty/Dev/metaphrand/stories/kuku/book
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
S="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is the exact locked design of one character; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo. FULL-BLEED CHILDREN'S PICTURE BOOK ILLUSTRATION, generous open composition, no text anywhere."
E="NEGATIVE: no text, no letters, no readable symbols, no captions, no watermark, no logos, no photorealism, no live action, no human figures."

gen() { local n="$1" refs="$2" desc="$3"
  [ -s "$n.png" ] && { echo "SKIP $n"; return; }
  local out url
  out=$(higgsfield generate create nano_banana_pro --prompt "$S $desc $E" --image "$STYLE" $refs --aspect_ratio 1:1 --resolution 4k --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
  [ -n "$url" ] && curl -s -o "$n.png" "$url" && echo "OK $n" || echo "FAIL $n"
  sleep 2
}

K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; P="--image $CS/papa.png"; L="--image $CS/kalu.png"

gen bp01 "$K" "SCENE: Kuku the small moss-green baby dragon crawls happily through wet morning paper grass in a garden, paper dog-ears strapped on his head, a stick in his mouth, tail up, delighted; paper flowers, morning sun."
gen bp02 "$K $P" "SCENE: Kuku the small green baby dragon with paper dog-ears holds up a crayon drawing of a black dog to Papa, the big dark-green dragon crouched by a paper tool shed; Papa looks at it kindly but shakes his head gently."
gen bp03 "$D $K $F $V" "SCENE: Dadi Maya the grey spectacled grandmother dragon lifts a cloth from her sunny flat rock as warm golden light blooms out; Kuku, Furia and Vesper lean in with wonder; the glowing thing is a soft featureless golden radiance."
gen bp04 "$D $K $F $V" "SCENE: the three dragon children each draw a straight flat line in the air above their heads with one claw, following Dadi Maya the grey grandmother dragon; faint golden trails of light follow their claws; sunny rock, joyful learning."
gen bp05 "$K $F $V" "SCENE: on a dusty paper path, Kuku the green baby dragon and Furia the pink-red dragon girl hunt for treasures while Vesper the soft blue dragon boy far behind stands frozen, one ear turned toward an old stone paper well, one claw pointing."
gen bp06 "$F $L" "SCENE: close and tender: Kalu the tiny black cut-paper puppy with floppy ears stuck in brown paper mud at the foot of the old stone well, trembling, big scared eyes; Furia the pink-red dragon girl crouched low beside him, soft and gentle."
gen bp07 "$K $L $F" "SCENE: Kuku the green baby dragon laughs as Kalu the tiny black puppy licks his face; a squashed yellow paper banana lies ignored on the ground; Furia the pink-red dragon girl giggles behind; by the old stone well, joyful."
gen bp08 "$K $L" "SCENE: comic chaos in a cozy paper backyard: Kalu the tiny black puppy mid-leap through the air, shiny steel paper bowls scattering and bouncing everywhere, mud pawprints across the yard, Kuku the green baby dragon chasing with a rag, overwhelmed."
gen bp09 "$K $L $P" "SCENE: quiet after chaos: Kuku the green baby dragon sits in the messy yard holding the sleeping black puppy in his lap, thoughtful; in the far background Papa the big dark-green dragon walks out the gate with a sack, unaware."
gen bp10 "$K $L" "SCENE: alarm at golden hour: Kalu the tiny black puppy slips over the rim of the old stone paper well chasing a fat grey paper pigeon that flies clear; his front paws cling to the rim, eyes wide; Kuku the green baby dragon runs toward him in fear."
gen bp11 "$F $V $L" "SCENE: Furia the pink-red dragon girl lies flat on the well rim stretching both arms down toward the clinging black puppy but cannot reach; Vesper the soft blue dragon boy holds her tail and gazes calmly upward as if seeing an idea."
gen bp12 "$K $F $V" "SCENE: the hero moment: Kuku the small green baby dragon, eyes shut, belly puffed, breathes out a blazing warm golden radiance above the old stone well; Furia and Vesper watch with hope; sparkles rain; the radiance is featureless golden light."
gen bp13 "$K $L $P" "SCENE: warm evening room: Papa the big dark-green dragon kneels with his hand on the head of Kuku the small green baby dragon, who hugs the clean black puppy; a full food bowl and a folded blanket wait in the corner; golden lamplight."
gen bp14 "$D $K $F $V" "SCENE: starry night at the grandmother's rock: Furia the pink-red dragon girl proudly holds up a little paper notebook; Kuku the green baby dragon claps; behind them Vesper the soft blue dragon boy lies fast asleep curled around the black puppy while Dadi Maya the grey grandmother dragon pulls a blanket over them."
gen bpcover "$K $L $F $V" "SCENE: book cover composition with open sky space at the top: Kuku the small green baby dragon stands proudly in the middle of the sunny paper valley hugging Kalu the tiny black puppy; Furia the pink-red dragon girl and Vesper the soft blue dragon boy celebrate on either side; golden shapes of light float up like balloons."
gen bplesson "" "SCENE: a clean teaching vignette on soft cream paper background: three cut-paper objects arranged in a friendly row with space around each: a cute brown paper puppy, a large paper ear shape, and a yellow paper banana; simple, iconic, uncluttered."
echo "ART: $(ls bp*.png 2>/dev/null | wc -l | tr -d ' ')/16"
