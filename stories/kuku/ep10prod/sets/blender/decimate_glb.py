# Decimate a generated GLB to a workable size and re-export.
import bpy, sys, os
argv = sys.argv[sys.argv.index("--")+1:]
src, dst, ratio = argv[0], argv[1], float(argv[2])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("dec", "DECIMATE"); m.ratio = ratio
    bpy.ops.object.modifier_apply(modifier="dec")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB")
print("EXPORTED", dst)
