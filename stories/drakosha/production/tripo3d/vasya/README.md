# Вася — 3D model (Tripo3D)

Made 2026-08-19 for pose blocking. **The model is a posing armature for blocking, not a render source** — per the standing rule, clay only has to get the BLOCKING right; the image model fixes anatomy and look afterwards.

| | |
|---|---|
| source image | `source_image_used.png` — cropped from `ep1prod/scene1/references/packet_pages/vasya-04.png` (the locked Вася) |
| task | `image_to_model`, `v2.5-20250123`, texture + pbr, detailed, UV exported |
| task id | `14a9c9a5-74f4-481f-ac68-646a6255e67b` |
| cost | **40 Tripo credits** (balance after: 655) |
| model | `vasya_pbr_model.glb` (12.8 MB) |
| receipt | `vasya_task.json` |

## Blender

`blender -b -noaudio --python production/tools/bl_turnaround.py -- <glb> <outdir>`

The script imports the GLB, centres it on the origin, scales it to 2 units tall standing on the floor plane, lights it three-point and renders front / three-quarter / profile / back. **The model's front faces +X**, so camera angles are 0 / -42 / -90 / 180.

## What the model is good for, and what it is not

Good: silhouette, limb positions, camera angle, eyeline, where the hands are, how big he is against a prop. Everything a blocking pass needs.

Not good: the face. The hair reads as a single mass from behind, the mouth is baked open in his reference smile, and the brows have melted into the fringe. Nothing that survives to the final image — but it means **do not pose him for a shot that lives on his expression** and expect the clay to carry it. The expression comes from the image pass.

The pouch cord is modelled and hangs correctly, which matters, because the cord is how his gift reads on screen.
