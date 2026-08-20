#!/usr/bin/env bash
# Keyframe stills for jobs 10–19 — one approved-reference-stacked opening frame per job.
# Sequential; fixed list = budget cap (10 × 2cr + retries).
set -uo pipefail
cd "$(dirname "$0")"
R="../../ep1prod/scene1/references"
P="$R/packet_pages"
STYLE="Cinematic film still in the exact stylized low-poly 3D render style of the reference images, warm hearth lighting, 16:9. Characters and sets MUST match the reference images exactly."

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

gen 10 "Wide view of the tiny house-spirits' main room behind the stove from the far corner, matching the room reference exactly: fireplace at right, string lights, spool table center, herringbone floorboards. The room is EMPTY of the two older children. МАМА stands midground-right holding the thin baby boy on her arm with the round baby girl on her back; ПАПА stands foreground-left squarely in front of a cloth-covered rounded object the size of a child, trying to hide it behind his body, wood shavings in his hair, a huge grin barely suppressed." "$R/SET-HOME-ROOM-01_approved_plate.jpg" "$P/mama-06.png" "$P/babies-13.png" "$P/lineup-02.png"

gen 11 "Inside the warm main room: the covered present stands center frame — a cloth draped over a rounded object the size of a child — with ПАПА's hands already gripping the cloth, about to pull it away. Фрося and Вася stand to the left watching with wide eyes, мама with both babies behind them. Matching all references exactly." "$R/SET-HOME-ROOM-01_approved_plate.jpg" "$R/R-EP1-TOP-01_approved_author.png" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png"

gen 12 "Side view in the main room: the repaired two-seat spinning top from the reference stands mid-floor, cord wound around its neck with the wooden toggle hanging; ФРОСЯ and ВАСЯ are already seated on its two opposite seats gripping their grab-handles, feet tucked in, faces lit with anticipation; ПАПА stands beside it taking hold of the cord's toggle handle with both hands, feet planted wide." "$R/R-EP1-TOP-01_approved_author.png" "$P/frosya-05.png" "$P/vasya-04.png" "$P/lineup-02.png" "$R/SET-HOME-ROOM-01_approved_plate.jpg"

gen 13 "By the spool table in the main room: МАМА, both babies attached, walks the last steps toward ФРОСЯ holding out a small closed round vintage candy tin tied with a thin ribbon — the exact tin from the reference, closed state. Фрося's eyes are on the tin; the stopped spinning top stands against the far wall behind them." "$R/D-FRO-ARTBOX-01_approved_tin.png" "$P/mama-06.png" "$P/frosya-05.png" "$R/SET-HOME-ROOM-01_approved_plate.jpg" "$P/babies-13.png"

gen 14 "Close over-shoulder view at the spool table: ФРОСЯ holds the OPEN round candy tin from the reference — bare colored wax cores lying flat in stitched cloth loops — her finger touching the red core, her face delighted; МАМА's warm face beyond, the babies peeking. Matching the tin reference exactly, open state." "$R/D-FRO-ARTBOX-01_approved_tin.png" "$P/frosya-05.png" "$P/mama-06.png"

gen 15 "Distant exterior view matching the roof reference plate: the human house's roof and brick chimney under a morning sky, and approaching from screen-left through the air, БАБА-ЯГА standing in her flying wooden mortar exactly as in the mortar reference — pestle across the rim, birch broom steering behind, cloth bundles lashed to the sides, her skirt and headscarf streaming." "$R/SET-ROOF-01_approved_plate.jpg" "$P/yaga_stupa-10.png" "$P/yaga_flight-08.png"

gen 16 "Close view of БАБА-ЯГА in her hovering mortar directly above the brick chimney, matching her flight-form reference exactly: she plants her feet wide, grips the mortar rim with both hands, mouth open mid-command, fierce joy on her face; the chimney opening directly below, the roof falling away beneath." "$P/yaga_stupa-10.png" "$P/yaga_flight-08.png" "$R/SET-ROOF-01_approved_plate.jpg"

gen 17 "Inside the main room: the whole family frozen mid-motion staring at a dark seam in the plaster wall beside the stove — МАМА clutching both babies, ПАПА half-risen with his eyebrows high and a grin starting, ФРОСЯ and ВАСЯ shoulder to shoulder, wide-eyed. Two empty thimbles on a nearby shelf caught mid-jump. Matching all character references exactly." "$R/SET-HOME-ROOM-01_approved_plate.jpg" "$P/frosya-05.png" "$P/vasya-04.png" "$P/mama-06.png" "$P/babies-13.png"

gen 18 "Inside a short soot-black passage matching the hatch reference plate: the metal cleanout hatch at the far end has just burst open and a cloud of black soot rushes toward the camera, filling half the frame; through the soot, the glow of the miniature mortar's silhouette entering." "$R/SET-STOVE-HATCH-01_approved_plate.jpg" "$P/yaga_stupa-10.png"

gen 19 "In the warm main room near the now-closed plaster seam: БАБА-ЯГА in her домовой form from the reference — mushroom-red polka-dot kerchief, patched skirt, birch broom in hand, gold tooth glinting — brushes soot from her shoulders and looks around the room; her miniature mortar and tied bundles rest beside her; the family visible beyond, ФРОСЯ already mid-leap toward her." "$P/yaga_domovoy-07.png" "$R/SET-HOME-ROOM-01_approved_plate.jpg" "$P/frosya-05.png" "$P/lineup-02.png"

echo "=== ALL KEYFRAMES DONE $(date +%H:%M:%S) ==="
ls -la kf*.png 2>/dev/null
