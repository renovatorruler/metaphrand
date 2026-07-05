"""INDIVISIBLE — gray-clay set blockouts in Blender (3D-consistent storyboard refs).

Runs INSIDE Blender headless. Builds low-poly clay models of every pilot set,
then renders each from its shots' exact cameras. Clay renders are passed to
Gemini as structural references, so every angle of a location obeys one real
geometry — including reverse angles no master frame ever showed.

    Blender --background --python examples/civilwar_set3d.py -- all stories/civil-war/storyboard/clay
    Blender --background --python examples/civilwar_set3d.py -- hangar stories/civil-war/storyboard/clay

Cameras are keyed by storyboard frame id (clay/<frame>.png pairs 1:1 with the
pipeline's frames). Only SPATIAL shots get clay — pure face close-ups don't
need geometry and keep Gemini's freedom. Sets are STATIC: architecture, fixed
props, the airplane; actors are Gemini's job (the acting layer).
"""

import math
import os
import random
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # so `import setplan` works

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["all", "clay"]
SET, OUTDIR = ARGS[0], ARGS[1]
HORSE_GLB = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "..", "stories", "civil-war", "assets", "horse.glb")


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def box(name, size, loc, rot=(0, 0, 0), color=0.55):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.color = (color, color, color, 1)
    return o


def cyl(name, r, depth, loc, rot=(0, 0, 0), color=0.55, verts=24):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc,
                                        rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    o.color = (color, color, color, 1)
    return o


def cone(name, r, depth, loc, rot=(0, 0, 0), color=0.55):
    bpy.ops.mesh.primitive_cone_add(radius1=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.color = (color, color, color, 1)
    return o


def sphere(name, r, loc, color=0.55):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=16, ring_count=8)
    o = bpy.context.object
    o.name = name
    o.color = (color, color, color, 1)
    return o


def build_cessna(cx=0.0, cy=0.0, heading=0.0, tag=""):
    """High-wing single, nose toward +y before rotation by `heading` (radians)."""
    def rot2(x, y):
        c, s = math.cos(heading), math.sin(heading)
        return (cx + x * c - y * s, cy + x * s + y * c)

    def place(o, x, y):
        o.location.x, o.location.y = rot2(x, y)
        o.rotation_euler[2] += heading

    f = cyl(f"fuselage{tag}", 0.72, 7.0, (0, 0, 1.25), rot=(math.pi / 2, 0, 0), color=0.72)
    f.scale[0] = 0.85
    place(f, 0, 0)
    place(cone(f"nose{tag}", 0.62, 1.1, (0, 0, 1.25), rot=(-math.pi / 2, 0, 0), color=0.72), 0, 4.05)
    place(cyl(f"prop{tag}", 1.0, 0.05, (0, 0, 1.25), rot=(math.pi / 2, 0, 0), color=0.6), 0, 4.65)
    place(box(f"wing{tag}", (11, 1.7, 0.14), (0, 0, 2.45), color=0.72), 0, 1.4)
    place(box(f"tailplane{tag}", (3.4, 0.9, 0.1), (0, 0, 1.45), color=0.72), 0, -3.2)
    place(box(f"fin{tag}", (0.12, 1.5, 1.7), (0, 0, 2.4), color=0.72), 0, -3.4)
    for sx in (-1, 1):
        place(cyl(f"strut{tag}{sx}", 0.05, 2.0, (0, 0, 1.7), rot=(0, sx * 0.5, 0), color=0.65),
              sx * 1.7, 2.0)
        place(cyl(f"gear{tag}{sx}", 0.28, 0.18, (0, 0, 0.28), rot=(0, math.pi / 2, 0), color=0.35),
              sx * 1.1, 0.4)
    place(cyl(f"nosegear{tag}", 0.22, 0.15, (0, 0, 0.22), rot=(0, math.pi / 2, 0), color=0.35), 0, 3.4)
    place(box(f"cargodoor{tag}", (0.06, 0.9, 0.8), (0, 0, 1.1), color=0.6), 0.68, -1.6)


# ---------------------------------------------------------------- the sets

def build_hangar():
    """Interior 24m wide (x -12..12), 18m deep (y 0 door .. -18 back), 6m walls."""
    box("floor", (26, 20, 0.1), (0, -9, -0.05), color=0.42)
    box("wall-back", (26, 0.3, 6), (0, -18.1, 3), color=0.5)
    box("wall-left", (0.3, 18.6, 6), (-12.1, -9, 3), color=0.5)
    box("wall-right", (0.3, 18.6, 6), (12.1, -9, 3), color=0.5)
    box("roof", (26, 20, 0.25), (0, -9, 6.2), color=0.48)
    box("door-header", (26, 0.3, 1.2), (0, 0.1, 5.6), color=0.5)
    box("door-panel", (7, 0.25, 5.0), (8.5, 0.15, 2.5), color=0.45)
    build_cessna(-2, -9, heading=0.0)  # nose toward the door
    box("scale-base", (0.95, 0.95, 0.14), (3.5, -6, 0.07), color=0.6)
    box("scale-post", (0.1, 0.1, 1.5), (3.5, -6.42, 0.85), color=0.6)
    cyl("scale-dial", 0.27, 0.07, (3.5, -6.42, 1.62), rot=(math.pi / 2, 0, 0), color=0.8)
    box("duffel", (0.85, 0.4, 0.4), (2.6, -5.3, 0.2), color=0.5)
    box("bench", (1.0, 4.2, 0.95), (11.3, -9, 0.48), color=0.55)
    cyl("coffee-can", 0.11, 0.26, (11.3, -7.6, 1.08), color=0.78)
    box("wallphone", (0.25, 0.1, 0.4), (11.9, -6.2, 1.5), color=0.6)
    box("toaster", (0.55, 0.35, 0.34), (-11.5, -7.2, 0.17), color=0.75)
    box("pic-frame", (0.55, 0.05, 0.75), (-11.55, -8.2, 0.38), rot=(0.06, 0, 0), color=0.75)
    box("suitcase", (0.72, 0.26, 0.5), (-11.5, -9.3, 0.25), color=0.75)
    cyl("light-cord", 0.015, 1.6, (2.5, -6.5, 5.3), color=0.4)
    cone("light-shade", 0.35, 0.35, (2.5, -6.5, 4.4), rot=(math.pi, 0, 0), color=0.85)


