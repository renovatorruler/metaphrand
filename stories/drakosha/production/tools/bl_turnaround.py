import bpy, math, sys, os
argv=sys.argv[sys.argv.index('--')+1:]
GLB, OUT = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)

objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
# normalise: centre on origin, scale so height = 2
import mathutils
mn=mathutils.Vector((1e9,)*3); mx=mathutils.Vector((-1e9,)*3)
for o in objs:
    for c in o.bound_box:
        w=o.matrix_world @ mathutils.Vector(c)
        for i in range(3):
            mn[i]=min(mn[i],w[i]); mx[i]=max(mx[i],w[i])
size=mx-mn; centre=(mn+mx)/2
s=2.0/max(size.z,1e-6)
root=bpy.data.objects.new("ROOT",None); bpy.context.scene.collection.objects.link(root)
for o in objs:
    if o.parent is None: o.parent=root
root.scale=(s,s,s)
root.location=(-centre.x*s,-centre.y*s,-mn.z*s)

scn=bpy.context.scene
scn.render.engine='BLENDER_EEVEE'
scn.render.resolution_x=640; scn.render.resolution_y=800
scn.render.film_transparent=False
world=bpy.data.worlds.new("W"); scn.world=world
world.use_nodes=True
world.node_tree.nodes["Background"].inputs[0].default_value=(0.16,0.15,0.14,1)
world.node_tree.nodes["Background"].inputs[1].default_value=1.0

def light(name,loc,energy,size=3.0):
    d=bpy.data.lights.new(name,type='AREA'); d.energy=energy; d.size=size
    o=bpy.data.objects.new(name,d); o.location=loc
    scn.collection.objects.link(o)
    c=o.constraints.new('TRACK_TO'); c.target=root; c.track_axis='TRACK_NEGATIVE_Z'; c.up_axis='UP_Y'
    return o
light("key",(4.2,-2.6,3.8),1400)
light("fill",(1.0,4.0,1.8),420)
light("rim",(-4.0,1.0,3.2),520)

cam_d=bpy.data.cameras.new("C"); cam_d.lens=70
cam=bpy.data.objects.new("C",cam_d); scn.collection.objects.link(cam); scn.camera=cam
tgt=bpy.data.objects.new("TGT",None); tgt.location=(0,0,1.0); scn.collection.objects.link(tgt)
c=cam.constraints.new('TRACK_TO'); c.target=tgt; c.track_axis='TRACK_NEGATIVE_Z'; c.up_axis='UP_Y'

views=[("front",0),("three_quarter",-42),("side",-90),("back",180)]
R=6.0
os.makedirs(OUT,exist_ok=True)
for name,ang in views:
    a=math.radians(ang)
    cam.location=(R*math.cos(a), R*math.sin(a), 1.5)
    scn.render.filepath=os.path.join(OUT,f"turn_{name}.png")
    bpy.ops.render.render(write_still=True)
print("RENDERED_OK")
