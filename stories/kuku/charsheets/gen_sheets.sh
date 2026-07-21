#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/charsheets
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
S="STYLE REFERENCE: Match the attached reference image EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft studio lighting, non-photorealistic, illustrated, not a photo, no live-action, no realism. CHARACTER REFERENCE SHEET: one single character, full body, standing in a friendly relaxed 3/4 pose, centered, on a plain soft cream paper background with a simple paper ground shadow, no scenery, no props except those named, no other characters."
E="NEGATIVE: no text, no letters, no captions, no watermark, no logos, no extra characters, no background scenery, no photorealism, no human features except those named."

gen() { local name="$1" desc="$2"
  local out url
  out=$(higgsfield generate create nano_banana_pro --prompt "$S $desc $E" --image "$STYLE" --aspect_ratio 3:4 --resolution 2k --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "$name.png" "$url"; echo "OK $name"; else echo "FAIL $name"; fi
}

gen kuku   "SUBJECT: Kuku, a small round moss-green cut-paper baby dragon, about four years old in feel; big friendly round eyes, chubby cream-colored belly, tiny paper wings, small rounded horns, short tail; sweet eager smile with mouth closed."
gen furia  "SUBJECT: Furia, a bright pink-red cut-paper dragon girl, a head taller than a baby dragon; confident sparky expression, long eyelashes, a small crest of paper spikes, cream belly, medium paper wings, a proud stance with hands on hips."
gen vesper "SUBJECT: Vesper, a soft light-blue cut-paper dragon boy, slightly smaller than his sister; dreamy half-lidded gentle eyes gazing slightly upward, relaxed sleepy smile, small paper wings, cream belly, loose relaxed posture."
gen dadi   "SUBJECT: Dadi Maya, an elderly GREY DRAGON grandmother, unmistakably a DRAGON: full dragon snout and muzzle, dragon horns, folded paper wings, long dragon tail, grey scales with a silvery sheen; grandmotherly warmth: small round spectacles perched on her dragon snout, a soft knitted paper shawl over her shoulders, kind crinkled smiling eyes; gently stooped, leaning slightly on nothing, warm and wise. She is a dragon, NOT a human; no human face, no human skin, no hair bun."
gen papa   "SUBJECT: Papa, a big broad dark-green cut-paper dragon father, tall and strong with wide shoulders; kind tired eyes, warm small smile, work-worn look, sturdy paper wings folded, thick tail; a simple work strap across his chest with a tiny paper radio clipped to it."
gen kalu   "SUBJECT: Kalu, a tiny black cut-paper puppy, all black with big soft floppy ears hanging down, big shiny adoring eyes, little wagging tail, sitting with head tilted; NOT a dragon, a puppy dog."
gen cheeku "SUBJECT: Cheeku, a very tiny yellow cut-paper toddler dragon, the smallest of all; round baby proportions, huge curious eyes, stubby little wings, sitting on his bottom holding a little paper spoon, giggling with mouth open showing one tooth."
echo "SHEETS: $(ls *.png 2>/dev/null | wc -l | tr -d ' ')/7"
