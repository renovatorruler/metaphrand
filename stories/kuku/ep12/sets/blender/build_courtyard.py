# build_courtyard.py — build the «द से दीया» courtyard in Blender from scene JSON.
#
# No geometry is authored here. Every dimension comes from
# studio/src/KukuEp12_Blender.res. This file only turns that data into meshes,
# lights and cameras. Blender's API is Python-only — the same exception the
# Defold runtime carries; ReScript still owns the set.
#
#   blender --background --python build_courtyard.py -- <scene.json> <outdir> [shot ...]
#
# CONVENTION, learned the hard way on EP10: the courtyard floor is z = 0, and
# every camera z in the scene file is METRES ABOVE IT — position and aim both.

import bpy, json, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
scene_path, outdir = argv[0], argv[1]
want = set(argv[2:])
os.makedirs(outdir, exist_ok=True)
D = json.load(open(scene_path))

FLOOR = D["floor_size_m"]
WALL_Y, WALL_H = D["wall_y_m"], D["wall_h_m"]
NICHE_H = D["niche_h_m"]
DOOR_Y = D["door_y_m"]
DX, DY, DZ = D["diya"]


def mat(name, rgb, rough=0.9, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (1.0, 0.72, 0.34, 1)
        b.inputs["Emission Strength"].default_value = emit
    return m


def box(name, size, loc, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.data.materials.append(material)
    return o


def build_set():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    stone = mat("stone", (0.82, 0.76, 0.66))
    warmstone = mat("warmstone", (0.78, 0.70, 0.58))
    grass = mat("grass", (0.42, 0.55, 0.34))
    wood = mat("wood", (0.45, 0.32, 0.21))
    brass = mat("brass", (0.72, 0.55, 0.24), rough=0.35)
    flame_m = mat("flame", (1.0, 0.78, 0.36), rough=0.2, emit=6.0)

    # the paper flagstone floor
    box("floor", (FLOOR, FLOOR, 0.06), (0, 0, -0.03), stone)
    # the valley ground beyond the wall, dropping away
    box("valley", (60, 34, 0.05), (0, WALL_Y + 18.0, -3.0), grass)
    # far hills, so there is depth beyond the wall instead of a flat green slab
    for i, (hx, hy, hw, hh) in enumerate([(-13, 24, 20, 3.5), (3, 29, 24, 5.0), (17, 23, 16, 2.8)]):
        box("hill%d" % i, (hw, 10, hh), (hx, hy, -3.0 + hh / 2), grass)

    # the low valley wall, built as two piers and a lintel so the NICHE is a real
    # hole in the geometry rather than a painted rectangle
    nw, nh = 0.46, 0.34           # niche opening
    seg = (FLOOR - nw) / 2
    box("wall_l", (seg, 0.3, WALL_H), (-(nw / 2 + seg / 2), WALL_Y, WALL_H / 2), warmstone)
    box("wall_r", (seg, 0.3, WALL_H), (+(nw / 2 + seg / 2), WALL_Y, WALL_H / 2), warmstone)
    box("wall_under", (nw, 0.3, NICHE_H), (0, WALL_Y, NICHE_H / 2), warmstone)
    box("wall_over", (nw, 0.3, WALL_H - NICHE_H - nh),
        (0, WALL_Y, NICHE_H + nh + (WALL_H - NICHE_H - nh) / 2), warmstone)
    box("niche_back", (nw, 0.06, nh), (0, WALL_Y + 0.12, NICHE_H + nh / 2), warmstone)
    box("wall_coping", (FLOOR, 0.40, 0.09), (0, WALL_Y, WALL_H + 0.045), stone)

    # दादी's doorway
    box("door_wall", (FLOOR, 0.3, 2.4), (0, DOOR_Y, 1.2), warmstone)
    box("door_gap", (1.0, 0.34, 1.9), (0, DOOR_Y, 0.95), wood)

    # the दीया itself: a small brass dish and its flame
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.05, location=(DX, DY, DZ + 0.025))
    bpy.context.object.name = "diya_dish"
    bpy.context.object.data.materials.append(brass)
    bpy.ops.mesh.primitive_cone_add(radius1=0.018, depth=0.062, location=(DX, DY, DZ + 0.078))
    bpy.context.object.name = "flame"
    bpy.context.object.data.materials.append(flame_m)

    # the flame is a real light — it is the key light of the whole episode
    l = bpy.data.lights.new("flame_light", type="POINT")
    l.energy, l.color, l.shadow_soft_size = 22.0, (1.0, 0.66, 0.30), 0.04
    o = bpy.data.objects.new("flame_light", l)
    o.location = (DX, DY, DZ + 0.10)
    bpy.context.collection.objects.link(o)
    return {"stone": stone, "wood": wood}


def build_actors(cast):
    """Coloured proxies. Tagged is_actor so a later shot can clear only these and
    leave the set standing — the EP10 tableau leak came from rebuilding blind."""
    for a in cast:
        x, y, _ = a["pos"]
        h = a["height"]
        m = mat("m_" + a["who"], tuple(a["rgb"]))
        if a["pose"] == "curled":
            bpy.ops.mesh.primitive_uv_sphere_add(radius=h, location=(x, y, h * 0.7))
            o = bpy.context.object
            o.scale = (1.5, 1.0, 0.7)
        else:
            sit = a["pose"] in ("sit", "kneel")
            body_h = h * (0.62 if sit else 1.0)
            o = box("a_" + a["who"], (h * 0.5, h * 0.42, body_h), (x, y, body_h / 2), m)
            # a head, so the aim height reads and framing can be judged
            bpy.ops.mesh.primitive_uv_sphere_add(radius=h * 0.15,
                                                 location=(x, y, body_h + h * 0.13))
            head = bpy.context.object
            head.data.materials.append(m)
            head.name = "h_" + a["who"]
            head["is_actor"] = True
        o.name = "a_" + a["who"]
        o.data.materials.append(m) if not o.data.materials else None
        o["is_actor"] = True
        o.rotation_euler = (0, 0, math.radians(a["facing"]))


def clear_actors():
    for o in [x for x in bpy.data.objects if x.get("is_actor")]:
        bpy.data.objects.remove(o, do_unlink=True)


def set_light(state):
    for o in [x for x in bpy.data.objects if x.name.startswith("sky_")]:
        bpy.data.objects.remove(o, do_unlink=True)
    w = bpy.context.scene.world
    if not w:
        w = bpy.data.worlds.new("W"); bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    if state == "dusk":
        bg.inputs[0].default_value = (0.42, 0.34, 0.30, 1)
        bg.inputs[1].default_value = 0.55
        l = bpy.data.lights.new("sky_sun", type="SUN")
        l.energy, l.color, l.angle = 2.4, (1.0, 0.72, 0.45), 0.12
        o = bpy.data.objects.new("sky_sun", l)
        o.location = (-7, 9, 3.2)
        o.rotation_euler = (math.radians(72), 0, math.radians(-140))
        bpy.context.collection.objects.link(o)
    else:  # night — the lamp is the only real light
        bg.inputs[0].default_value = (0.07, 0.10, 0.17, 1)
        bg.inputs[1].default_value = 0.42
        l = bpy.data.lights.new("sky_moon", type="SUN")
        l.energy, l.color = 0.85, (0.62, 0.72, 1.0)
        o = bpy.data.objects.new("sky_moon", l)
        o.rotation_euler = (math.radians(38), 0, math.radians(30))
        bpy.context.collection.objects.link(o)


def place_cam(c):
    for o in [x for x in bpy.data.objects if x.type == "CAMERA"]:
        bpy.data.objects.remove(o, do_unlink=True)
    cd = bpy.data.cameras.new("cam")
    cd.lens = c["lens"]
    o = bpy.data.objects.new("cam", cd)
    o.location = Vector(c["pos"])                      # z is metres above the floor
    d = Vector(c["aim"]) - o.location                  # aim likewise
    o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.collection.objects.link(o)
    bpy.context.scene.camera = o


def render(path):
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE"
    s.render.resolution_x, s.render.resolution_y = 960, 540
    s.render.filepath = path
    s.render.image_settings.file_format = "PNG"
    s.view_settings.view_transform = "AgX"
    bpy.ops.render.render(write_still=True)


build_set()
CAMS = {c["tag"]: c for c in D["cams"]}
done = 0
for sh in D["shots"]:
    if want and sh["id"] not in want:
        continue
    clear_actors()
    build_actors(sh["cast"])
    set_light(sh["light"])
    place_cam(CAMS[sh["cam"]])
    render(os.path.join(outdir, sh["id"] + ".png"))
    done += 1
    print("rendered", sh["id"], "cam=" + sh["cam"], sh["light"])
print("BLOCKOUTS COMPLETE", done)
