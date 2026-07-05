"""INDIVISIBLE — figure-staged clay: posed MPFB2 humans + horses in the set3d sets.

Fuses the Blender pipeline's two halves:
  - civilwar_set3d  : gray-clay SETS + per-frame SHOTS cameras (geometry)
  - civilwar_bakeoff: MPFB2 parametric humans, rigged + bone-posed (acting)
  - + a CC0 Quaternius horse (stories/civil-war/assets/horse.glb) for mounts

For each frame id in ACTORS it rebuilds that frame's set, places the cast as
posed clay figures (auto-seating a horse under every mounted rider, plus any
riderless horses in HORSES), on that frame's exact camera, and renders Workbench
clay to clay/<fid>.png — overwriting the set-only clay. The pro storyboard pass
then gets character BLOCKING locked in 3D (the floating-figure fix).

    Blender --background --python examples/civilwar_stage3d.py -- \
        c1-standoff,c1-leader-talk stories/civil-war/storyboard/clay
    Blender --background --python examples/civilwar_stage3d.py -- ALL stories/civil-war/storyboard/clay

Facing convention (matches the bake-off): rot_z = 0 faces +Y; pi faces -Y.
Homestead: house at -Y, riders arrive up the track from +Y and face the house
(facing = pi); the family faces the yard (facing = 0).
"""

import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import civilwar_set3d as set3d  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else \
    ["ALL", "stories/civil-war/storyboard/clay"]
WHICH, OUTDIR = ARGS[0], ARGS[1]
HORSE_GLB = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "..", "stories", "civil-war", "assets", "horse.glb")
HORSE_SCALE = 0.25   # 9.235u model -> ~2.3 m long
MOUNT_Z = 0.33       # rider FEET height (MPFB origin is at the feet) -> pelvis ~saddle

bpy.ops.preferences.addon_enable(module="bl_ext.user_default.mpfb")
from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402

D = math.radians
R_AFR = {"asian": 0.0, "african": 1.0, "caucasian": 0.0}

# Build only (gray clay; identity is the portrait sheet's job). The whole ch1
# patrol is Black (inverted-antebellum bounty patrol of freedmen).
CAST = {
    "desmond": dict(age=0.55, gender=1.0, height=0.60, weight=0.52, race=R_AFR),
    "della":   dict(age=0.50, gender=0.0, height=0.46, weight=0.50, race=R_AFR),
    "nia":     dict(age=0.16, gender=0.0, height=0.22, weight=0.42, race=R_AFR),
    "moses":   dict(age=0.55, gender=1.0, height=0.58, weight=0.62, race=R_AFR),  # leader, heavy
    "silas":   dict(age=0.70, gender=1.0, height=0.58, weight=0.48, race=R_AFR),  # old, spare
    "dab":     dict(age=0.45, gender=1.0, height=0.63, weight=0.66, race=R_AFR),  # big rider
    "young":   dict(age=0.26, gender=1.0, height=0.52, weight=0.45, race=R_AFR),  # youngest
}

POSES = {
    "stand":   {},
    "hands_up": {"upperarm01.R": (D(150), 0, D(-20)), "upperarm01.L": (D(150), 0, D(20)),
                 "lowerarm01.R": (D(16), 0, 0), "lowerarm01.L": (D(16), 0, 0)},
    "talk":    {"upperarm01.R": (D(48), 0, D(-34)), "lowerarm01.R": (D(74), 0, 0),
                "spine03": (D(8), 0, 0), "neck01": (D(6), 0, 0)},
    "draw":    {"upperarm01.R": (D(70), 0, D(-6)), "lowerarm01.R": (D(86), 0, 0),
                "spine03": (D(4), 0, 0)},
    "block":   {"upperarm01.R": (D(32), 0, D(-46)), "upperarm01.L": (D(32), 0, D(46)),
                "lowerarm01.R": (D(26), 0, 0), "lowerarm01.L": (D(26), 0, 0)},
    "point":   {"upperarm01.R": (D(96), 0, D(-10)), "lowerarm01.R": (D(8), 0, 0),
                "neck01": (D(4), 0, 0)},
    "cling":   {"upperarm01.R": (D(116), 0, D(-16)), "upperarm01.L": (D(116), 0, D(16)),
                "lowerarm01.R": (D(84), 0, 0), "lowerarm01.L": (D(84), 0, 0),
                "spine03": (D(10), 0, 0)},
    "prone":   {},  # whole-root rotation handles lying down
    # mounted variants splay the legs around the barrel
    "ride":    {"upperleg01.R": (D(62), 0, D(-30)), "upperleg01.L": (D(62), 0, D(30)),
                "lowerleg01.R": (D(-58), 0, 0), "lowerleg01.L": (D(-58), 0, 0),
                "upperarm01.R": (D(40), 0, D(-14)), "lowerarm01.R": (D(58), 0, 0),
                "upperarm01.L": (D(36), 0, D(14)), "lowerarm01.L": (D(52), 0, 0)},
    "ride_talk": {"upperleg01.R": (D(62), 0, D(-30)), "upperleg01.L": (D(62), 0, D(30)),
                  "lowerleg01.R": (D(-58), 0, 0), "lowerleg01.L": (D(-58), 0, 0),
                  "spine03": (D(14), 0, 0), "upperarm01.R": (D(54), 0, D(-26)),
                  "lowerarm01.R": (D(70), 0, 0)},
    "ride_rifle": {"upperleg01.R": (D(62), 0, D(-30)), "upperleg01.L": (D(62), 0, D(30)),
                   "lowerleg01.R": (D(-58), 0, 0), "lowerleg01.L": (D(-58), 0, 0),
                   "upperarm01.R": (D(70), 0, D(-30)), "lowerarm01.R": (D(80), 0, 0),
                   "upperarm01.L": (D(64), 0, D(22)), "lowerarm01.L": (D(70), 0, 0)},
}

