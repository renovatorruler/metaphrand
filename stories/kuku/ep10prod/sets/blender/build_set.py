# build_set.py — construct an EP10 set in Blender from the engine's scene JSON.
#
# The geometry is NOT authored here: every dimension and landmark position comes
# from studio/src/Kuku_Ep10Sets.res via KukuEp10_Blender.res. This file only
# knows how to turn that data into meshes and cameras. Blender's API is
# Python-only, the same exception the Defold runtime carries; ReScript still
# owns the set data.
#
# Usage (from the repo, any cwd):
#   blender --background --python build_set.py -- <scene.json> <outdir> [cam_tag ...]
# With no cam tags it renders every camera in the scene file.

import bpy, json, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
scene_path = argv[0]
outdir = argv[1] if len(argv) > 1 else os.path.dirname(scene_path)
want = set(argv[2:])
os.makedirs(outdir, exist_ok=True)
D = json.load(open(scene_path))

LEN, WID, DROP = D["lane_length_m"], D["lane_width_m"], D["lane_drop_m"]
FLAT_AT = next(l["pos"][1] for l in D["landmarks"] if l["name"] == "FLAT BEGINS")


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, rgb, rough=0.9):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    return m


def box(name, size, loc, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.data.materials.append(material)
    return o


def ground_z(y):
    """Height of the lane surface at distance y — the slope is data, not a guess."""
    if y <= 0:
        return DROP
    if y >= FLAT_AT:
        return 0.0
    return DROP * (1.0 - y / FLAT_AT)


clear()
stone = mat("stone", (0.86, 0.80, 0.68))
kerb = mat("kerb", (0.78, 0.72, 0.60))
red = mat("marker_red", (0.62, 0.14, 0.11), rough=0.7)
grass = mat("verge", (0.55, 0.60, 0.36))

# --- the lane surface: one quad strip per metre, following the slope ---------
verts, faces = [], []
step = 1.0
n = int(LEN / step) + 1
for i in range(n):
    y = i * step
    z = ground_z(y)
    verts.append((-WID / 2, y, z))
    verts.append((WID / 2, y, z))
    if i:
        a = 2 * (i - 1)
        faces.append((a, a + 1, a + 3, a + 2))
me = bpy.data.meshes.new("lane_surface")
me.from_pydata(verts, [], faces)
me.update()
lane = bpy.data.objects.new("lane_surface", me)
bpy.context.collection.objects.link(lane)
lane.data.materials.append(stone)

# --- kerbs down both sides, following the same slope ------------------------
for side, sx in (("L", -1), ("R", 1)):
    kv, kf = [], []
    for i in range(n):
        y = i * step
        z = ground_z(y)
        x0 = sx * (WID / 2)
        x1 = sx * (WID / 2 + 0.6)
        kv += [(x0, y, z), (x1, y, z), (x0, y, z + 0.5), (x1, y, z + 0.5)]
        if i:
            b = 4 * (i - 1)
            kf += [(b + 2, b + 3, b + 7, b + 6), (b + 0, b + 2, b + 6, b + 4)]
    km = bpy.data.meshes.new(f"kerb_{side}")
    km.from_pydata(kv, [], kf)
    km.update()
    ko = bpy.data.objects.new(f"kerb_{side}", km)
    bpy.context.collection.objects.link(ko)
    ko.data.materials.append(kerb)

# --- the hillside the lane is cut INTO --------------------------------------
# The terrain follows the lane's own fall and drops away to either side, so the
# lane reads as a cut in a slope rather than a causeway standing above a plain.
tv, tf = [], []
COLS = [-140.0, -34.0, -(WID / 2 + 0.6), (WID / 2 + 0.6), 34.0, 140.0]
SIDE_DROP = {-140.0: -2.4, -34.0: -0.6, -(WID / 2 + 0.6): -0.3,
             (WID / 2 + 0.6): -0.3, 34.0: -0.6, 140.0: -2.4}
rows = range(-40, int(LEN) + 60, 4)
for ri, y in enumerate(rows):
    base = ground_z(min(max(y, 0.0), LEN))
    for x in COLS:
        tv.append((x, float(y), base + SIDE_DROP[x]))
    if ri:
        a = len(COLS) * (ri - 1)
        b = len(COLS) * ri
        for ci in range(len(COLS) - 1):
            tf.append((a + ci, a + ci + 1, b + ci + 1, b + ci))
tm = bpy.data.meshes.new("landscape")
tm.from_pydata(tv, [], tf)
tm.update()
to = bpy.data.objects.new("landscape", tm)
bpy.context.collection.objects.link(to)
to.data.materials.append(grass)

# --- landmarks, each placed from the data -----------------------------------
for l in D["landmarks"]:
    x, y, z = l["pos"]
    nm = l["name"]
    if nm == "STONE POST":
        box("stone_post", (0.9, 0.9, 2.4), (x, y, ground_z(y) + 1.2), kerb)
    elif nm.startswith("MARKER"):
        box(nm.replace(" ", "_"), (0.55, 0.18, 0.75), (x, y, ground_z(y) + 0.37), red)
    elif nm == "END WALL":
        box("end_wall", (WID + 1.4, 0.8, 3.0), (0, LEN, 1.5), kerb)
    elif nm == "GA-STONE":
        # the flat paving slab the ga-shape is later forged ON (not the shape)
        box("ga_slab", (3.0, 3.0, 0.12), (x, y, 0.06), stone)

# --- light: the last golden evening, low and from the far end ---------------
bpy.ops.object.light_add(type="SUN", location=(6, LEN + 40, 14))
sun = bpy.context.object
sun.data.energy = 6.5
sun.data.angle = math.radians(3)
sun.rotation_euler = (math.radians(66), 0, math.radians(196))
world = bpy.data.worlds.new("W")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.47, 0.62, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.1

# --- render every requested camera ------------------------------------------
sc = bpy.context.scene
engines = {i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
sc.render.engine = next(e for e in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH") if e in engines)
sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
sc.render.film_transparent = False

made = []
for c in D["cameras"]:
    if want and c["tag"] not in want:
        continue
    bpy.ops.object.camera_add(location=Vector(c["pos"]))
    cam = bpy.context.object
    cam.data.lens = c["lens_mm"]
    d = Vector(c["aim"]) - Vector(c["pos"])
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    path = os.path.join(outdir, f"{D['set']}_{c['tag']}_blockout.png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    made.append(path)
    bpy.data.objects.remove(cam, do_unlink=True)

print("BLOCKOUTS: " + " ".join(made))
