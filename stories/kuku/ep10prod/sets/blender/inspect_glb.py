# Import a generated GLB, report its real dimensions, and render turntable views.
import bpy, sys, os, math
from mathutils import Vector
argv = sys.argv[sys.argv.index("--")+1:]
glb, outdir, tag = argv[0], argv[1], argv[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
tris = sum(len(o.data.loop_triangles) for o in objs if (o.data.calc_loop_triangles() or True))
mn = Vector((1e9,)*3); mx = Vector((-1e9,)*3)
for o in objs:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        mn = Vector((min(mn[i], w[i]) for i in range(3)))
        mx = Vector((max(mx[i], w[i]) for i in range(3)))
size = mx - mn; ctr = (mx + mn) / 2
print(f"MESHES={len(objs)} TRIS={tris} SIZE={tuple(round(v,2) for v in size)}")
# light + sky
w = bpy.data.worlds.new("W"); bpy.context.scene.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.5,0.55,0.68,1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.6
bpy.ops.object.light_add(type="SUN", location=(ctr.x+size.x, ctr.y-size.y, ctr.z+size.z*2))
bpy.context.object.data.energy = 4
sc = bpy.context.scene
engines = {i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
sc.render.engine = next(e for e in ("BLENDER_EEVEE_NEXT","BLENDER_EEVEE","BLENDER_WORKBENCH") if e in engines)
sc.render.resolution_x, sc.render.resolution_y = 960, 540
r = max(size) * 1.5
for i, (ang, elev) in enumerate([(0, 25), (60, 25), (140, 20), (90, 70)]):
    a = math.radians(ang); e = math.radians(elev)
    pos = ctr + Vector((math.cos(a)*math.cos(e), math.sin(a)*math.cos(e), math.sin(e))) * r
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.object; cam.data.lens = 40
    cam.rotation_euler = (ctr - pos).to_track_quat("-Z","Y").to_euler()
    sc.camera = cam
    sc.render.filepath = os.path.join(outdir, f"{tag}_view{i}.png")
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
print("OK")