def build_homestead():
    """House faces +y; porch at y ~-10.5; the track runs +y to the county road."""
    box("dirt", (60, 80, 0.08), (0, 8, -0.04), color=0.45)
    box("track", (3.2, 70, 0.02), (1, 28, 0.02), color=0.58)
    box("county-road", (40, 4, 0.02), (0, 60, 0.02), color=0.52)
    cyl("gatepost", 0.12, 1.4, (2.8, 2.0, 0.7), color=0.5)
    box("house", (9, 8, 6.4), (0, -16, 3.2), color=0.62)
    box("house-roof", (10, 9, 0.3), (0, -16, 6.6), color=0.5)
    box("porch-deck", (8, 2.6, 0.3), (0, -11.4, 0.55), color=0.55)
    for i, sy in enumerate((-10.4, -10.0, -9.6)):
        box(f"step{i}", (3.0, 0.4, 0.15), (0, sy, 0.4 - i * 0.14), color=0.55)
    for px in (-3.6, -1.2, 1.2, 3.6):
        cyl(f"post{px}", 0.09, 2.4, (px, -10.3, 1.85), color=0.55)
    box("porch-roof", (8.6, 3.0, 0.18), (0, -11.4, 3.1), color=0.5)
    box("door", (1.1, 0.1, 2.2), (0.8, -12.05, 1.6), color=0.35)
    for wx in (-2.2, 2.2):
        box(f"upwin{wx}", (1.0, 0.1, 1.3), (wx, -11.95, 4.6), color=0.2)
    cyl("chop-block", 0.27, 0.55, (3.5, -7.5, 0.28), color=0.5)
    for i in range(3):
        box(f"wood{i}", (0.7, 0.5, 0.35), (4.4 + i * 0.2, -8.1 - i * 0.5, 0.18), color=0.5)
    cyl("well", 0.65, 0.95, (-6, -6.5, 0.48), color=0.5)
    box("well-roof", (1.6, 1.2, 0.12), (-6, -6.5, 2.1), color=0.5)
    for wx in (-6.6, -5.4):
        cyl(f"wellpost{wx}", 0.06, 1.6, (wx, -6.5, 1.3), color=0.5)
    for i, (px, py) in enumerate(((-7.6, -10.6), (-7.6, -13.4), (-10.8, -10.6), (-10.8, -13.4))):
        cyl(f"lpost{i}", 0.1, 2.6, (px, py, 1.3), color=0.5)
    box("lean-roof", (3.8, 3.4, 0.15), (-9.2, -12, 2.7), rot=(0, 0.12, 0), color=0.5)
    h = cyl("bay-body", 0.45, 1.7, (-9.4, -12, 1.15), rot=(0, math.pi / 2, 0), color=0.4)
    h.scale[2] = 1.15
    for i, (lx, ly) in enumerate(((-10.1, -12.3), (-10.1, -11.7), (-8.7, -12.3), (-8.7, -11.7))):
        cyl(f"bay-leg{i}", 0.07, 1.0, (lx, ly, 0.5), color=0.4)
    box("bay-neck", (0.3, 0.55, 0.6), (-8.45, -12, 1.7), rot=(0.5, 0, 0), color=0.4)
    box("bay-head", (0.22, 0.65, 0.3), (-8.35, -11.7, 2.05), rot=(0.25, 0, 0), color=0.4)
    box("rail", (2.0, 0.09, 0.09), (-7.4, -9.9, 1.12), color=0.5)
    for rx in (-8.3, -6.5):
        cyl(f"railpost{rx}", 0.07, 1.1, (rx, -9.9, 0.56), color=0.5)
    box("saddle", (0.52, 0.38, 0.3), (-7.3, -9.9, 1.32), color=0.78)
    random.seed(7)
    for i in range(10):
        tx = -14 + i * 3 + random.uniform(-1, 1)
        sphere(f"tree{i}", random.uniform(1.6, 2.6), (tx, -24 + random.uniform(-2, 2), 3.2), color=0.38)
        cyl(f"trunk{i}", 0.18, 2.6, (tx, -24, 1.2), color=0.35)


def build_bonusroom():
    """Empty bonus room, window on +x wall; cul-de-sac ring outside below."""
    box("b-floor", (6, 5, 0.1), (0, 0, 1.0), color=0.6)
    box("b-ceil", (6, 5, 0.1), (0, 0, 3.75), color=0.62)
    box("b-wall-n", (6, 0.15, 2.7), (0, 2.5, 2.4), color=0.65)
    box("b-wall-s", (6, 0.15, 2.7), (0, -2.5, 2.4), color=0.65)
    box("b-wall-w", (0.15, 5, 2.7), (-3, 0, 2.4), color=0.65)
    box("b-wall-e1", (0.15, 1.6, 2.7), (3, 1.7, 2.4), color=0.65)
    box("b-wall-e2", (0.15, 1.6, 2.7), (3, -1.7, 2.4), color=0.65)
    box("b-wall-e3", (0.15, 1.8, 0.8), (3, 0, 1.45), color=0.65)
    box("b-wall-e4", (0.15, 1.8, 0.6), (3, 0, 3.45), color=0.65)
    box("b-window-sill", (0.2, 1.9, 0.06), (3, 0, 1.86), color=0.6)
    box("b-door", (1.0, 0.12, 2.1), (-1.8, -2.5, 2.1), color=0.4)
    box("house-shell", (10, 9, 7), (0, 0, -0.6), color=0.66)
    box("hs-roof", (10.6, 9.6, 0.3), (0, 0, 3.0), color=0.5)
    box("street-ring", (60, 60, 0.02), (22, -18, -4.19), color=0.5)
    for i in range(8):
        a = i * math.pi / 4
        hx, hy = 22 + 18 * math.cos(a), -18 + 18 * math.sin(a)
        box(f"nbr{i}", (7, 6, 5), (hx, hy, -1.7), color=0.6)
    box("sign", (0.7, 0.05, 0.5), (4.5, 7.5, -3.0), color=0.8)
    cyl("signpost", 0.04, 1.0, (4.5, 7.5, -3.7), color=0.5)


def build_fenceyard():
    """Two back yards split by a chain-link fence along y=0; gate at x~6.6."""
    box("grass", (32, 22, 0.05), (0, -1, -0.02), color=0.5)
    box("sidewalk", (32, 1.6, 0.06), (0, 8.5, 0.01), color=0.62)
    cyl("hydrant", 0.18, 0.7, (14, 8.5, 0.35), color=0.7)
    box("toprail", (16, 0.05, 0.05), (-1, 0, 1.22), color=0.55)
    box("midrail", (16, 0.03, 0.03), (-1, 0, 0.62), color=0.55)
    for i in range(9):
        cyl(f"fpost{i}", 0.05, 1.25, (-9 + i * 2, 0, 0.62), color=0.5)
    box("gate", (1.4, 0.04, 1.15), (6.9, 0.45, 0.62), rot=(0, 0, 0.7), color=0.55)
    box("swing-top", (3.2, 0.08, 0.08), (-8, -6, 2.2), color=0.5)
    for sx in (-9.4, -6.6):
        cyl(f"swa1{sx}", 0.05, 2.5, (sx - 0.5, -5.6, 1.1), rot=(0.35, 0, 0), color=0.5)
        cyl(f"swa2{sx}", 0.05, 2.5, (sx - 0.5, -6.4, 1.1), rot=(-0.35, 0, 0), color=0.5)
    for sx in (-8.7, -7.3):
        box(f"seat{sx}", (0.45, 0.18, 0.04), (sx, -6, 0.55), color=0.6)
    box("kporch", (3.4, 2.0, 0.25), (8, -9.5, 0.3), color=0.6)
    box("kporch-roof", (3.6, 2.2, 0.12), (8, -9.5, 2.6), color=0.55)
    box("kscreendoor", (0.95, 0.08, 2.05), (8, -10.4, 1.35), color=0.45)
    box("khouse", (9, 4, 4.5), (8, -13, 2.25), color=0.66)
    box("nia-house", (9, 4, 4.5), (-6, 12.5, 2.25), color=0.66)


