"""Render NEW camera angles of a Tripo .glb in Blender (headless).

  blender --background --python tripo_blender_render.py -- <model.glb> <outdir> <stem> [n_views]

Imports the textured mesh, frames it, lights it 3-point, and renders n_views
orbiting shots -> <outdir>/<stem>_<az>.png  (the payoff: shots we never filmed).
"""
import bpy, sys, os, math, mathutils

argv = sys.argv[sys.argv.index("--") + 1:]
glb, outdir = argv[0], argv[1]
stem = argv[2] if len(argv) > 2 else "shot"
n_views = int(argv[3]) if len(argv) > 3 else 4
os.makedirs(outdir, exist_ok=True)

# empty scene, import the glb
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

# world-space bounding box -> center + radius (for framing & light/cam distances)
mn = mathutils.Vector((1e9,) * 3); mx = mathutils.Vector((-1e9,) * 3)
for o in meshes:
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c)
        mn = mathutils.Vector(min(mn[i], w[i]) for i in range(3))
        mx = mathutils.Vector(max(mx[i], w[i]) for i in range(3))
center = (mn + mx) / 2
size = mx - mn
radius = max(size) or 1.0

scn = bpy.context.scene

# soft dark world
world = bpy.data.worlds.new("W"); scn.world = world; world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs[0].default_value = (0.04, 0.04, 0.05, 1); bg.inputs[1].default_value = 0.5

def light(name, loc, energy):
    l = bpy.data.lights.new(name, "AREA"); l.energy = energy; l.size = radius * 2
    o = bpy.data.objects.new(name, l); o.location = loc
    bpy.context.collection.objects.link(o)
    o.rotation_euler = (center - mathutils.Vector(loc)).to_track_quat("-Z", "Y").to_euler()

R = radius * 2.4
light("key", (center.x + R, center.y - R, center.z + R), radius**2 * 1200)
light("fill", (center.x - R, center.y - R * 0.6, center.z + R * 0.4), radius**2 * 400)
light("rim", (center.x, center.y + R, center.z + R * 1.3), radius**2 * 800)

# camera
cam_d = bpy.data.cameras.new("Cam"); cam_d.lens = 85
cam = bpy.data.objects.new("Cam", cam_d); bpy.context.collection.objects.link(cam)
scn.camera = cam

# render engine (EEVEE Next on 4.2+, else legacy EEVEE)
try:
    scn.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    scn.render.engine = "BLENDER_EEVEE"
scn.render.resolution_x, scn.render.resolution_y = 1080, 1350
scn.view_settings.view_transform = "Standard"

dist = radius * 2.7
elev = math.radians(6)
for i in range(n_views):
    az = math.radians(360.0 * i / n_views + 20)
    cam.location = (center.x + dist * math.cos(elev) * math.sin(az),
                    center.y - dist * math.cos(elev) * math.cos(az),
                    center.z + dist * math.sin(elev) + size.z * 0.06)
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    scn.render.filepath = f"{outdir}/{stem}_{int(math.degrees(az)) % 360:03d}.png"
    bpy.ops.render.render(write_still=True)
    print("rendered", scn.render.filepath, flush=True)
print("BLENDER DONE", flush=True)
