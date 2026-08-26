#!/usr/bin/env bash
# Keyframe v2 fix round — refire KF11, 14, 17, 18 with corrected ref stacks + hard locks.
set -uo pipefail
cd "$(dirname "$0")"
R="../../ep1prod/scene1/references"
P="$R/packet_pages"
ROOM="$R/SET-HOME-ROOM-01_author_master_FINAL.png"
DOOR="$R/SET-YAGA-DOOR-01_approved_states.png"
PAPA="$R/papa_author_packet_v2.png"
STYLE="Cinematic film still in the exact stylized low-poly 3D render style of the reference images, warm hearth lighting, 16:9. Characters and the set MUST match the reference images exactly. The set is the tiny family's hall inside an old bricked-up fireplace per the room reference: giant boulder-scale red-brown brick courses, dark riveted iron plate wall with warm light seeping around its edges, four matchbox beds + knitted-mitten cradle, plank-on-spools banquet table with button stools, colored garland bulbs overhead, rusty arched iron door low in the left wall, railed floor opening in the far corner. No windows, no daylight, no sinks, no faucets, no modern fixtures. All characters fully in frame with complete bodies — no disembodied limbs."

gen () {
  local n="$1" prompt="$2"; shift 2
  local refargs=()
  for r in "$@"; do refargs+=(--image-references "$r"); done
  echo "=== KF$n-r2 start $(date +%H:%M:%S) ==="
  higgsfield generate create nano_banana_pro --prompt "$STYLE $prompt" \
    ${refargs[@]+"${refargs[@]}"} --aspect-ratio 16:9 --resolution 2k \
    --wait --wait-timeout 20m > "kf${n}_r2.url.txt" 2> "kf${n}_r2.err.txt"
  local u; u=$(grep -Eo 'https://[^ ]+\.png' "kf${n}_r2.url.txt" | tail -1)
  [ -n "$u" ] && curl -sL --max-time 120 -o "kf${n}_r2.png" "$u" && echo "KF$n-r2 OK"
}

gen 11 "Inside the hall: the covered present stands center frame — a patched cloth draped over a rounded object the size of a child. ПАПА — the bearded shaggy-haired father from the reference, wood shavings in his hair, blue shirt and suspenders, FULL BODY VISIBLE — stands directly behind the covered present, both hands gripping the edge of the cloth, about to whip it away, grinning. Фрося and Вася stand to the left watching with wide eyes; мама with both babies behind them. Every character complete and on-model." "$ROOM" "$PAPA" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png"

gen 14 "Close over-shoulder shot at the banquet table: ФРОСЯ holds ONE open round vintage candy tin matching the tin reference EXACTLY — inside the open tin, bare colored WAX CORES with NO paper wrappers LIE FLAT on their sides in stitched cloth loops, like short naked crayon cores lying down. Her finger touches the red core, her face delighted. МАМА stands DIRECTLY BESIDE her at the table, warm face close, babies peeking from her arms. The tin is one single object with its lid hinged open — not two separate containers. No upright crayons, no paper-wrapped crayons." "$R/D-FRO-ARTBOX-01_approved_tin.png" "$P/frosya-05.png" "$P/mama-06.png" "$ROOM"

gen 17 "Wide shot in the hall matching the room reference EXACTLY — same giant boulder bricks, same iron plate wall, same matchbox beds and railed corner. The whole family frozen mid-motion staring toward the little rusty arched iron door low in the LEFT brick wall — the door from the door reference, closed but rattling, thin wisps of soot puffing from its edges. All gaze lines locked on that door. МАМА clutches both babies; ПАПА — the bearded shaggy father from the reference — is half-risen from a button stool, eyebrows high, grin starting; ФРОСЯ and ВАСЯ stand shoulder to shoulder, wide-eyed. Two empty thimbles caught mid-jump above the shelf." "$ROOM" "$DOOR" "$PAPA" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png"

gen 18 "Tight claustrophobic shot INSIDE a short pitch-dark soot-caked brick passage — rough sooty giant bricks fill the entire frame on all sides, nothing else exists. At the far end of the passage, the little arched iron door from the reference has just BURST OPEN outward into warm light, and a thick cloud of black soot rushes toward the camera filling half the frame; through the soot glows the silhouette of a miniature wooden flying mortar with a small hunched rider, birch broom trailing. NO room furniture, NO beds, NO table, NO shelf — only the dark passage, the burst-open door, the soot, and the silhouette." "$DOOR" "$P/yaga_stupa-10.png"

echo "=== FIX ROUND DONE $(date +%H:%M:%S) ==="
ls -la kf11_r2.png kf14_r2.png kf17_r2.png kf18_r2.png 2>/dev/null