def build_strip():
    """The dirt strip at night; the overpass with two fires far off."""
    box("scrub", (220, 120, 0.05), (0, 0, -0.02), color=0.4)
    box("strip-pad", (8, 130, 0.02), (0, -10, 0.02), color=0.55)
    random.seed(11)
    for i in range(26):
        sphere(f"brush{i}", random.uniform(0.3, 0.8),
               (random.uniform(-60, 60), random.uniform(-55, 45), 0.3), color=0.34)
    box("overpass", (60, 8, 1.2), (-95, 42, 8), color=0.42)
    for px in (-115, -95, -75):
        box(f"pylon{px}", (2, 2, 7.5), (px, 42, 3.75), color=0.42)
    cone("fire1", 0.9, 2.2, (-100, 42, 9.6), color=0.95)
    cone("fire2", 0.9, 2.2, (-88, 42, 9.6), color=0.95)
    build_cessna(0, 0, heading=math.pi)  # rolled out, nose south


def build_betos():
    """Beto's dirt strip: flatbed with drums, brush line, the Cessna taxied up."""
    box("b-dirt", (120, 80, 0.05), (0, 0, -0.02), color=0.46)
    rr = random.Random(5)
    for i in range(16):
        sphere(f"bl{i}", rr.uniform(0.5, 1.1),
               (-30 + i * 4 + rr.uniform(-1, 1), -16 + rr.uniform(-1.5, 1.5), 0.4), color=0.33)
    box("cab", (2.0, 2.2, 2.0), (0, 1.6, 1.0), color=0.5)
    box("bed", (2.2, 4.2, 0.5), (0, -1.6, 0.85), color=0.5)
    for i, (dx, dy) in enumerate(((-0.6, -0.7), (0.6, -0.7), (-0.6, -2.2), (0.6, -2.2))):
        cyl(f"drum{i}", 0.32, 0.95, (dx, dy, 1.6), color=0.6)
    box("pump", (0.25, 0.25, 0.5), (0, -3.4, 1.35), color=0.65)
    for i, (wx, wy) in enumerate(((-1.05, 1.1), (1.05, 1.1), (-1.05, -2.6), (1.05, -2.6))):
        cyl(f"twheel{i}", 0.42, 0.3, (wx, wy, 0.42), rot=(0, math.pi / 2, 0), color=0.3)
    build_cessna(12, 6, heading=-2.2)


def build_cockpit():
    """Panel, glareshield, yokes, seats, the sight tube, the stencil plate."""
    box("c-floor", (1.5, 2.2, 0.06), (0, -0.4, 0.62), color=0.45)
    p = box("panel", (1.25, 0.09, 0.5), (0, 0.52, 1.06), color=0.5)
    p.rotation_euler[0] = 0.18
    box("glareshield", (1.32, 0.34, 0.05), (0, 0.45, 1.34), color=0.4)
    for i, gx in enumerate((-0.45, -0.27, -0.09, 0.09, 0.27, 0.45)):
        cyl(f"gauge{i}", 0.065, 0.03, (gx, 0.49, 1.12), rot=(math.pi / 2 - 0.18, 0, 0), color=0.75)
    cyl("gauge-low", 0.05, 0.03, (-0.2, 0.5, 0.96), rot=(math.pi / 2 - 0.18, 0, 0), color=0.75)
    for sx in (-0.33, 0.33):
        cyl(f"col{sx}", 0.035, 0.5, (sx, 0.28, 0.95), rot=(1.2, 0, 0), color=0.45)
        box(f"yoke{sx}", (0.4, 0.04, 0.12), (sx, 0.1, 1.05), color=0.35)
    box("console", (0.22, 0.5, 0.3), (0, 0.15, 0.78), color=0.45)
    cyl("mixture", 0.022, 0.12, (0.07, 0.28, 0.96), rot=(1.4, 0, 0), color=0.8)
    cyl("throttle", 0.028, 0.12, (-0.04, 0.28, 0.96), rot=(1.4, 0, 0), color=0.3)
    box("fuel-selector", (0.1, 0.1, 0.04), (0, -0.05, 0.66), color=0.6)
    for sx in (-0.35, 0.35):
        box(f"seat{sx}", (0.55, 0.55, 0.12), (sx, -0.55, 0.78), color=0.42)
        box(f"seatback{sx}", (0.55, 0.12, 0.7), (sx, -0.82, 1.2), color=0.42)
    box("c-wall-l", (0.07, 2.0, 1.1), (-0.72, -0.35, 1.15), color=0.5)
    box("c-wall-r", (0.07, 2.0, 1.1), (0.72, -0.35, 1.15), color=0.5)
    ws = box("windscreen-frame", (1.4, 0.05, 0.75), (0, 0.78, 1.62), color=0.3)
    ws.rotation_euler[0] = -0.45
    box("c-roof", (1.45, 1.6, 0.06), (0, -0.4, 1.95), color=0.5)
    cyl("sight-tube", 0.025, 0.3, (0.66, 0.1, 1.05), color=0.85)
    box("stencil-plate", (0.18, 0.02, 0.05), (0.45, 0.42, 1.27), color=0.8)


