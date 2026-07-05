"""Pure-Blender storyboard test: can Freestyle + paper tone replace Gemini?

Rebuilds the hangar blockout, adds posed mannequin figures where the cast
stands, and renders the wide shot as NPR line art — sketchy Freestyle strokes
over paper tone, EEVEE flat shading. The honest bake-off frame against the
Gemini house style.

    Blender --background --python examples/civilwar_npr_test.py
"""

import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
import civilwar_set3d as set3d  # noqa: E402

OUT = "stories/civil-war/storyboard/clay/test-npr-hangar-wide.png"


def figure(name, loc, height=1.7, face_yaw=0.0, color=0.35):
    """A posed mannequin: head, torso, two legs, two arms. Reads as a person
    standing; does not act — which is the point of the test."""
    s = height / 1.7
    x, y, z = loc
    set3d.cyl(f"{name}-torso", 0.16 * s, 0.62 * s, (x, y, z + 1.12 * s),
              color=color)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.115 * s,
                                         location=(x, y, z + 1.56 * s))
    head = bpy.context.object
    head.name = f"{name}-head"
    head.color = (color, color, color, 1)
    for sx in (-1, 1):
        set3d.cyl(f"{name}-leg{sx}", 0.06 * s, 0.78 * s,
                  (x + sx * 0.09 * s, y, z + 0.4 * s), color=color)
        set3d.cyl(f"{name}-arm{sx}", 0.045 * s, 0.55 * s,
                  (x + sx * 0.24 * s, y, z + 1.1 * s),
                  rot=(0, sx * 0.12, 0), color=color)
    for o in bpy.data.objects:
        if o.name.startswith(name):
            o.rotation_euler[2] += face_yaw


def npr_setup(sc):
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.use_freestyle = True
    sc.render.line_thickness = 1.4
    vl = sc.view_layers[0]
    vl.use_freestyle = True
    ls = vl.freestyle_settings.linesets.new("sketch")
    style = bpy.data.linestyles.new("sketch-style")
    ls.linestyle = style
    style.color = (0.12, 0.11, 0.10)
    style.thickness = 2.4
    # sketchy hand: noise + thickness variation along strokes
    m = style.geometry_modifiers.new("wobble", "PERLIN_NOISE_1D")
    m.amplitude = 1.6
    m.frequency = 12
    tm = style.thickness_modifiers.new("taper", "ALONG_STROKE")
    tm.value_min, tm.value_max = 0.6, 2.6

    # paper world + soft key light
    world = bpy.data.worlds.new("paper")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.93, 0.90, 0.83, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    sc.world = world
    bpy.ops.object.light_add(type="SUN", location=(6, 2, 8))
    sun = bpy.context.object
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(55), math.radians(-12), math.radians(35))

    # matte near-paper materials so tone comes from light + lines
    mat = bpy.data.materials.new("clay-paper")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.82, 0.79, 0.72, 1)
    bsdf.inputs["Roughness"].default_value = 1.0
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(mat)


def main():
    set3d.reset()
    set3d.build_hangar()
    # the cast as mannequins: family of three + the pilot at the scale
    figure("doctor", (2.0, -4.6, 0), 1.74, face_yaw=2.6)
    figure("wife", (1.4, -4.1, 0), 1.62, face_yaw=2.8)
    figure("girl", (1.0, -4.7, 0), 1.18, face_yaw=2.4)
    figure("ray", (4.4, -6.6, 0), 1.78, face_yaw=-0.6)

    sc = bpy.context.scene
    npr_setup(sc)
    sc.render.resolution_x = 1376
    sc.render.resolution_y = 768
    sc.render.image_settings.file_format = "PNG"

    loc, look, lens = (7.5, -2.0, 1.8), (-3.0, -10.0, 1.3), 24
    cam = bpy.data.cameras.new("wide")
    cam.lens = lens
    ob = bpy.data.objects.new("wide", cam)
    bpy.context.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = ob
    sc.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("npr:", OUT)


main()
