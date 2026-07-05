"""Render a moving-camera animatic of a clay set.

Shows the DETERMINISTIC layer of the video pipeline in motion — real 3D space,
real parallax, zero flicker — which is the half you can only judge by watching
it move. The generative pass (rented GPU) replaces the gray surfaces with the
house style; it does NOT touch camera, timing, or geometry, which are locked
here. This is previs/animatic quality: film-grade motion, placeholder skin.

    Blender --background --python examples/civilwar_animatic.py -- homestead /tmp/animatic
"""

import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import civilwar_set3d as set3d  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["homestead", "/tmp/animatic"]
SET, OUTDIR = ARGS[0], ARGS[1]

# (frame, camera_location) — a crane down the track onto the yard, foreground
# parallax off the woodpile and well selling the real 3D space.
MOVES = {
    "homestead": (30, (0, -11, 1.4), {1: (30, 44, 13), 60: (15, 8, 4.5), 120: (7.5, 1.5, 1.9)}),
    "hangar":    (28, (-2, -9, 1.3), {1: (10.5, 2.5, 2.4), 60: (6.5, -3.5, 1.7), 120: (2.5, -4.2, 1.3)}),
}


def main():
    set3d.reset()
    set3d.BUILDERS[SET]()
    lens, look, keys = MOVES[SET]

    bpy.ops.object.empty_add(location=look)
    target = bpy.context.object

    cd = bpy.data.cameras.new("animcam")
    cd.lens = lens
    cd.clip_start = 0.05
    cam = bpy.data.objects.new("animcam", cd)
    bpy.context.scene.collection.objects.link(cam)
    con = cam.constraints.new("TRACK_TO")
    con.target = target
    con.track_axis = "TRACK_NEGATIVE_Z"
    con.up_axis = "UP_Y"

    sc = bpy.context.scene
    sc.camera = cam
    for f, loc in keys.items():
        cam.location = loc
        cam.keyframe_insert("location", frame=f)
    sc.frame_start = 1
    sc.frame_end = max(keys)
    sc.render.fps = 24

    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "OBJECT"
    sc.display.shading.show_shadows = True
    sc.display.shading.show_cavity = True
    sc.display.shading.cavity_type = "BOTH"
    w = bpy.data.worlds.new("w")
    w.color = (0.16, 0.16, 0.18)
    sc.world = w
    sc.render.resolution_x = 1024
    sc.render.resolution_y = 576
    sc.render.image_settings.file_format = "PNG"
    os.makedirs(OUTDIR, exist_ok=True)
    sc.render.filepath = os.path.join(OUTDIR, "f_")
    bpy.ops.render.render(animation=True)
    print("animatic frames ->", OUTDIR)


main()