def build_pharmacy():
    """Strip-mall pharmacy: storefront glass +y, door frame-right (x ~3.4);
    counter along the back; will-call shelf behind it; two gondola aisles."""
    box("p-floor", (12.5, 9.5, 0.08), (0, -4.5, -0.04), color=0.6)
    box("p-ceil", (12.5, 9.5, 0.1), (0, -4.5, 3.05), color=0.62)
    box("p-wall-w", (0.2, 9.5, 3), (-6.1, -4.5, 1.5), color=0.62)
    box("p-wall-e", (0.2, 9.5, 3), (6.1, -4.5, 1.5), color=0.62)
    box("p-wall-back", (12.5, 0.2, 3), (0, -9.1, 1.5), color=0.62)
    # storefront: glass implied by mullions + header; door at x=3.4
    box("p-header", (12.5, 0.15, 0.5), (0, 0.05, 2.8), color=0.55)
    for mx in (-5.0, -2.4, 0.2, 2.2):
        box(f"p-mullion{mx}", (0.08, 0.1, 2.6), (mx, 0.0, 1.3), color=0.5)
    box("p-doorframe", (1.1, 0.12, 2.45), (3.4, 0.0, 1.22), color=0.5)
    cyl("p-bell", 0.06, 0.05, (3.4, -0.12, 2.5), color=0.8)
    box("p-sign", (0.4, 0.02, 0.3), (3.0, -0.05, 1.9), color=0.85)
    # the counter L + terminal + register
    box("p-counter", (5.6, 0.9, 1.05), (-1.6, -6.6, 0.52), color=0.55)
    box("p-terminal", (0.5, 0.4, 0.45), (-3.0, -6.7, 1.3), color=0.72)
    box("p-register", (0.45, 0.45, 0.35), (-0.6, -6.7, 1.22), color=0.5)
    box("p-mat", (0.5, 0.35, 0.02), (-1.6, -6.3, 1.06), color=0.45)
    # back wall: stock shelves + will-call + radio
    box("p-backshelf", (5.8, 0.35, 1.6), (-1.5, -8.85, 2.0), color=0.58)
    for i in range(14):
        box(f"p-stock{i}", (0.16, 0.16, 0.28), (-4.0 + i * 0.38, -8.8, 1.42), color=0.8)
    box("p-willcall", (2.6, 0.3, 1.1), (2.6, -8.85, 2.1), color=0.55)
    for r in range(3):
        for c in range(7):
            box(f"p-bag{r}{c}", (0.22, 0.12, 0.3 - r * 0.02),
                (1.55 + c * 0.34, -8.72, 1.75 + r * 0.36), color=0.88)
    box("p-radio", (0.4, 0.18, 0.22), (-4.6, -8.75, 1.32), color=0.4)
    # gondola aisles
    for gx in (-2.2, 1.2):
        box(f"p-gondola{gx}", (0.9, 4.6, 1.5), (gx, -3.2, 0.75), color=0.62)
        for s in range(3):
            box(f"p-gshelf{gx}{s}", (1.0, 4.7, 0.04), (gx, -3.2, 0.45 + s * 0.5), color=0.55)
    # outside: sidewalk, bicycle with basket, two cars, road
    box("p-sidewalk", (14, 2.2, 0.06), (0, 1.3, -0.03), color=0.66)
    box("p-lot", (24, 10, 0.04), (0, 7.5, -0.02), color=0.5)
    box("p-road", (30, 3, 0.03), (0, 13.5, -0.015), color=0.45)
    # bicycle proxy near the door
    for wy in (2.0, 3.1):
        cyl(f"p-bwheel{wy}", 0.33, 0.06, (4.3, wy, 0.33), rot=(0, 1.5708, 0), color=0.35)
    box("p-bframe", (0.06, 1.0, 0.08), (4.3, 2.55, 0.62), rot=(0.25, 0, 0), color=0.4)
    box("p-basket", (0.32, 0.3, 0.25), (4.3, 3.35, 0.78), color=0.55)
    for cx, cy in ((-3.5, 7.0), (1.8, 8.4)):
        box(f"p-car{cx}", (1.9, 4.4, 1.35), (cx, cy, 0.7), color=0.45)


def build_nkitchen():
    """The Nguyens' kitchen: table centre, stove back, sink+window frame-left."""
    box("k-floor", (5.2, 4.4, 0.06), (0, 0, -0.03), color=0.55)
    box("k-ceil", (5.2, 4.4, 0.08), (0, 0, 2.55), color=0.62)
    box("k-wall-back", (5.2, 0.15, 2.5), (0, -2.2, 1.25), color=0.66)
    box("k-wall-left", (0.15, 4.4, 2.5), (-2.6, 0, 1.25), color=0.66)
    box("k-wall-right", (0.15, 4.4, 2.5), (2.6, 0, 1.25), color=0.66)
    box("k-counter", (3.4, 0.62, 0.92), (-0.5, -1.85, 0.46), color=0.55)
    box("k-stove", (0.76, 0.66, 0.92), (1.6, -1.85, 0.46), color=0.45)
    box("k-sink", (0.7, 0.5, 0.1), (-1.8, -1.85, 0.93), color=0.7)
    cyl("k-tap", 0.03, 0.35, (-1.8, -2.05, 1.12), rot=(0.6, 0, 0), color=0.75)
    box("k-window", (1.0, 0.08, 0.9), (-1.8, -2.21, 1.75), color=0.25)
    box("k-table", (1.3, 0.85, 0.08), (0.2, 0.5, 0.74), color=0.6)
    for tx, ty in ((-0.3, 0.15), (0.7, 0.15), (-0.3, 0.85), (0.7, 0.85)):
        cyl(f"k-tleg{tx}{ty}", 0.035, 0.74, (tx - 0.15 + 0.35, ty, 0.37), color=0.5)
    for cx, cy in ((0.2, 1.35), (0.2, -0.35)):
        box(f"k-chair{cx}{cy}", (0.42, 0.42, 0.06), (cx, cy, 0.46), color=0.5)
        box(f"k-chairback{cx}{cy}", (0.42, 0.06, 0.5), (cx, cy + (0.2 if cy > 0.5 else -0.2), 0.95), color=0.5)
    box("k-ricecooker", (0.3, 0.3, 0.28), (0.62, 0.72, 0.92), color=0.75)
    box("k-phone", (0.08, 0.02, 0.16), (0.5, 0.66, 0.88), rot=(0.35, 0, 0), color=0.3)
    for dx, dy in ((0.0, 0.45), (0.35, 0.3), (-0.15, 0.62)):
        cyl(f"k-dish{dx}{dy}", 0.12, 0.05, (dx, dy, 0.81), color=0.82)
    cone("k-lamp", 0.22, 0.22, (0.2, 0.5, 2.2), rot=(3.1416, 0, 0), color=0.85)


def load_horse(x, y, facing, scale=0.25):
    """Drop the CC0 Quaternius horse (no rig) at (x,y), centered, facing `facing`."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(HORSE_GLB))
    h = bpy.data.objects.get("Horse")
    for m in list(h.modifiers):
        if m.type == "ARMATURE":
            h.modifiers.remove(m)
    for o in bpy.data.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = h
    h.select_set(True)
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(set(bpy.data.objects) - before):
        if o is not h:
            bpy.data.objects.remove(o, do_unlink=True)
    xs = [v.co.x for v in h.data.vertices]
    ys = [v.co.y for v in h.data.vertices]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    for v in h.data.vertices:
        v.co.x -= cx
        v.co.y -= cy
    h.scale = (scale, scale, scale)
    h.rotation_euler = (0, 0, facing)
    h.location = (x, y, 0.0)
    h.color = (0.5, 0.48, 0.45, 1)
    return h


def place_glb(path, x, y, target_h, rot_z=0.0, color=0.6):
    """Import a generated mesh (image-to-3D), join it, scale by height, center on
    (x,y) with feet at z=0, rotate, clay-color — drop it onto its coordinate."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(path))
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    for o in bpy.data.objects:
        o.select_set(False)
    for o in new:
        o.select_set(True)
    bpy.context.view_layer.objects.active = new[0]
    if len(new) > 1:
        bpy.ops.object.join()
    h = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(set(bpy.data.objects) - before):
        if o is not h:
            bpy.data.objects.remove(o, do_unlink=True)
    xs = [v.co.x for v in h.data.vertices]
    ys = [v.co.y for v in h.data.vertices]
    zs = [v.co.z for v in h.data.vertices]
    cx, cy, zmin = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)
    for v in h.data.vertices:
        v.co.x -= cx; v.co.y -= cy; v.co.z -= zmin
    s = target_h / max(0.001, max(zs) - min(zs))
    h.scale = (s, s, s)
    h.rotation_euler = (0, 0, rot_z)
    h.location = (x, y, 0.0)
    h.color = (color, color, color, 1)
    return h


