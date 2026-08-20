#!/usr/bin/env bash
# Keyframes v2 — jobs 10–14, 17, 18, 19 against the FINAL author room master.
# KF15/16 (roof exterior) stand from v1. Sequential; fixed list = budget cap (8 × ~13cr + retries).
set -uo pipefail
cd "$(dirname "$0")"
R="../../ep1prod/scene1/references"
P="$R/packet_pages"
ROOM="$R/SET-HOME-ROOM-01_author_master_FINAL.png"
DOOR="$R/SET-YAGA-DOOR-01_approved_states.png"
STYLE="Cinematic film still in the exact stylized low-poly 3D render style of the reference images, warm hearth lighting, 16:9. Characters and the set MUST match the reference images exactly. The set is the tiny family's hall inside an old bricked-up fireplace per the room reference: giant boulder-scale red-brown brick courses (each course shoulder-high to an adult character, a single brick as long as four matchbox beds), dark riveted iron plate wall with warm light seeping around its edges, four matchbox beds + knitted-mitten cradle, plank-on-spools banquet table with button stools, shelf and bottle-cap basin, colored garland bulbs overhead, rusty arched iron door low in the left wall, railed floor opening (matchstick posts, twine rope) with the plank descent in the far corner. No windows, no daylight, no modern fixtures."

gen () {
  local n="$1" prompt="$2"; shift 2
  local refargs=()
  for r in "$@"; do refargs+=(--image-references "$r"); done
  echo "=== KF$n start $(date +%H:%M:%S) ==="
  higgsfield generate create nano_banana_pro --prompt "$STYLE $prompt" \
    ${refargs[@]+"${refargs[@]}"} --aspect-ratio 16:9 --resolution 2k \
    --wait --wait-timeout 20m > "kf${n}.url.txt" 2> "kf${n}.err.txt"
  local u; u=$(grep -Eo 'https://[^ ]+\.png' "kf${n}.url.txt" | tail -1)
  [ -n "$u" ] && curl -sL --max-time 120 -o "kf${n}.png" "$u" && echo "KF$n OK"
}

gen 10 "Wide view of the hall from the far corner, matching the room reference exactly. The room is EMPTY of the two older children. МАМА stands midground-right holding the thin baby boy on her arm with the round baby girl on her back; ПАПА stands foreground-left squarely in front of a cloth-covered rounded object the size of a child, trying to hide it behind his body, wood shavings in his hair, a huge grin barely suppressed. The scale law is visible: the brick courses tower over both adults." "$ROOM" "$P/mama-06.png" "$P/babies-13.png" "$P/lineup-02.png"

gen 11 "Inside the hall: the covered present stands center frame near the banquet table — a cloth draped over a rounded object the size of a child — with ПАПА's hands already gripping the cloth, about to pull it away. Фрося and Вася stand to the left watching with wide eyes, мама with both babies behind them. The iron plate wall glows warmly behind." "$ROOM" "$R/R-EP1-TOP-01_approved_author.png" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png"

gen 12 "Side view on the open hall floor between the table and the sleeping wall: the repaired two-seat spinning top from the reference stands mid-floor, cord wound around its neck with the wooden toggle hanging; ФРОСЯ and ВАСЯ are already seated on its two opposite seats gripping their grab-handles, feet tucked in, faces lit with anticipation; ПАПА stands beside it taking hold of the cord's toggle handle with both hands, feet planted wide. Matchbox beds visible behind." "$R/R-EP1-TOP-01_approved_author.png" "$P/frosya-05.png" "$P/vasya-04.png" "$P/lineup-02.png" "$ROOM"

gen 13 "By the banquet table in the hall: МАМА, both babies attached, walks the last steps toward ФРОСЯ holding out a small closed round vintage candy tin tied with a thin ribbon — the exact tin from the reference, closed state. Фрося's eyes are on the tin; the stopped spinning top stands against the brick wall behind them." "$R/D-FRO-ARTBOX-01_approved_tin.png" "$P/mama-06.png" "$P/frosya-05.png" "$ROOM" "$P/babies-13.png"

gen 14 "Close over-shoulder view at the banquet table: ФРОСЯ holds the OPEN round candy tin from the reference — bare colored wax cores lying flat in stitched cloth loops — her finger touching the red core, her face delighted; МАМА's warm face beyond, the babies peeking. Matching the tin reference exactly, open state; warm garland light above." "$R/D-FRO-ARTBOX-01_approved_tin.png" "$P/frosya-05.png" "$P/mama-06.png" "$ROOM"

gen 17 "Inside the hall: the whole family frozen mid-motion staring at the little rusty arched iron door low in the brick wall — the door from the reference, still closed but rattling, a thin wisp of soot puffing from its edges. МАМА clutches both babies, ПАПА is half-risen with his eyebrows high and a grin starting, ФРОСЯ and ВАСЯ stand shoulder to shoulder, wide-eyed. Two empty thimbles on the shelf caught mid-jump." "$ROOM" "$DOOR" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png" "$P/babies-13.png"

gen 18 "Inside a short soot-black passage: at its far end the little arched iron door from the reference has just BURST OPEN toward the hall's warm light and a cloud of black soot rushes toward the camera, filling half the frame; through the soot, the silhouette of the miniature flying mortar with its rider entering." "$DOOR" "$P/yaga_stupa-10.png"

gen 19 "In the warm hall near the now-quiet little iron door: БАБА-ЯГА in her домовой form from the reference — mushroom-red polka-dot kerchief, patched skirt, birch broom in hand, gold tooth glinting — brushes soot from her shoulders and looks around; her miniature mortar and tied bundles rest beside her against the giant brick; the family visible beyond, ФРОСЯ already mid-leap toward her." "$P/yaga_domovoy-07.png" "$ROOM" "$P/frosya-05.png" "$P/lineup-02.png"

echo "=== ALL v2 KEYFRAMES DONE $(date +%H:%M:%S) ==="
ls -la kf*.png 2>/dev/null
