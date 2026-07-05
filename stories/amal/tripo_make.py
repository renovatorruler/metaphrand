"""Make a Tripo 3D asset from an image (or poll an existing task) and download it.

  python tripo_make.py <image.png> <name>        # upload + task + wait + download
  python tripo_make.py --task <task_id> <name>   # poll an existing task + download

-> stories/amal/tripo3d/<name>/  (glb model(s), preview, task json)
"""
import sys, os, json
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import tripo

OUT = "/Users/dusty/dev/brehon-law/stories/amal/tripo3d"


def main():
    a = sys.argv[1:]
    if a and a[0] == "--task":
        tid, name = a[1], a[2]
    else:
        img, name = a[0], a[1]
        print("balance:", tripo.balance(), flush=True)
        print("upload + task:", img, flush=True)
        tid = tripo.from_image(img)
        print("task_id:", tid, flush=True)
    d = tripo.wait(tid)
    outdir = f"{OUT}/{name}"
    os.makedirs(outdir, exist_ok=True)
    json.dump(d, open(f"{outdir}/{name}_task.json", "w"), indent=1)
    saved = tripo.fetch_outputs(d, outdir, stem=name)
    print("SAVED:", json.dumps(saved, indent=1), flush=True)
    print("DONE", name, flush=True)


if __name__ == "__main__":
    main()