def build_homestead_from_layout():
    """Build the homestead set from setplan.ELEMENTS — the same coordinates the
    blueprint was drawn from, so nothing the chapter names gets dropped."""
    import setplan as sp

    def get(key):
        for e in sp.ELEMENTS:
            if key in e[0].lower():
                return e
        return None

    box("dirt", (80, 100, 0.08), (0, -4, -0.04), color=0.45)
    box("county-road", (70, 4.0, 0.02), (0, sp.ROAD_Y, 0.02), color=0.52)
    for i in range(len(sp.TRACK) - 1):
        (x0, y0), (x1, y1) = sp.TRACK[i], sp.TRACK[i + 1]
        length = math.hypot(x1 - x0, y1 - y0)
        seg = box(f"track{i}", (3.0, length + 0.4, 0.02),
                  ((x0 + x1) / 2, (y0 + y1) / 2, 0.01), color=0.58)
        seg.rotation_euler[2] = math.atan2(y1 - y0, x1 - x0) - math.pi / 2

    _, _, x, y, w, h = get("farmhouse")
    mesh = os.environ.get("HOUSE_MESH")
    if mesh and os.path.exists(mesh):  # hybrid: drop a generated house mesh on the coordinate
        place_glb(mesh, x, y, 7.0, math.radians(float(os.environ.get("HOUSE_ROT", "0"))), color=0.62)
    else:
        box("house", (w, h, 6.4), (x, y, 3.2), color=0.62)
        box("house-roof", (w + 1, h + 1, 0.3), (x, y, 6.6), color=0.5)
        for wx in (x - 2.2, x + 2.2):
            box(f"upwin{wx:.1f}", (1.0, 0.1, 1.3), (wx, y + h / 2 + 0.02, 4.6), color=0.2)
        box("door", (1.1, 0.1, 2.2), (x + 0.8, y + h / 2 + 0.02, 1.6), color=0.35)

    _, _, x, y, w, h = get("porch")
    box("porch-deck", (w, h, 0.3), (x, y, 0.55), color=0.55)
    box("porch-roof", (w + 0.6, h + 0.5, 0.18), (x, y, 3.1), color=0.5)
    for px in (x - w / 2 + 0.4, x - w / 6, x + w / 6, x + w / 2 - 0.4):
        cyl(f"post{px:.1f}", 0.09, 2.4, (px, y - h / 2 + 0.15, 1.85), color=0.55)
    for i, dz in enumerate((0.4, 0.27, 0.14)):
        box(f"step{i}", (3.0, 0.4, 0.15), (x, y + h / 2 + 0.2 + i * 0.4, dz), color=0.55)

    _, _, x, y, w, h = get("lean-to")
    for lx in (x - w / 2 + 0.3, x + w / 2 - 0.3):
        for ly in (y - h / 2 + 0.3, y + h / 2 - 0.3):
            cyl(f"lpost{lx:.1f}{ly:.1f}", 0.1, 2.6, (lx, ly, 1.3), color=0.5)
    roof = box("lean-roof", (w + 0.4, h + 0.4, 0.15), (x, y, 2.7), color=0.5)
    roof.rotation_euler[1] = 0.12
    # solid back + side walls so the open front unambiguously faces the yard (+x)
    box("lean-back", (0.14, h + 0.2, 2.4), (x - w / 2, y, 1.2), color=0.55)
    box("lean-side-a", (w * 0.7, 0.12, 2.1), (x - w * 0.15, y - h / 2, 1.05), color=0.55)
    box("lean-side-b", (w * 0.7, 0.12, 2.1), (x - w * 0.15, y + h / 2, 1.05), color=0.55)
    box("saddle-rail", (0.09, h - 0.6, 0.09), (x + w / 2 - 0.5, y, 1.1), color=0.5)
    box("saddle", (0.38, 0.5, 0.3), (x + w / 2 - 0.5, y + 0.4, 1.32), color=0.78)
    load_horse(x - 0.4, y - 0.4, math.radians(70))

    _, _, x, y, r = get("stone well")
    cyl("well", r, 0.95, (x, y, 0.48), color=0.5)
    box("well-roof", (r * 2.6, r * 2.0, 0.12), (x, y, 2.1), color=0.5)
    for wx in (x - r * 0.9, x + r * 0.9):
        cyl(f"wellpost{wx:.1f}", 0.06, 1.6, (wx, y, 1.3), color=0.5)

    _, _, x, y, r = get("chopping block")
    cyl("chop-block", r, 0.55, (x, y, 0.28), color=0.5)
    _, _, x, y, w, h = get("woodpile")
    for i in range(3):
        box(f"wood{i}", (w, h * 0.5, 0.34), (x, y - i * 0.1, 0.2 + i * 0.34), color=0.5)

    _, _, x, y, r = get("wash pot")
    cyl("washpot", r, 0.7, (x, y, 0.6), color=0.4)
    for a in range(3):
        ang = a * 2.0944
        cyl(f"tripod{a}", 0.04, 1.6, (x + 0.55 * math.cos(ang), y + 0.55 * math.sin(ang), 0.7),
            rot=(0.32 * math.sin(ang), -0.32 * math.cos(ang), 0), color=0.3)
    cone("fire", r * 0.9, 0.5, (x, y, 0.25), color=0.85)

    _, _, x, y, r = get("gatepost")
    cyl("gatepost", r, 1.4, (x, y, 0.7), color=0.5)

    rr = random.Random(7)
    for i in range(13):
        tx = sp.XMIN + 1 + i * 2
        sphere(f"tree{i}", rr.uniform(1.6, 2.4), (tx, sp.TREELINE_Y, 3.2), color=0.38)
        cyl(f"trunk{i}", 0.18, 2.6, (tx, sp.TREELINE_Y, 1.2), color=0.35)


