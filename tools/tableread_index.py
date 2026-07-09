#!/usr/bin/env python
"""Generate index.html for the table-read directory (served over Tailscale).

Newest render per scene up top, full history below. Dark, ink-flavored.
"""
from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

TR = sys.argv[1] if len(sys.argv) > 1 else "stories/four-olds/tableread"

vids = [f for f in os.listdir(TR) if f.endswith(".mp4")]
by_scene: dict[str, list[str]] = defaultdict(list)
for f in vids:
    m = re.match(r"TABLEREAD_([^_]+(?:-open)?)", f)
    key = m.group(1) if m else "misc"
    by_scene[key].append(f)
for k in by_scene:
    by_scene[k].sort(reverse=True)  # timestamped names -> newest first

order = sorted(by_scene.keys())

rows = []
for k in order:
    latest, *old = by_scene[k]
    rows.append(f"""
  <section>
    <h2>{k}</h2>
    <video controls preload="metadata" src="{latest}"></video>
    <p class="f">{latest}</p>
    {"".join(f'<p class="old"><a href="{o}">{o}</a></p>' for o in old)}
  </section>""")

html = f"""<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>THE FOUR OLDS — table read</title>
<style>
 body {{ background:#111; color:#eee; font-family:'Courier New',monospace;
        max-width:960px; margin:2rem auto; padding:0 1rem; }}
 h1 {{ letter-spacing:.2em; border-bottom:2px solid #eee; padding-bottom:.5rem; }}
 h2 {{ margin:2.2rem 0 .4rem; }}
 video {{ width:100%; background:#000; border:1px solid #333; }}
 .f {{ color:#888; font-size:.75rem; margin:.3rem 0 0; }}
 .old {{ color:#666; font-size:.7rem; margin:.15rem 0 0; }}
 .old a {{ color:#8a8; }}
</style>
<h1>THE FOUR OLDS — TABLE READ</h1>
<p class="f">graphic-novel read · newest render per scene · older takes below each</p>
{"".join(rows)}
"""
open(os.path.join(TR, "index.html"), "w").write(html)
print(f"index.html: {len(vids)} videos, {len(order)} scenes")
