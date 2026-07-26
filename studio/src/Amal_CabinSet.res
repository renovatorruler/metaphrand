/* अमल — the TRAIN CABIN standing set (gray blocking geometry).
   Emits a bpy script and runs Blender headless: builds the enclosed
   FC-style four-berth cabin (full-height partitions, barred window,
   sliding door, side corridor, platform slab outside), saves the .blend,
   renders three approval angles.
   Run: node src/Amal_CabinSet.res.mjs */

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let outDir = "/Users/dusty/dev/metaphrand/stories/amal/set3d"
let py = `
import bpy, math

# ---------- clean ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

# world background so nothing renders as void
w = bpy.data.worlds.new("w")
w.use_nodes = True
bgn = w.node_tree.nodes["Background"]
bgn.inputs[0].default_value = (0.55, 0.58, 0.62, 1.0)
bgn.inputs[1].default_value = 0.8
sc.world = w

# ---------- materials ----------
def mat(name, rgb):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = 0.85
    return m

M_WALL  = mat("wall",  (0.62, 0.60, 0.55))   # cream-gray
M_BERTH = mat("berth", (0.15, 0.45, 0.22))   # bench A green
M_BERTHB = mat("berthb", (0.75, 0.45, 0.12))  # bench B orange
M_TEXT  = mat("text", (0.02, 0.02, 0.02))
M_FLOOR = mat("floor", (0.25, 0.25, 0.26))
M_DARK  = mat("dark",  (0.35, 0.30, 0.25))   # door / laminate
M_LAM   = mat("lam",   (0.45, 0.33, 0.22))   # partition laminate brown
M_PLAT  = mat("plat",  (0.55, 0.53, 0.50))

def box(name, sx, sy, sz, x, y, z, m):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))
    o = bpy.context.object
    o.name = name
    o.scale = (sx/2, sy/2, sz/2)
    o.data.materials.append(m)
    return o

# ---------- dimensions (meters) ----------
# X across the coach: window wall at x=0 -> corridor outer wall at x=2.95
# Y along the coach: partitions at y=0 and y=2.0 ; Z up, floor z=0
CW = 2.30   # cabin width (x)
CD = 2.00   # cabin depth (y)
H  = 2.60   # ceiling
COR = 0.65  # corridor width
T  = 0.06   # wall thickness

# floor + ceiling (cabin + corridor)
box("floor", 2.95, CD, T, 2.95/2, CD/2, -T/2, M_FLOOR)
box("ceiling", 2.95, CD, T, 2.95/2, CD/2, H + T/2, M_WALL)

# partitions (full height) at y=0 and y=2.0, spanning cabin + corridor
box("partition_A", 2.95, T, H, 2.95/2, -T/2, H/2, M_LAM)
box("partition_B", 2.95, T, H, 2.95/2, CD + T/2, H/2, M_LAM)

# window wall x=0 — TWO windows, one per bench (Indian section, author-corrected)
# window A (bench A / the woman): y 0.12..0.62 ; window B (bench B / Kamla): y 1.38..1.88
box("pier_left",  T, 0.12, H, -T/2, 0.06, H/2, M_WALL)
box("pier_mid",   T, 0.76, H, -T/2, 1.00, H/2, M_WALL)
box("pier_right", T, 0.12, H, -T/2, CD - 0.06, H/2, M_WALL)
for tag, yc in [("A", 0.37), ("B", 1.63)]:
    box(f"wtop_{tag}",  T, 0.50, H - 1.50, -T/2, yc, 1.50 + (H - 1.50)/2, M_WALL)
    box(f"wsill_{tag}", T, 0.50, 0.85, -T/2, yc, 0.425, M_WALL)
    for i, bz in enumerate([0.95, 1.06, 1.17, 1.28, 1.39]):
        box(f"bar_{tag}{i}", 0.015, 0.50, 0.014, -T/2, yc, bz, M_DARK)

# inner wall (cabin/corridor) x=2.30, sliding door opening y 0.62..1.18
box("iwall_a", T, 0.62, H, CW + T/2, 0.31, H/2, M_WALL)
box("iwall_b", T, 0.82, H, CW + T/2, CD - 0.41, H/2, M_WALL)
box("iwall_top", T, 0.56, H - 2.0, CW + T/2, 0.90, 2.0 + (H - 2.0)/2, M_WALL)
# door panel slid open against iwall_b
box("door", T, 0.56, 2.0, CW + T/2 + 0.04, 1.50, 1.0, M_DARK)

# corridor outer wall with one barred window
box("cwall_low", T, CD, 0.85, 2.95 - T/2, CD/2, 0.425, M_WALL)
box("cwall_top", T, CD, H - 1.50, 2.95 - T/2, CD/2, 1.50 + (H - 1.50)/2, M_WALL)
box("cwall_l", T, 0.4, 0.65, 2.95 - T/2, 0.2, 1.175, M_WALL)
box("cwall_r", T, 0.4, 0.65, 2.95 - T/2, CD - 0.2, 1.175, M_WALL)
for i, bz in enumerate([1.00, 1.17, 1.34]):
    box(f"cbar_{i}", 0.02, 1.2, 0.02, 2.95 - T/2, CD/2, bz, M_DARK)
box("cshutter", 0.02, 1.24, 0.68, 2.95 - T/2 - 0.03, CD/2, 1.175, M_LAM)

# lower berths (benches) along each partition, spanning most of cabin width
box("bench_A", 2.20, 0.60, 0.10, 1.12, 0.30, 0.42, M_BERTH)   # near partition_A
box("bench_A_base", 2.20, 0.60, 0.42, 1.12, 0.30, 0.21, M_DARK)
box("bench_B", 2.20, 0.60, 0.10, 1.12, CD - 0.30, 0.42, M_BERTHB)
box("bench_B_base", 2.20, 0.60, 0.42, 1.12, CD - 0.30, 0.21, M_DARK)

# upper berths
box("upper_A", 2.20, 0.55, 0.08, 1.12, 0.28, 1.78, M_BERTH)
box("upper_B", 2.20, 0.55, 0.08, 1.12, CD - 0.28, 1.78, M_BERTHB)

# corridor floor strip
box("corridor_strip", 0.62, CD, 0.012, CW + 0.33, CD/2, 0.012, mat("corr", (0.8, 0.75, 0.35)))

# ---------- text tags ----------
import math as _m
def txt(body, x, y, z, rot, size=0.15, align='CENTER'):
    bpy.ops.object.text_add(location=(x, y, z))
    t = bpy.context.object
    t.data.body = body
    t.data.size = size
    t.data.align_x = align
    t.rotation_euler = rot
    t.data.materials.append(M_TEXT)
    return t

UP = (0, 0, 0)                       # flat, read from above
FACE_INTO_ROOM_FROM_WINDOW = (_m.pi/2, 0, _m.pi/2)    # stands on window wall, faces +X
FACE_INTO_ROOM_FROM_DOOR   = (_m.pi/2, 0, -_m.pi/2)   # stands on door, faces -X

txt("BENCH A (window seat here)", 1.12, 0.22, 0.531, UP, 0.13)
txt("BENCH B (facing)", 1.12, 1.62, 0.531, UP, 0.13)
txt("CORRIDOR", 2.63, 0.55, 0.02, (0, 0, _m.pi/2), 0.14, 'LEFT')
txt("PLATFORM (outside)", -0.9, 0.6, -0.51, UP, 0.16)
txt("WINDOW A (woman)", 0.05, 0.37, 1.66, FACE_INTO_ROOM_FROM_WINDOW, 0.10)
txt("WINDOW B (Kamla)", 0.05, 1.63, 1.66, FACE_INTO_ROOM_FROM_WINDOW, 0.10)
txt("DOOR", 2.27, 1.50, 1.62, FACE_INTO_ROOM_FROM_DOOR, 0.13)
txt("window seat", 0.30, 0.60, 0.532, UP, 0.09, 'LEFT')

# ceiling fan (disc)
bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.05, location=(1.15, 1.0, H - 0.18))
fan = bpy.context.object; fan.name = "fan"; fan.data.materials.append(M_DARK)

# platform slab outside the window (low platform, long and straight)
box("platform", 2.2, 22.0, 0.15, -1.15, 1.0, -0.60, M_PLAT)
for i, py in enumerate([-6.0, -2.0, 2.6, 6.5, 10.0]):
    box(f"plat_post_{i}", 0.08, 0.08, 2.4, -1.7, py, 0.55, M_DARK)

# the coach shell continues STRAIGHT both ways so the train cannot bend
for tag, y0, y1 in [("N", -9.0, 0.0), ("S", 2.0, 11.0)]:
    yl = y1 - y0
    box(f"shell_{tag}", 0.06, yl, H + 0.65, -0.03, (y0 + y1)/2, (H - 0.65)/2 + 0.02, M_WALL)
    # window rhythm: shallow dark insets every ~2.0m
    n = int(yl // 2.0)
    for k in range(n):
        wy = y0 + 1.0 + k * 2.0
        box(f"shellwin_{tag}{k}", 0.02, 0.55, 0.65, -0.075, wy, 1.175, M_DARK)
# roofline strip full length
box("roofline", 0.30, 20.0, 0.25, -0.12, 1.0, H + 0.30, M_WALL)

# ---------- mannequins (the ruler: people make proportions readable) ----------
def seated(nm, sx, sy, face, col):
    m = mat(nm, col)
    box(nm + "_hip",   0.34, 0.32, 0.16, sx, sy, 0.55, m)
    box(nm + "_torso", 0.36, 0.20, 0.52, sx, sy - face*0.04, 0.90, m)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.105, location=(sx, sy - face*0.02, 1.27))
    h = bpy.context.object; h.name = nm + "_head"; h.data.materials.append(m)
    box(nm + "_thigh", 0.32, 0.42, 0.12, sx, sy + face*0.30, 0.50, m)
    box(nm + "_shin",  0.30, 0.12, 0.42, sx, sy + face*0.48, 0.21, m)

def lying(nm, x, y, col):
    m = mat(nm, col)
    box(nm + "_body", 1.55, 0.38, 0.22, x, y, 1.95, m)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.10, location=(x + 0.85, y, 1.98))
    h = bpy.context.object; h.name = nm + "_head"; h.data.materials.append(m)

def standing(nm, x, y, col):
    m = mat(nm, col)
    box(nm + "_legs",  0.34, 0.22, 0.80, x, y, -0.125, m)
    box(nm + "_torso", 0.40, 0.24, 0.60, x, y, 0.575, m)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.105, location=(x, y, 1.04))
    h = bpy.context.object; h.name = nm + "_head"; h.data.materials.append(m)

# the woman at Window A (bench A window seat), facing bench B
seated("WOMAN", 0.20, 0.34, +1, (0.85, 0.15, 0.55))
# the bundle at her window-side shoulder
box("BUNDLE", 0.20, 0.20, 0.44, 0.18, 0.20, 1.02, mat("bundle", (0.25, 0.65, 0.25)))
# Kamla at Window B (bench B window seat), Suresh beside her — both facing bench A
seated("KAMLA",  0.35, 1.70, -1, (0.10, 0.65, 0.75))
seated("SURESH", 1.00, 1.70, -1, (0.12, 0.18, 0.55))
# Rajesh lying on the upper berth above bench B
lying("RAJESH", 1.10, 1.72, (0.10, 0.55, 0.50))
# a standing man outside on the platform at Kamla's window (the peek sightline)
standing("MAN_OUTSIDE", -0.50, 1.63, (0.35, 0.35, 0.40))
# platform crowd anchors along the coach (beyond the bay)
standing("PLAT_1", -0.65, 2.90, (0.42, 0.40, 0.38))
standing("PLAT_2", -0.95, 3.90, (0.40, 0.42, 0.38))
standing("PLAT_3", -0.55, 4.70, (0.38, 0.38, 0.42))

# ---------- light ----------
bpy.ops.object.light_add(type='SUN', location=(-3, 1, 3))
sun = bpy.context.object
sun.rotation_euler = (math.radians(55), 0, math.radians(-70))
sun.data.energy = 1.4
bpy.ops.object.light_add(type='AREA', location=(1.15, 1.0, H - 0.3))
ar = bpy.context.object
ar.data.energy = 22
ar.data.size = 1.6

# ---------- cameras (track-to an empty at cabin heart) ----------
bpy.ops.object.empty_add(location=(0.9, 1.0, 1.05))
target = bpy.context.object; target.name = "target"

def cam(name, x, y, z, lens):
    c = bpy.data.cameras.new(name); c.lens = lens
    o = bpy.data.objects.new(name, c)
    o.location = (x, y, z)
    con = o.constraints.new('TRACK_TO')
    con.target = target
    bpy.context.collection.objects.link(o)
    return o

cam_master   = cam("cam_master",   2.16, 0.18, 1.55, 24)   # from door corner
cam_reverse  = cam("cam_reverse",  2.10, 1.85, 1.50, 24)   # from opposite corner
cam_platform = cam("cam_platform", -1.35, 0.72, 1.08, 38)  # outside, through the bars
# platform cam aims at the window itself
bpy.ops.object.empty_add(location=(0.1, 0.37, 1.10))
wtarget = bpy.context.object; wtarget.name = "wtarget"
cam_platform.constraints[0].target = wtarget

# top-down orthographic plan view (layout debugging / approval)
pc = bpy.data.cameras.new("cam_plan")
pc.type = 'ORTHO'
pc.ortho_scale = 5.4
po = bpy.data.objects.new("cam_plan", pc)
po.location = (1.475, 1.0, 6.0)
po.rotation_euler = (0, 0, 0)
bpy.context.collection.objects.link(po)
cam_plan = po

# ---------- render ----------
sc.render.engine = 'CYCLES'
sc.cycles.samples = 24
sc.render.resolution_x = 1152
sc.render.resolution_y = 648
sc.view_settings.view_transform = 'Standard'

import os
os.makedirs("${outDir}/renders", exist_ok=True)

# AI-NEUTRAL CLAY PASS: uniform gray, no labels — geometry only
M_CLAY = mat("clay", (0.52, 0.52, 0.52))
texts = [o for o in bpy.data.objects if o.type == 'FONT']
for t in texts:
    t.hide_render = True
bpy.context.view_layer.material_override = M_CLAY
sc.camera = cam_platform
sc.render.filepath = "${outDir}/renders/cam_platform_ai.png"
bpy.ops.render.render(write_still=True)
bpy.context.view_layer.material_override = None
for t in texts:
    t.hide_render = False

# plan first, roof off so the layout reads
for n in ["ceiling", "upper_A", "upper_B", "fan", "RAJESH_body", "RAJESH_head"]:
    bpy.data.objects[n].hide_render = True
sc.camera = cam_plan
sc.render.filepath = "${outDir}/renders/cam_plan.png"
bpy.ops.render.render(write_still=True)
for n in ["ceiling", "upper_A", "upper_B", "fan", "RAJESH_body", "RAJESH_head"]:
    bpy.data.objects[n].hide_render = False

for c in [cam_master, cam_reverse, cam_platform]:
    sc.camera = c
    sc.render.filepath = "${outDir}/renders/" + c.name + ".png"
    bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath="${outDir}/cabin.blend")
print("CABIN OK")
`

let main = () => {
  let mk = Js.Dict.empty()
  Js.Dict.set(mk, "recursive", Obj.magic(true))
  mkdirSync(outDir, Obj.magic(mk))
  writeFileSync("/tmp/cabin_build.py", py)
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic("pipe"))
  Js.Dict.set(opts, "timeout", Obj.magic(480000))
  let out = execSync("/opt/homebrew/bin/blender --background --python /tmp/cabin_build.py 2>&1 | tail -8", opts)
  Js.log(out)
}
main()