# ------------------------------------------------- cameras per frame id
SHOTS = {
    "homestead2": {
        "h2-overhead":  ((0.5, -7.0, 60), (0.5, -7.0, 0), 32, 0.0, 0.0),
        "h2-establish": ((26, 30, 7), (-1, -12, 2.5), 35, 0.1, 0.0),
        "h2-yard":      ((11, 0, 2.2), (-3, -12, 1.4), 28, 0.08, 0.0),
        "h2-leanto":    ((-3, -6, 1.6), (-9.2, -12, 1.2), 35, 0.12, 0.0),
        "c1-riders-come": ((-0.4, -6.0, 1.05), (2.2, 9.5, 1.6), 35, 0.1, 0.04),
        "c1-standoff":    ((6.8, -4.4, 0.95), (-0.5, -9.5, 1.5), 28, 0.08, 0.04),
    },
    # Composition law: aim at the subject, then SHIFT it onto a third
    # (shift_x/+ pushes subject left in frame); quarter angles over wall-parallel;
    # wides carry a foreground element; height is dramatic, not default.
    # Screen direction: homestead — house lives frame-left, the track runs to
    # depth frame-right; hangar — the door lives frame-left of the airplane.
    "hangar": {
        "c3-hangar-wide":  ((8.5, -3.5, 1.45), (-2.5, -9.0, 1.2), 24, 0.12, -0.04),
        "c3-family":       ((4.9, -3.0, 1.35), (2.0, -5.2, 1.1), 35, 0.1, 0.0),
        "c3-scale-cu":     ((2.4, -4.4, 0.95), (3.6, -6.1, 0.7), 50, -0.12, 0.0),
        "c3-scale-duffel": ((0.8, -3.6, 1.5), (3.4, -6.1, 0.7), 35, -0.1, 0.0),
        "c3-ray-doctor":   ((2.0, -4.2, 1.55), (4.2, -6.6, 1.3), 50, 0.15, 0.0),
        "c3-frame-set":    ((-9.0, -5.8, 0.85), (-11.5, -8.4, 0.35), 35, 0.1, 0.0),
        "c3-toaster":      ((-10.0, -6.0, 0.6), (-11.55, -7.3, 0.25), 50, -0.1, 0.0),
        "c3-curb-row":     ((-8.8, -5.2, 0.9), (-11.6, -9.0, 0.35), 35, -0.1, 0.0),
        "c3-phone":        ((9.6, -4.6, 1.45), (11.9, -6.3, 1.45), 35, 0.12, 0.0),
        "c3-hangup":       ((10.2, -7.4, 1.4), (11.9, -6.1, 1.45), 50, -0.12, 0.0),
        "c3-family-wait":  ((2.2, -12.8, 1.25), (0.0, -7.2, 1.2), 35, 0.12, 0.0),
        "c3-wing-count":   ((-5.4, -4.2, 1.5), (-0.6, -8.2, 1.5), 35, 0.12, 0.0),
        "c3-recount":      ((-3.6, -5.8, 1.75), (-0.9, -7.9, 1.5), 50, -0.1, 0.0),
        "c3-coffee-can":   ((10.0, -7.0, 1.2), (11.35, -7.7, 1.05), 50, -0.13, 0.0),
        "c3-kids-shirts":  ((0.6, -12.0, 1.2), (-1.0, -8.4, 1.1), 35, 0.1, 0.0),
        "c3-doctor-look":  ((4.4, -7.2, 1.65), (0.2, -9.2, 1.25), 35, 0.12, 0.0),
        "c3-loading":      ((4.2, -13.0, 1.3), (-1.6, -9.2, 1.4), 28, 0.1, 0.0),
        "c3-walkaround":   ((0.2, -3.2, 1.35), (-2.2, -5.6, 1.3), 35, -0.12, 0.0),
        "c3-get-in":       ((1.8, -11.2, 1.35), (-1.4, -10.0, 1.3), 35, 0.1, 0.0),
        "c3-hangar-door-moon": ((-7.0, 4.0, 1.2), (2.5, -4.5, 1.6), 28, 0.12, 0.05),
        "c3-curb-row-moon": ((-9.0, -5.6, 0.8), (-11.6, -8.6, 0.35), 35, -0.1, 0.0),
        "c3-reverse-demo": ((-2.0, -15.5, 0.9), (-2.0, 2.0, 2.2), 28, 0.0, 0.08),
    },
    "homestead": {
        "c1-establish":   ((26, 38, 7), (-2, -12, 2.5), 35, 0.1, 0.0),
        "c1-track":       ((2.2, -1.5, 1.5), (0.6, 45, 1.0), 35, -0.08, 0.05),
        "c1-yard-axe":    ((5.8, -5.0, 1.1), (2.6, -8.4, 1.0), 35, -0.12, 0.0),
        "c1-nia-porch":   ((2.6, -11.0, 1.5), (-2.2, -11.6, 1.4), 35, 0.12, 0.0),
        "c1-nia-quip":    ((4.8, -8.0, 1.3), (0.2, -10.8, 1.1), 35, 0.1, 0.0),
        "c1-step-sit":    ((2.8, -9.2, 1.0), (-0.2, -10.8, 0.85), 35, 0.12, 0.0),
        "c1-road-look":   ((0.2, -10.4, 1.65), (1.2, 40, 1.2), 35, 0.0, 0.06),
        "c1-rules-road":  ((4.4, 7.5, 1.4), (1.2, 40, 1.2), 50, -0.1, 0.04),
        "c1-nia-chin":    ((1.4, -9.0, 1.25), (0.0, -10.5, 1.1), 50, 0.13, 0.0),
        "c1-dust":        ((1.0, -5.0, 1.7), (1.0, 56, 1.6), 85, 0.0, 0.08),
        "c1-riders-far":  ((1.0, -5.0, 1.6), (1.0, 50, 1.3), 120, 0.0, 0.05),
        "c1-riders-come": ((-0.4, -6.0, 1.05), (2.2, 9.5, 1.6), 35, 0.1, 0.04),
        "c1-leader":      ((1.2, -10.0, 1.3), (2.8, -7.0, 1.8), 35, -0.12, 0.05),
        "c1-standoff":    ((6.8, -4.4, 0.95), (-0.5, -9.5, 1.5), 28, 0.08, 0.04),
        "c1-leader-talk": ((0.4, -8.8, 1.35), (3.0, -6.4, 1.85), 50, -0.12, 0.05),
        "c1-three-watch": ((-0.6, -7.6, 1.3), (2.8, 1.5, 1.7), 35, 0.1, 0.04),
        "c1-survey":      ((2.4, -7.2, 2.3), (-6.5, -11.0, 0.9), 24, 0.0, -0.04),
        "c1-dismount":    ((4.6, -5.0, 1.35), (1.6, -7.8, 1.1), 35, -0.1, 0.0),
        "c1-block":       ((3.4, -10.9, 1.35), (0.2, -9.4, 1.4), 50, 0.12, 0.0),
        "c1-glance-back": ((-1.0, -9.4, 1.4), (3.0, 1.0, 1.6), 35, -0.1, 0.03),
        "c1-hands-show":  ((-0.6, 2.5, 1.3), (0.7, -8.2, 1.5), 35, 0.1, 0.0),
        "c1-mount-up":    ((5.0, -5.8, 1.3), (1.8, -6.6, 1.3), 35, -0.1, 0.0),
        "c1-turning":     ((8.2, -2.6, 1.6), (0.2, -7.2, 1.2), 24, 0.08, 0.0),
        "c1-young-still": ((-1.2, -3.8, 1.45), (-5.4, -7.4, 1.35), 50, 0.12, 0.0),
        "c1-bay":         ((-5.0, -7.6, 1.3), (-9.6, -12.2, 1.05), 35, 0.1, 0.0),
        "c1-saddle":      ((-6.2, -9.2, 1.05), (-7.6, -10.1, 1.28), 50, -0.1, 0.0),
        "c1-young-point": ((-0.8, -4.6, 1.35), (-2.9, -6.0, 1.5), 50, 0.12, 0.0),
        "c1-shot":        ((6.4, -11.4, 1.2), (-1.4, -5.6, 1.4), 28, 0.1, 0.04),
        "c1-windows-fire": ((3.2, -8.0, 0.8), (-1.5, -13.5, 4.8), 24, 0.1, 0.1),
        "c1-yard-chaos":  ((6.8, -3.0, 2.2), (-0.4, -8.4, 1.0), 24, 0.08, 0.0),
        "c1-down":        ((3.4, -4.4, 1.3), (-1.6, -7.0, 0.35), 35, 0.1, 0.0),
        "c1-flee":        ((2.6, -8.0, 1.5), (0.8, 42, 0.8), 35, -0.08, 0.06),
        "c1-pistol-up":   ((-2.6, -5.2, 1.0), (1.6, -8.6, 1.6), 35, 0.12, 0.04),
    },
    "bonusroom": {
        "c2-bonus-brad":  ((-2.6, 2.1, 1.35), (2.2, -1.0, 1.3), 24, 0.1, 0.0),
        "c2-desmond-window": ((0.4, 1.9, 1.5), (2.9, -0.4, 1.35), 35, 0.12, 0.0),
        "c2-couple-window": ((0.7, 2.15, 1.5), (2.9, -1.0, 1.35), 35, 0.1, 0.0),
        "c2-brad-hall":   ((2.0, 1.6, 1.5), (-2.0, -2.5, 1.55), 35, -0.1, 0.0),
        "c2-culdesac":    ((2.96, 0.0, 1.9), (24, -16, -4.0), 28, 0.0, -0.1),
        "c2-house-ext":   ((14, 13, 1.4), (-1, 1, 2.2), 35, 0.12, 0.05),
    },
    "fenceyard": {
        "c2-street-kids": ((-7.5, 9.6, 1.45), (4.5, 2.5, 1.1), 35, 0.1, 0.0),
        "c2-yard-kids":   ((-5.5, 7.5, 1.9), (3.5, -6.5, 0.7), 28, 0.1, 0.0),
        "c2-min":         ((3.4, -1.6, 1.25), (-0.4, -5.4, 1.0), 50, 0.12, 0.0),
        "c2-nia-fence":   ((2.6, 1.6, 1.15), (0.6, -2.6, 1.0), 50, -0.13, 0.0),
        "c2-kids-stop":   ((-0.4, -4.9, 1.25), (2.0, -0.4, 1.2), 35, 0.1, 0.03),
        "c2-mother":      ((1.8, 2.4, 1.2), (8.2, -10.2, 1.1), 50, 0.1, 0.0),
        "c2-between":     ((-1.0, 6.0, 2.0), (5.0, -4.0, 0.8), 28, 0.1, 0.0),
        "c2-gate":        ((7.6, 2.0, 1.15), (6.5, 0.0, 0.85), 50, -0.1, 0.0),
        "c2-min-gate":    ((4.4, 2.8, 1.35), (6.7, 0.2, 1.15), 35, -0.12, 0.0),
        "c2-min-approach": ((-3.0, 7.4, 1.35), (3.4, 3.2, 1.15), 28, 0.1, 0.0),
        "c2-two-walk":    ((1.0, 9.8, 1.45), (14.5, 8.2, 0.95), 35, 0.1, 0.03),
    },
    "strip": {
        "c3-strip-dark":  ((24, 22, 5.5), (-4, -14, 0.8), 28, 0.1, 0.0),
        "c3-fires":       ((8.0, -16.0, 1.3), (-95, 42, 8.0), 85, -0.1, 0.06),
        "c3-fires-cu":    ((8.0, -16.0, 1.5), (-95, 42, 9.0), 135, 0.0, 0.05),
        "c3-flare":       ((-6.5, -44, 0.8), (0.5, -15, 1.5), 50, 0.1, 0.05),
        "c3-rollout":     ((10.5, -28, 1.2), (-0.5, -7.5, 1.2), 35, 0.1, 0.04),
        "c3-prop-frozen": ((1.4, -5.8, 1.2), (-0.1, -4.3, 1.3), 50, -0.12, 0.05),
        "c3-chaining":    ((3.4, 2.8, 1.0), (1.4, 0.4, 0.7), 35, -0.1, 0.0),
        "c3-chain-still": ((2.8, 2.2, 1.2), (1.2, 0.0, 1.0), 50, -0.12, 0.0),
        "c3-cargo-door":  ((-2.6, 3.0, 1.05), (-0.6, 1.5, 1.1), 50, 0.1, 0.0),
        "c3-dog-drop":    ((-3.0, 3.4, 0.7), (-0.7, 1.6, 0.4), 35, 0.1, 0.0),
        "c3-ray-dog-stare": ((3.8, 0.6, 1.05), (0.8, 1.2, 0.6), 35, 0.12, 0.0),
        "c3-moon-strip":  ((22, -16, 3.8), (-1, -1, 1.2), 28, 0.1, 0.05),
        "c3-two-night":   ((0.8, -4.2, 0.85), (-1.5, 28, 2.0), 28, 0.0, 0.15),
    },
    "betos": {
        "c3-landing-betos": ((22, -12, 1.2), (4, 3, 1.4), 50, 0.1, 0.05),
        "c3-drums-flash": ((3.0, -2.8, 1.25), (-0.2, -1.2, 1.45), 35, 0.1, 0.0),
        "c3-beto-count":  ((1.7, -4.4, 1.05), (-0.4, -2.2, 1.0), 50, 0.1, 0.0),
        "c3-beto-ray":    ((-3.0, -4.0, 1.3), (0.5, -3.2, 1.15), 35, -0.1, 0.0),
        "c3-pumping":     ((4.0, -2.8, 1.2), (0.2, -1.6, 1.3), 35, 0.12, 0.04),
        "c3-wingtip":     ((18.0, 0.5, 1.3), (12.2, 6.2, 1.3), 35, 0.12, 0.0),
        "c3-truck-load":  ((8.5, 4.5, 1.1), (0.0, -0.5, 1.2), 35, 0.1, 0.0),
        "c3-girl-dog-dirt": ((5.0, -4.6, 0.8), (1.8, -2.0, 0.4), 35, 0.1, 0.0),
        "c3-doctor-wing": ((8.2, 1.0, 1.35), (12.2, 5.8, 1.4), 35, -0.12, 0.0),
        "c3-wing-two":    ((10.5, 10.0, 1.3), (12.8, 5.2, 1.4), 50, 0.1, 0.0),
        "c3-takeoff-night": ((20, -18, 1.5), (-25, 30, 6), 28, 0.0, 0.1),
        "c3-flashback-ramp": ((2.4, -6.0, 1.25), (11.0, 4.8, 1.1), 28, 0.12, 0.0),
    },
    "pharmacy": {
        "n3-pharm-wide":   ((5.3, -0.5, 2.2), (-2.9, -7.3, 1.0), 24, 0.12, -0.03),
        "n3-screen-turn":  ((0.6, -5.0, 1.5), (-2.9, -6.9, 1.3), 35, 0.12, 0.0),
        "n3-register":     ((1.2, -5.2, 1.4), (-0.7, -6.8, 1.2), 35, -0.1, 0.0),
        "n3-door-watch":   ((-1.4, -6.2, 1.5), (3.4, 0.4, 1.3), 35, 0.12, 0.0),
        "n3-willcall":     ((1.0, -7.0, 1.5), (2.7, -8.8, 2.0), 35, -0.1, 0.05),
        "n3-radio":        ((-3.9, -7.6, 1.35), (-4.65, -8.78, 1.32), 50, -0.12, 0.0),
        "n3-lot-heat":     ((-1.0, -1.2, 1.55), (0.5, 12.0, 0.8), 35, 0.1, 0.06),
        "n3-mehta-enters": ((-2.2, -6.0, 1.45), (3.4, 0.2, 1.4), 28, 0.14, 0.0),
        "n3-bike-dog":     ((1.6, -2.6, 1.25), (4.35, 3.3, 0.8), 35, -0.12, 0.0),
        "n3-counter-word": ((-4.4, -5.6, 1.6), (-1.5, -6.4, 1.05), 35, 0.1, -0.04),
        "n3-door-look":    ((1.0, -3.4, 1.5), (3.5, 0.2, 1.35), 35, -0.12, 0.0),
        "n3-lot-survey":   ((3.4, -0.3, 1.6), (4.5, 8.0, 0.7), 28, 0.1, 0.04),
        "n3-sign-flip":    ((2.6, -1.0, 1.75), (3.05, -0.05, 1.9), 85, -0.1, 0.0),
        "n3-two-memorize": ((-0.5, 0.2, 1.5), (-0.6, -6.0, 1.3), 28, 0.1, 0.0),
        "n3-vitamins":     ((1.2, -5.6, 1.3), (1.2, -0.8, 1.0), 35, 0.1, 0.0),
        "n3-aisle-walk":   ((-2.2, -6.4, 1.55), (-2.2, 0.0, 1.1), 28, -0.1, 0.0),
        "n3-bell-leave":   ((0.4, -4.4, 1.5), (3.5, 0.3, 1.5), 35, 0.12, 0.03),
        "n3-bike-wobble":  ((2.2, -2.0, 1.4), (6.5, 9.0, 0.7), 35, 0.1, 0.04),
        "n3-lights-buzz":  ((4.2, -1.4, 2.0), (-2.4, -7.2, 1.1), 24, 0.12, -0.03),
    },
    "nkitchen": {
        "n3-hoa-kitchen":  ((1.9, 1.4, 1.5), (-1.2, -1.7, 1.2), 35, 0.12, 0.0),
        "n3-tap":          ((-1.0, -0.9, 1.25), (-1.82, -1.95, 1.0), 50, -0.1, 0.0),
        "n3-hoa-hangup":   ((1.5, 0.2, 1.45), (-0.9, -1.8, 1.15), 35, 0.1, 0.0),
        "n3-dinner-wide":  ((-1.9, 1.7, 1.45), (0.5, 0.2, 0.85), 28, 0.1, 0.0),
        "n3-phone-speaker": ((-0.4, 1.3, 1.0), (0.52, 0.68, 0.9), 50, -0.1, 0.0),
        "n3-spoon":        ((-0.6, 1.1, 1.05), (0.1, 0.45, 0.82), 85, 0.1, 0.0),
    },
    "cockpit": {
        "c3-cockpit-doctor": ((0.55, -1.7, 1.25), (-0.3, 0.5, 1.1), 28, 0.1, 0.0),
        "c3-ray-profile": ((0.9, -0.25, 1.22), (-0.5, -0.45, 1.15), 50, 0.1, 0.0),
        "c3-sight-tube":  ((0.38, -0.2, 0.95), (0.67, 0.12, 1.06), 85, -0.1, 0.0),
        "c3-stencil":     ((0.12, -0.15, 1.0), (0.46, 0.43, 1.27), 85, -0.1, 0.05),
        "c3-thumb":       ((0.18, -0.25, 1.08), (0.46, 0.43, 1.27), 100, -0.08, 0.04),
        "c3-halftanks":   ((-0.27, -0.8, 1.16), (-0.27, 0.48, 1.12), 85, -0.1, 0.0),
        "c3-needles":     ((-0.09, -0.75, 1.12), (-0.09, 0.49, 1.12), 85, 0.1, 0.0),
        "c3-panel-ghost": ((0.22, -0.45, 1.22), (0.42, 0.48, 1.2), 85, -0.1, 0.0),
        "c3-panel-dark":  ((0.05, -0.75, 1.28), (-0.05, 0.5, 1.08), 50, 0.08, 0.0),
        "c3-power-back":  ((0.3, -0.75, 1.0), (-0.06, 0.28, 0.95), 50, 0.1, 0.0),
        "c3-mixture-hand": ((0.32, -0.55, 1.0), (0.07, 0.29, 0.96), 85, 0.08, 0.0),
        "c3-shutdown-hand": ((0.28, -0.65, 0.9), (-0.02, -0.06, 0.66), 85, 0.1, 0.0),
        "c3-groundspeed": ((-0.2, -0.7, 1.0), (-0.2, 0.5, 0.96), 85, 0.08, 0.0),
        "c3-hands-wheel": ((0.0, -1.35, 1.3), (0.0, 0.25, 1.02), 35, 0.0, 0.05),
        "c3-windscreen-dark": ((0.0, -0.85, 1.32), (0.0, 4.0, 1.6), 28, 0.0, 0.18),
        "c3-dark-ahead":  ((0.05, -0.85, 1.3), (0.0, 4.0, 1.4), 35, 0.0, 0.15),
        "c3-cockpit-night": ((0.55, -1.5, 1.15), (-0.35, 0.45, 1.05), 28, -0.1, 0.05),
        "c3-ray-dark-cu": ((0.48, -1.05, 1.28), (-0.36, -0.32, 1.18), 50, 0.1, 0.0),
    },
}

