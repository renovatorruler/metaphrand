"""Last multiview lever: feed Tripo ONLY front + back (the two clean valley-cut panels),
dropping the profile views that — if even a few degrees off true 90° — corrupt the solve
and make it symmetrize the front face onto the back. -> stories/amal/tripo3d/ratan_fb_mv/
"""
import os, json, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import tripo

SRC = "/Users/dusty/dev/brehon-law/stories/amal/tripo3d/ratan3_mv"
OD = "/Users/dusty/dev/brehon-law/stories/amal/tripo3d/ratan_fb_mv"
os.makedirs(OD, exist_ok=True)

print("balance", tripo.balance(), flush=True)
f = tripo.upload(f"{SRC}/_mvc_front.png")
b = tripo.upload(f"{SRC}/_mvc_back.png")
print("uploaded front + back", flush=True)
tid = tripo.multiview_to_model({"front": f, "back": b})   # left/right omitted
print("task", tid, flush=True)
d = tripo.wait(tid)
json.dump(d, open(f"{OD}/ratan_fb_task.json", "w"), indent=1)
print("SAVED", tripo.fetch_outputs(d, OD, stem="ratan_fb"), flush=True)
print("DONE", flush=True)
