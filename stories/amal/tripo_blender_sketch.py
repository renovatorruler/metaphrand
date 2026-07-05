"""Clean ink line-art ORBIT of a Tripo .glb (Blender Freestyle). Smooths the mesh to kill
micro-speckle, then renders n_views around the subject as black-on-white ink — proving a
stylized look that's consistent from any angle and indifferent to texture/geometry noise.

  blender --background --python tripo_blender_sketch.py -- <glb> <outdir> <stem> [n_views]
"""
import bpy, sys, os, math, mathutils

argv = sys.argv[sys.argv.index("--") + 1:]
glb, outdir = argv[0], argv[1]
stem = argv[2] if len(argv) > 2 else "ink"
n_views = int(argv[3]) if len(argv) > 3 else 4
os.makedirs(outdir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

mn = mathutils.Vector((1e9,) * 3); mx = mathutils.Vector((-1e9,) * 3)
for o in meshes:
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c)
        mn = mathutils.Vector(min(mn[i], w[i]) for i in range(3))
        mx = mathutils.Vector(max(mx[i], w[i]) for i in range(3))
center = (mn + mx) / 2; size = mx - mn; radius = max(size) or 1.0

scn = bpy.context.scene
world = bpy.data.worlds.new("W"); scn.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)

# flat white emission (only the ink reads) + SMOOTH modifier (kills micro-speckle)
mat = bpy.data.materials.new("paper"); mat.use_nodes = True
nt = mat.node_tree; nt.nodes.clear()
em = nt.nodes.new("ShaderNodeEmission"); em.inputs[0].default_value = (1, 1, 1, 1)
mo = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(em.outputs[0], mo.inputs[0])
for o in meshes:
    o.data.materials.clear(); o.data.materials.append(mat)
    for poly in o.data.polygons:
        poly.use_smooth = True
    sm = o.modifiers.new("smooth", "SMOOTH"); sm.factor = 0.5; sm.iterations = 14

cam_d = bpy.data.cameras.new("Cam"); cam_d.lens = 85
cam = bpy.data.objects.new("Cam", cam_d); bpy.context.collection.objects.link(cam); scn.camera = cam

try:
    scn.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    scn.render.engine = "BLENDER_EEVEE"
scn.render.resolution_x, scn.render.resolution_y = 1080, 1350
scn.view_settings.view_transform = "Standard"

scn.render.use_freestyle = True
vl = scn.view_layers[0]; vl.use_freestyle = True
fs = vl.freestyle_settings; fs.crease_angle = math.radians(134)
ls = fs.linesets[0] if fs.linesets else fs.linesets.new("ink")
if ls.linestyle is None:
    ls.linestyle = bpy.data.linestyles.new("ink")
ls.select_silhouette = ls.select_border = ls.select_contour = ls.select_crease = True
ls.linestyle.color = (0, 0, 0); ls.linestyle.thickness = 2.0

dist = radius * 2.7; elev = math.radians(6)
for i in range(n_views):
    az = math.radians(360.0 * i / n_views + 20)
    cam.location = (center.x + dist * math.cos(elev) * math.sin(az),
                    center.y - dist * math.cos(elev) * math.cos(az),
                    center.z + dist * math.sin(elev) + size.z * 0.06)
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    scn.render.filepath = f"{outdir}/{stem}_{int(math.degrees(az)) % 360:03d}.png"
    bpy.ops.render.render(write_still=True)
    print("rendered", scn.render.filepath, flush=True)
print("INK DONE", flush=True)