BUILDERS = {
    "homestead2": build_homestead_from_layout,
    "pharmacy": build_pharmacy,
    "nkitchen": build_nkitchen,
    "hangar": build_hangar,
    "homestead": build_homestead,
    "bonusroom": build_bonusroom,
    "fenceyard": build_fenceyard,
    "strip": build_strip,
    "betos": build_betos,
    "cockpit": build_cockpit,
}


def render_set(setname):
    reset()
    BUILDERS[setname]()
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "OBJECT"
    sc.display.shading.show_shadows = True
    sc.display.shading.show_cavity = True
    sc.display.shading.cavity_type = "BOTH"
    world = bpy.data.worlds.new("w")
    world.color = (0.18, 0.18, 0.18)
    sc.world = world
    sc.render.resolution_x = 1376
    sc.render.resolution_y = 768
    sc.render.image_settings.file_format = "PNG"
    os.makedirs(OUTDIR, exist_ok=True)
    for fid, spec in SHOTS[setname].items():
        loc, look, lens = spec[0], spec[1], spec[2]
        shift_x = spec[3] if len(spec) > 3 else 0.0
        shift_y = spec[4] if len(spec) > 4 else 0.0
        cam = bpy.data.cameras.new(fid)
        cam.lens = lens
        cam.clip_start = 0.02
        cam.shift_x = shift_x
        cam.shift_y = shift_y
        ob = bpy.data.objects.new(fid, cam)
        bpy.context.collection.objects.link(ob)
        ob.location = loc
        ob.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.camera = ob
        sc.render.filepath = os.path.join(OUTDIR, f"{fid}.png")
        bpy.ops.render.render(write_still=True)
        print("clay:", sc.render.filepath)


if __name__ == "__main__":
    sets = list(BUILDERS) if SET == "all" else [SET]
    for s in sets:
        render_set(s)
