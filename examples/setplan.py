"""CH1 homestead — the SET as DATA (layout), plus a top-down schematic renderer.

The set is a layout, not a hand-built render: every element has a world position
and footprint; the track and county road are paths. Code draws a clean plan for
approval and (next) builds the Blender set + cameras from this same data, so
nothing the chapter names gets dropped. World convention matches
civilwar_set3d: the house sits at -Y; the track runs +Y out to the county road
(so +Y = "toward the road / where riders come from and flee to").

    python -m examples.setplan          # render the schematic
"""
import os

# label, kind(rect|circ), x, y, (w,h) or r   — world metres
ELEMENTS = [
    ("Farmhouse (2-story, 2 upstairs windows)", "rect", 0.0, -16.0, 9.0, 8.0),
    ("Front porch", "rect", 0.0, -11.2, 8.0, 2.4),
    ("Lean-to  ·  bay horse + silver saddle on rail", "rect", -9.2, -12.0, 4.4, 3.6),
    ("Stone well", "circ", -6.0, -6.5, 1.0),
    ("Chopping block + axe", "circ", 3.4, -7.5, 0.6),
    ("Woodpile", "rect", 4.9, -8.6, 1.4, 1.9),
    ("Iron wash pot (over cookfire)", "circ", 6.4, -12.6, 0.9),
    ("Gatepost", "circ", 2.6, 2.0, 0.4),
]
TRACK = [(0.4, -10.0), (1.6, 2.0), (1.6, 12.0)]   # porch -> gatepost -> county road
ROAD_Y, TREELINE_Y = 12.0, -21.0
XMIN, XMAX, YMIN, YMAX = -14.0, 11.5, -23.0, 14.5
SCALE, MARGIN = 42, 90
CREAM, INK, TAN, GRAY, GREEN = (244, 240, 230), (40, 38, 34), (196, 170, 120), (150, 150, 150), (70, 96, 70)


def _font(sz):
    from PIL import ImageFont
    try:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/Georgia.ttf", sz)
    except OSError:
        return ImageFont.load_default()


def render(out="stories/civil-war/setdesign/ch1-homestead-LAYOUT.png"):
    from PIL import Image, ImageDraw
    W = int((XMAX - XMIN) * SCALE) + 2 * MARGIN
    H = int((YMAX - YMIN) * SCALE) + 2 * MARGIN
    img = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(img)

    def px(x): return MARGIN + (x - XMIN) * SCALE
    def py(y): return MARGIN + (YMAX - y) * SCALE

    # county road band (far out) + its meaning
    d.rectangle([px(XMIN), py(ROAD_Y + 1.4), px(XMAX), py(ROAD_Y - 1.4)], fill=(210, 205, 195))
    for x in range(int(XMIN), int(XMAX), 2):
        d.line([px(x + 0.4), py(ROAD_Y), px(x + 1.2), py(ROAD_Y)], fill=(170, 165, 155), width=4)
    d.text((px(XMIN) + 8, py(ROAD_Y + 1.4) - 30), "COUNTY ROAD  —  riders ride IN from here · routed riders flee back to it",
           font=_font(26), fill=INK)

    # tree line
    for x in range(int(XMIN) + 1, int(XMAX), 2):
        d.ellipse([px(x) - 16, py(TREELINE_Y) - 16, px(x) + 16, py(TREELINE_Y) + 16], fill=GREEN)
    d.text((px(XMIN) + 6, py(TREELINE_Y) - 46), "tree line  (“nobody past the tree line alone”)", font=_font(22), fill=GREEN)

    # the track
    pts = [(px(x), py(y)) for x, y in TRACK]
    d.line(pts, fill=TAN, width=int(3.2 * SCALE / 4))
    # flow arrows along the track
    d.polygon([(px(1.6) - 12, py(7)), (px(1.6) + 12, py(7)), (px(1.6), py(7) + 22)], fill=INK)   # in (down)
    d.polygon([(px(1.6) - 12, py(-2.5)), (px(1.6) + 12, py(-2.5)), (px(1.6), py(-2.5) - 22)], fill=(120, 60, 60))  # flee (up)

    # elements
    lf = _font(23)
    for label, kind, x, y, *dim in ELEMENTS:
        if kind == "rect":
            w, h = dim
            d.rectangle([px(x - w / 2), py(y + h / 2), px(x + w / 2), py(y - h / 2)],
                        fill=(225, 218, 205), outline=INK, width=3)
        else:
            r = dim[0]
            d.ellipse([px(x - r), py(y + r), px(x + r), py(y - r)],
                      fill=(225, 218, 205), outline=INK, width=3)
        d.text((px(x) + 14, py(y) - 12), label, font=lf, fill=INK)

    # north arrow + scale bar
    nx, ny = W - 130, MARGIN + 30
    d.line([nx, ny + 60, nx, ny], fill=INK, width=4)
    d.polygon([(nx - 11, ny + 14), (nx + 11, ny + 14), (nx, ny - 6)], fill=INK)
    d.text((nx - 78, ny + 18), "toward road", font=_font(18), fill=INK)
    sb_y = H - MARGIN + 18
    d.line([px(-13), sb_y, px(-13) + 5 * SCALE, sb_y], fill=INK, width=4)
    d.text((px(-13), sb_y + 6), "5 m", font=_font(20), fill=INK)
    d.text((MARGIN, 28), "CHAPTER ONE  ·  HOMESTEAD  ·  SET LAYOUT (top-down, from the text)", font=_font(30), fill=INK)

    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("saved", out, img.size)
    return out


if __name__ == "__main__":
    render()
