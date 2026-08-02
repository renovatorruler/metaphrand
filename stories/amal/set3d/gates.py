"""Pipeline gates — importable module used by every build/import/shot script.
Doctrine: every check either BLOCKS (raises) or produces a required ARTIFACT.
Nothing here depends on anyone remembering anything."""
import bpy, os, sys, math, json, mathutils

SET3D = '/Users/dusty/dev/metaphrand/stories/amal/set3d'

# ------------------------------------------------------------------ preflight
def preflight_set(spec_path, ref_dir, min_refs=2):
    """A set build refuses to run without its spec and photographic evidence."""
    if not os.path.exists(spec_path):
        raise SystemExit(f'GATE FAIL [spec-missing]: {spec_path} does not exist. No spec, no set.')
    refs = [f for f in os.listdir(ref_dir)] if os.path.isdir(ref_dir) else []
    refs = [f for f in refs if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    if len(refs) < min_refs:
        raise SystemExit(f'GATE FAIL [refs-missing]: {ref_dir} holds {len(refs)} reference photos; {min_refs} required.')
    print(f'GATE OK [preflight]: spec + {len(refs)} reference photos present.')
    return refs

# ------------------------------------------------------------------ asset gate
HUMAN_FOOT_SEATED = (0.95, 1.10)   # max width/depth for a clean seated figure (m, generous)
HUMAN_FOOT_STAND  = (0.80, 0.80)

def _band_fill(meshes, lo_frac=0.18, hi_frac=0.42, G=14):
    """max XY grid-fill of any thin z-band in the low zone (the furniture-slab signature)."""
    import mathutils
    verts = []
    for o in meshes:
        mw = o.matrix_world
        vs = o.data.vertices
        stride = max(1, len(vs)//40000)
        for i in range(0, len(vs), stride):
            verts.append(mw @ vs[i].co)
    xs=[v.x for v in verts]; ys=[v.y for v in verts]; zs=[v.z for v in verts]
    x0,x1,y0,y1,z0,z1 = min(xs),max(xs),min(ys),max(ys),min(zs),max(zs)
    W,D,H = x1-x0, y1-y0, z1-z0
    best = 0.0
    band_h = 0.055
    f0 = lo_frac
    bands = []
    while f0 + band_h <= hi_frac + 0.02:
        bands.append(f0); f0 += 0.04
    for f0 in bands:
        lo = z0 + H*f0; hi = lo + H*band_h
        cells = set()
        for v in verts:
            if lo <= v.z < hi:
                cx = int((v.x-x0)/max(W,1e-6)*(G-1)); cy = int((v.y-y0)/max(D,1e-6)*(G-1))
                cells.add((cx,cy))
        best = max(best, len(cells)/(G*G))
    return best, (W,D,H)

SLAB_THRESHOLD = 0.38

def _width_profile(meshes):
    """widths at the low band vs the shoulder band. Furniture is WIDER than its occupant."""
    import mathutils
    verts=[]
    for o in meshes:
        mw=o.matrix_world; vs=o.data.vertices
        stride=max(1,len(vs)//40000)
        for i in range(0,len(vs),stride): verts.append(mw @ vs[i].co)
    xs=[v.x for v in verts]; ys=[v.y for v in verts]; zs=[v.z for v in verts]
    x0,x1,y0,y1,z0,z1=min(xs),max(xs),min(ys),max(ys),min(zs),max(zs)
    W,D,H=x1-x0,y1-y0,z1-z0
    def band(f0,f1):
        lo,hi=z0+H*f0, z0+H*f1
        bx=[v.x for v in verts if lo<=v.z<hi]
        by=[v.y for v in verts if lo<=v.z<hi]
        if len(bx)<20: return 0.0,0.0
        return max(bx)-min(bx), max(by)-min(by)
    low_w, low_d = 0.0, 0.0             # widest point anywhere in the lower half
    f = 0.05
    while f < 0.55:
        bw, bd = band(f, f+0.08)
        low_w = max(low_w, bw); low_d = max(low_d, bd)
        f += 0.05
    sh_w,  sh_d  = band(0.72,0.94)      # shoulders
    return (low_w,low_d),(sh_w,sh_d),(W,D,H)

SEAT_RATIO_MAX = 1.35   # low-band width may exceed shoulder width by at most this

def asset_gate(meshes, name, seated=True, target_h=None):
    """Reject a character mesh that arrived with furniture.
    Detector 1: absolute footprint envelope.
    Detector 2: low-band width vs shoulder width — furniture is wider than its occupant.
    Calibrated 2026-07-30 against 4 known-bad and 3 known-clean meshes."""
    (lw,ld),(sw,sd),(w,d,h) = _width_profile(meshes)
    lim = HUMAN_FOOT_SEATED if seated else HUMAN_FOOT_STAND
    if w > lim[0] or d > lim[1]:
        raise SystemExit(
            f'GATE FAIL [furniture-envelope]: {name} footprint {w:.2f}x{d:.2f}m exceeds '
            f'{lim[0]:.2f}x{lim[1]:.2f}m. REGENERATE furniture-free; do not trim.')
    ratio = (lw/sw) if sw > 0.05 else 0.0
    if ratio >= SEAT_RATIO_MAX:
        raise SystemExit(
            f'GATE FAIL [furniture-wider-than-occupant]: {name} low-band width {lw:.2f}m is '
            f'{ratio:.2f}x the shoulder width {sw:.2f}m (limit {SEAT_RATIO_MAX}) — a bench/stool '
            f'is inside the mesh. REGENERATE furniture-free; do not trim.')
    print(f'GATE OK [asset]: {name} footprint {w:.2f}x{d:.2f}m, low/shoulder width ratio {ratio:.2f}.')
    return w, d, h

def asset_passport(meshes, name, out_dir):
    """Solo four-view render of the asset on a bare floor — visible birth certificate."""
    os.makedirs(out_dir, exist_ok=True)
    S = bpy.context.scene
    prev_cam, prev_res = S.camera, (S.render.resolution_x, S.render.resolution_y)
    prev_engine = S.render.engine
    mn = [9e9]*3; mx = [-9e9]*3
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ mathutils.Vector(c)
            for i in range(3):
                mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    cx, cy, cz = (mn[0]+mx[0])/2, (mn[1]+mx[1])/2, (mn[2]+mx[2])/2
    rad = max(mx[0]-mn[0], mx[1]-mn[1], mx[2]-mn[2]) * 1.6 + 0.4
    S.render.engine = 'BLENDER_WORKBENCH'
    sh = S.display.shading; sh.light='STUDIO'; sh.color_type='TEXTURE'; sh.show_cavity=True
    S.render.resolution_x, S.render.resolution_y = 480, 640
    tgt = bpy.data.objects.new('_pp_aim', None); S.collection.objects.link(tgt)
    tgt.location = (cx, cy, cz)
    cd = bpy.data.cameras.new('_pp_cam'); cd.lens = 45
    co = bpy.data.objects.new('_pp_cam', cd); S.collection.objects.link(co)
    cn = co.constraints.new('TRACK_TO'); cn.target = tgt
    cn.track_axis='TRACK_NEGATIVE_Z'; cn.up_axis='UP_Y'
    S.camera = co
    for i, ang in enumerate((0, 90, 180, 270)):
        a = math.radians(ang)
        co.location = (cx + rad*math.sin(a), cy - rad*math.cos(a), cz + 0.15)
        S.render.filepath = os.path.join(out_dir, f'{name}_{i}.png')
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(co, do_unlink=True); bpy.data.objects.remove(tgt, do_unlink=True)
    S.camera = prev_cam
    S.render.resolution_x, S.render.resolution_y = prev_res
    S.render.engine = prev_engine
    print(f'GATE OK [passport]: {name} 4-view written to {out_dir}.')

# ------------------------------------------------------------------ shot gate
def shot_gate(cam_obj, aim_loc, subject_names, scene=None, tol=0.55):
    """Ray from camera to subject through real geometry. First hit must belong to the
    subject (or be within tol of the aim point). Otherwise the shot DOES NOT COMPILE."""
    S = scene or bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    origin = cam_obj.matrix_world.translation
    target = mathutils.Vector(aim_loc)
    d = (target - origin)
    dist = d.length
    d.normalize()
    hit, loc, nrm, idx, obj, mw = S.ray_cast(dg, origin + d*0.05, d, distance=dist+0.5)
    if not hit:
        return True  # nothing between camera and subject at all
    hit_name = obj.name
    if any(hit_name.startswith(s) for s in subject_names):
        return True
    if (mathutils.Vector(loc) - target).length <= tol:
        return True  # hit landed on/next to the aim point itself
    raise SystemExit(
        f'GATE FAIL [shot-blocked]: camera {cam_obj.name} cannot see its subject — '
        f'first hit is {hit_name} at {[round(v,2) for v in loc]}. Re-block or re-solve.')

def bounds_gate(cam_obj, xmin, xmax, ymin, ymax, zmin, zmax):
    p = cam_obj.matrix_world.translation
    if not (xmin <= p.x <= xmax and ymin <= p.y <= ymax and zmin <= p.z <= zmax):
        raise SystemExit(
            f'GATE FAIL [camera-outside]: {cam_obj.name} at {[round(v,2) for v in p]} '
            f'is outside the coach interior. Re-solve.')
    return True
