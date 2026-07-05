"""Full-Blender bake-off: the screen-turn two-shot with rigged MPFB2 humans.

Builds the pharmacy set, creates two parametric humans (pharmacist + elderly
customer), rigs and poses them at the counter, renders NPR. The frame that
flash kept collaging, staged for real.

    Blender --background --python examples/civilwar_bakeoff.py
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import civilwar_set3d as set3d  # noqa: E402

OUT = "/tmp/blender_bakeoff_raw.png"

bpy.ops.preferences.addon_enable(module="bl_ext.user_default.mpfb")
from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402

print("mpfb ops:", [o for o in dir(bpy.ops.mpfb) if not o.startswith("_")][:40])


def make_human(name, loc, rot_z, age=0.5, gender=0.5, height=0.5, weight=0.5,
               race=None):
    macro = {
        "gender": gender, "age": age, "muscle": 0.45, "weight": weight,
        "proportions": 0.5, "height": height, "cupsize": 0.4, "firmness": 0.5,
        "race": race or {"asian": 0.34, "african": 0.33, "caucasian": 0.33},
    }
    before = set(bpy.data.objects)
    body = HumanService.create_human(macro_detail_dict=macro)
    rig = HumanService.add_builtin_rig(body, "default", import_weights=True)
    root = rig if rig else body
    root.location = loc
    root.rotation_euler[2] = rot_z
    root.name = name
    print(f"{name}: body={body.name} rig={getattr(rig, 'name', None)} "
          f"bones={len(rig.pose.bones) if rig else 0}")
    return root


def pose(arm, spec):
    """Best-effort bone posing: spec maps name-substring -> (x,y,z) radians."""
    if arm.type != "ARMATURE":
        print("no armature to pose for", arm.name)
        return
    names = [b.name for b in arm.pose.bones]
    print("bone sample:", names[:24])
    for key, rot in spec.items():
        hits = [b for b in arm.pose.bones if key.lower() in b.name.lower()]
        for b in hits[:1]:
            b.rotation_mode = "XYZ"
            b.rotation_euler = rot
            print(f"  posed {b.name} <- {key}")


def main():
    set3d.reset()
    set3d.build_pharmacy()

    # Thanh behind the counter (counter runs along y=-6.6; behind = y<-7)
    thanh = make_human("thanh", (-1.2, -7.55, 0), 0.0,
                       age=0.62, gender=1.0, height=0.45, weight=0.45,
                       race={"asian": 1.0, "african": 0.0, "caucasian": 0.0})
    pose(thanh, {
        "upperarm01.R": (math.radians(62), 0, math.radians(-24)),
        "lowerarm01.R": (math.radians(55), 0, math.radians(-8)),
        "wrist.R": (math.radians(15), 0, 0),
        "upperarm01.L": (math.radians(58), 0, math.radians(22)),
        "lowerarm01.L": (math.radians(48), 0, math.radians(8)),
        "wrist.L": (math.radians(15), 0, 0),
        "spine03": (math.radians(12), 0, 0),
        "neck01": (math.radians(10), 0, 0),
    })

    # Mrs. Adeyemi on the customer side, leaning in slightly to read the screen
    adeyemi = make_human("adeyemi", (-1.45, -5.75, 0), math.radians(180),
                         age=0.85, gender=0.0, height=0.38, weight=0.58,
                         race={"asian": 0.0, "african": 1.0, "caucasian": 0.0})
    pose(adeyemi, {
        "spine03": (math.radians(18), 0, 0),
        "spine02": (math.radians(8), 0, 0),
        "neck01": (math.radians(12), 0, 0),
        "upperarm01.R": (math.radians(30), 0, math.radians(-10)),
        "upperarm01.L": (math.radians(30), 0, math.radians(10)),
        "lowerarm01.R": (math.radians(74), 0, 0),
        "lowerarm01.L": (math.radians(74), 0, 0),
    })

    # gray clay for everyone
    mat = bpy.data.materials.new("clay")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.74, 0.71, 0.66, 1)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(mat)

    # a monitor on the counter between them, turned toward her
    mon = set3d.box("counter-monitor", (0.45, 0.34, 0.4), (-1.35, -6.55, 1.27))
    mon.rotation_euler[2] = math.radians(150)
    set3d.box("monitor-foot", (0.2, 0.2, 0.05), (-1.35, -6.55, 1.07))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    try:
        sc.eevee.use_gtao = True
        sc.eevee.gtao_distance = 1.2
    except AttributeError:
        pass
    sc.render.use_freestyle = True
    sc.render.line_thickness = 1.4
    vl = sc.view_layers[0]
    vl.use_freestyle = True
    ls = vl.freestyle_settings.linesets.new("ink")
    style = bpy.data.linestyles.new("ink-style")
    ls.linestyle = style
    style.color = (0.12, 0.11, 0.10)
    style.thickness = 2.8
    world = bpy.data.worlds.new("paper")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.93, 0.90, 0.83, 1)
    sc.world = world
    bpy.ops.object.light_add(type="SUN", location=(4, 4, 7))
    sun = bpy.context.object
    sun.data.energy = 5.0
    sun.rotation_euler = (math.radians(50), math.radians(-15), math.radians(140))
    bpy.ops.object.light_add(type="AREA", location=(-1.4, -6.4, 2.9))
    fill = bpy.context.object
    fill.data.energy = 120
    fill.data.size = 2.0

    from mathutils import Vector
    cam = bpy.data.cameras.new("shot")
    cam.lens = 28
    cam.clip_start = 0.05
    cam.shift_x = 0.1
    ob = bpy.data.objects.new("shot", cam)
    sc.collection.objects.link(ob)
    loc, look = (1.8, -3.6, 1.65), (-1.35, -6.6, 1.3)
    ob.location = loc
    ob.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = ob
    sc.render.resolution_x = 1344
    sc.render.resolution_y = 768
    sc.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("bakeoff raw:", OUT)


main()
