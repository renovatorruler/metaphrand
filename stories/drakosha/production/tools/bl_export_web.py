import bpy, sys, os, struct, base64, json
import mathutils
argv=sys.argv[sys.argv.index('--')+1:]
GLB, OUT, TARGET = argv[0], argv[1], int(argv[2])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
print("meshes:",len(meshes),"tris:",sum(len(o.data.loop_triangles) for o in meshes))
for o in meshes: o.data.calc_loop_triangles()
# join
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
if len(meshes)>1: bpy.ops.object.join()
ob=bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

me=ob.data
me.calc_loop_triangles()
n0=len(me.loop_triangles)
if n0>TARGET:
    m=ob.modifiers.new("dec","DECIMATE"); m.ratio=TARGET/n0
    bpy.ops.object.modifier_apply(modifier=m.name)
    me=ob.data; me.calc_loop_triangles()
print("after decimate tris:", len(me.loop_triangles))

# normalise: centre, height 2, sitting on z=0
mn=mathutils.Vector((1e9,)*3); mx=mathutils.Vector((-1e9,)*3)
for v in me.vertices:
    for i in range(3):
        mn[i]=min(mn[i],v.co[i]); mx[i]=max(mx[i],v.co[i])
size=mx-mn; c=(mn+mx)/2; s=2.0/max(size.z,1e-6)

uv=me.uv_layers.active.data if me.uv_layers.active else None
pos=[]; nor=[]; uvs=[]; idx=[]
seen={}
for t in me.loop_triangles:
    for li in t.loops:
        l=me.loops[li]; v=me.vertices[l.vertex_index]
        u=(uv[li].uv[0], uv[li].uv[1]) if uv else (0.0,0.0)
        key=(l.vertex_index, round(u[0],5), round(u[1],5), round(l.normal[0],3), round(l.normal[1],3), round(l.normal[2],3))
        i=seen.get(key)
        if i is None:
            i=len(pos)//3; seen[key]=i
            pos += [(v.co[0]-c[0])*s, (v.co[1]-c[1])*s, (v.co[2]-mn[2])*s]
            nor += [l.normal[0], l.normal[1], l.normal[2]]
            uvs += [u[0], u[1]]
        idx.append(i)
print("verts:",len(pos)//3,"indices:",len(idx))

# find the BASE COLOUR image by walking back from the shader's Base Color input
def trace_image(sock, depth=0):
    """follow links backwards from a socket until we hit an image texture"""
    if depth>8 or not sock.is_linked: return None
    n=sock.links[0].from_node
    if n.type=='TEX_IMAGE': return n.image
    for i in n.inputs:
        r=trace_image(i, depth+1)
        if r: return r
    return None

img=None
for mat in ob.data.materials:
    if not mat or not mat.use_nodes: continue
    out=next((n for n in mat.node_tree.nodes if n.type=='OUTPUT_MATERIAL'), None)
    surf=out.inputs['Surface'] if out else None
    shader=surf.links[0].from_node if (surf and surf.is_linked) else None
    if shader:
        for nm in ('Base Color','Color','Emission Color'):
            if nm in shader.inputs:
                img=trace_image(shader.inputs[nm])
                if img: break
    if img is None:   # last resort: any image whose name does not smell like a data map
        for n in mat.node_tree.nodes:
            if n.type=='TEX_IMAGE' and n.image:
                nm=n.image.name.lower()
                if not any(k in nm for k in ('normal','rough','metal','occl','ao','bump','orm')):
                    img=n.image; break
    if img: break
print("picked image:", img.name if img else None)

tex_path=os.path.join(OUT,'tex.png')
os.makedirs(OUT,exist_ok=True)
if img:
    img.filepath_raw=tex_path; img.file_format='PNG'; img.save()
    print("texture:", img.size[:])
else:
    print("NO TEXTURE")

buf=bytearray()
import array
a=array.array('f',pos); a.byteswap() if False else None; buf += a.tobytes()
a=array.array('f',nor); buf += a.tobytes()
a=array.array('f',uvs); buf += a.tobytes()
a=array.array('I',idx); buf += a.tobytes()
open(os.path.join(OUT,'mesh.bin'),'wb').write(bytes(buf))
json.dump({'nverts':len(pos)//3,'nidx':len(idx)}, open(os.path.join(OUT,'mesh.json'),'w'))
print("EXPORT_OK", len(buf))