CLAY = (0.62, 0.60, 0.57, 1.0)
HORSE_CLAY = (0.50, 0.48, 0.45, 1.0)
_printed = [False]


def import_horse_template():
    """Import the GLB once, strip to the Horse mesh, return a hidden template."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(HORSE_GLB))
    horse = bpy.data.objects.get("Horse")
    for m in list(horse.modifiers):
        if m.type == "ARMATURE":
            horse.modifiers.remove(m)
    for o in bpy.data.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = horse
    horse.select_set(True)
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(set(bpy.data.objects) - before):
        if o is not horse:
            bpy.data.objects.remove(o, do_unlink=True)
    # Re-center the mesh so the SADDLE sits at the object origin: x centered, y
    # ~30% back from the head (native head = +Y), z left alone so feet stay on
    # the ground. Then horse and rider share (x,y) under any rotation — no more
    # rider-at-the-hindquarters.
    xs = [v.co.x for v in horse.data.vertices]
    ys = [v.co.y for v in horse.data.vertices]
    cx = (min(xs) + max(xs)) / 2.0
    saddle_y = max(ys) - 0.23 * (max(ys) - min(ys))  # ~just behind the withers
    for v in horse.data.vertices:
        v.co.x -= cx
        v.co.y -= saddle_y
    horse.name = "_horse_template"
    horse.hide_render = True
    return horse


def place_horse(template, x, y, facing):
    o = template.copy()  # linked duplicate (shares mesh data — cheap)
    bpy.context.collection.objects.link(o)
    o.hide_render = False
    o.scale = (HORSE_SCALE, HORSE_SCALE, HORSE_SCALE)
    o.rotation_euler = (0, 0, facing)  # native nose +Y; facing=pi -> nose toward -Y (house)
    o.location = (x, y, 0.0)
    o.color = HORSE_CLAY
    return o


def make_human(name, char, loc, facing, pose_name):
    macro = {"gender": char["gender"], "age": char["age"], "muscle": 0.5,
             "weight": char["weight"], "proportions": 0.5, "height": char["height"],
             "cupsize": 0.4, "firmness": 0.5, "race": char["race"]}
    body = HumanService.create_human(macro_detail_dict=macro)
    rig = HumanService.add_builtin_rig(body, "default", import_weights=True)
    root = rig if rig else body
    root.location = loc
    # MPFB humans face -Y at rot 0, so add pi to map our facing (0 = +Y) convention
    if pose_name == "prone":
        root.rotation_euler = (D(90), 0, facing + math.pi)   # lying in the dirt
    else:
        root.rotation_euler = (0, 0, facing + math.pi)
    root.name = name
    for o in (body, *body.children):
        if o.type == "MESH":
            o.color = CLAY
    if not _printed[0] and rig:
        print("BONES OK")
        _printed[0] = True
    if rig:
        for key, rot in POSES.get(pose_name, {}).items():
            for b in [pb for pb in rig.pose.bones if key.lower() in pb.name.lower()][:1]:
                b.rotation_mode = "XYZ"
                b.rotation_euler = rot
    return root


# actor = (character, (x, y), facing, pose, mounted)   z is implicit
# (ground for on-foot, MOUNT_Z for mounted). HORSES holds riderless mounts.
M, F0 = True, 0.0
P = math.pi
ACTORS = {
    "c1-riders-come": [
        ("moses", (1.4, 1.0), P, "ride", M), ("dab", (3.0, 3.4), P, "ride_rifle", M),
        ("young", (-0.4, 4.2), P, "ride", M), ("silas", (2.2, 6.2), P, "ride", M),
    ],
    "c1-leader": [("moses", (2.8, -7.0), P, "ride_talk", M)],
    "c1-standoff": [
        ("moses", (1.4, -6.4), P, "ride_talk", M), ("dab", (3.2, -5.0), P, "ride_rifle", M),
        ("young", (-0.2, -4.0), P, "ride", M), ("silas", (2.6, 0.4), P, "ride", M),
        ("desmond", (-0.4, -9.0), F0, "stand", False),
    ],
    "c1-leader-talk": [
        ("moses", (3.0, -6.4), P, "ride_talk", M), ("desmond", (0.6, -8.9), F0, "stand", False),
    ],
    "c1-three-watch": [
        ("dab", (3.2, -5.0), P, "ride_rifle", M), ("young", (1.4, -3.4), P, "ride", M),
        ("silas", (2.6, 0.6), P, "ride", M),
    ],
    "c1-dismount": [("dab", (1.7, -7.6), P, "stand", False)],   # on foot beside the horse
    "c1-block": [
        ("desmond", (0.2, -9.4), F0, "block", False), ("dab", (0.7, -8.0), P, "stand", False),
    ],
    "c1-glance-back": [("dab", (1.4, -7.2), F0, "stand", False),
                       ("moses", (2.6, -4.2), P, "ride_talk", M)],
    "c1-mount-up": [("dab", (1.9, -6.7), P, "stand", False)],
    "c1-turning": [
        ("moses", (1.0, -6.0), F0, "ride", M), ("dab", (2.6, -5.0), D(40), "ride", M),
        ("young", (0.0, -4.0), D(-30), "ride", M), ("silas", (2.4, -1.0), F0, "ride", M),
    ],
    "c1-young-still": [("young", (-2.6, -5.2), D(250), "point", M)],   # half-turned to lean-to
    "c1-young-point": [("young", (-2.2, -5.6), D(250), "point", M)],
    "c1-hands-show": [
        ("desmond", (0.5, -8.0), F0, "hands_up", False),
        ("della", (-0.7, -10.6), F0, "stand", False),
        ("nia", (-1.7, -10.4), F0, "cling", False),
    ],
    "c1-pistol-up": [("desmond", (0.0, -8.6), F0, "draw", False)],
    "c1-yard-chaos": [
        ("dab", (2.6, -5.6), D(60), "ride_rifle", M), ("young", (0.6, -4.4), D(-50), "ride", M),
        ("moses", (1.6, -6.8), D(150), "ride", M),
    ],
    "c1-down": [("dab", (-1.4, -6.6), D(20), "prone", False)],
}

# riderless horses (x, y, facing); mounts are auto-placed under mounted actors.
HORSES = {
    "c1-dismount": [(2.0, -7.4, P)],     # the horse he just stepped off
    "c1-block":    [(1.0, -7.6, P)],
    "c1-mount-up": [(2.2, -6.5, P)],
    "c1-down":     [(-2.6, -7.4, D(40))],  # standing off, riderless
    "c1-bay":      [(-9.1, -12.0, D(-70))],  # the tied bay at the lean-to (the tell)
}


def frame_to_set():
    rev = {}
    for setname, shots in set3d.SHOTS.items():
        for fid in shots:
            rev[fid] = setname
    return rev


def render_frame(fid, setname):
    set3d.reset()
    set3d.BUILDERS[setname]()
    # the homestead set ships a crude bay-horse proxy at the lean-to; drop it on
    # the shot that features the bay (we place the real horse there instead).
    if fid == "c1-bay":
        for o in [o for o in bpy.data.objects if o.name.startswith("bay-")]:
            bpy.data.objects.remove(o, do_unlink=True)
    need_horse = bool(HORSES.get(fid)) or any(a[4] for a in ACTORS.get(fid, []))
    template = import_horse_template() if need_horse else None
    for (x, y, facing) in HORSES.get(fid, []):
        place_horse(template, x, y, facing)
    for (cname, (x, y), facing, pose, mounted) in ACTORS.get(fid, []):
        if mounted:
            place_horse(template, x, y, facing)
            make_human(cname, CAST[cname], (x, y, MOUNT_Z), facing, pose)
        else:
            make_human(cname, CAST[cname], (x, y, 0.0), facing, pose)

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "OBJECT"
    sc.display.shading.show_shadows = True
    sc.display.shading.show_cavity = True
    sc.display.shading.cavity_type = "BOTH"
    world = bpy.data.worlds.new("w")
    world.color = (0.18, 0.18, 0.18)
    sc.world = world
    sc.render.resolution_x = 1376
    sc.render.resolution_y = 768
    sc.render.image_settings.file_format = "PNG"
    os.makedirs(OUTDIR, exist_ok=True)

    spec = set3d.SHOTS[setname][fid]
    loc, look, lens = spec[0], spec[1], spec[2]
    cam = bpy.data.cameras.new(fid)
    cam.lens = lens
    cam.clip_start = 0.02
    cam.shift_x = spec[3] if len(spec) > 3 else 0.0
    cam.shift_y = spec[4] if len(spec) > 4 else 0.0
    ob = bpy.data.objects.new(fid, cam)
    bpy.context.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = ob
    sc.render.filepath = os.path.join(OUTDIR, f"{fid}.png")
    bpy.ops.render.render(write_still=True)
    print("staged clay:", sc.render.filepath)


def main():
    rev = frame_to_set()
    fids = sorted(set(ACTORS) | set(HORSES)) if WHICH == "ALL" else WHICH.split(",")
    for fid in fids:
        if fid not in rev:
            print("no camera in set3d.SHOTS for", fid); continue
        render_frame(fid, rev[fid])


main()
