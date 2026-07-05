"""Split a Gemini 4-view sheet (front | left | back | right, evenly spaced) into four
panels, feed them to Tripo multiview_to_model, and download the (much better) 360 model.

  python tripo_multiview.py <multiview.png> <name>   ->  stories/amal/tripo3d/<name>_mv/
"""
import sys, os, json
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from PIL import Image
from cinema import tripo

OUT = "/Users/dusty/dev/brehon-law/stories/amal/tripo3d"


def split4(path, outdir, canvas=1024, fill=0.86, nviews=4):
    """Cut a row of N views at the N-1 lowest-ink VALLEYS between them (robust to uneven
    gaps / bunched views; the cut goes through the thinnest seam, so nothing is clipped).
    Each view kept whole, rescaled to a common height, centred on a white square."""
    import numpy as np
    im = Image.open(path).convert("RGB"); W, H = im.size
    ink = (np.asarray(im.convert("L")) < 238).mean(axis=0)        # ink fraction per column
    cols = np.where(ink > 0.02)[0]
    x_lo, x_hi = int(cols.min()), int(cols.max())
    sep = int((x_hi - x_lo) / (nviews * 1.8))                     # min spacing between cuts
    work = np.full(W, np.inf); work[x_lo + sep:x_hi - sep] = ink[x_lo + sep:x_hi - sep]
    cuts = []
    for _ in range(nviews - 1):                                   # greedily pick the lowest valleys
        c = int(np.argmin(work)); cuts.append(c)
        work[max(0, c - sep):c + sep] = np.inf
    bounds = [x_lo] + sorted(cuts) + [x_hi + 1]
    print(f"  cut at {sorted(cuts)} -> {nviews} views", flush=True)
    names = ["front", "left", "back", "right"]; out = {}
    for i in range(nviews):
        view = im.crop((bounds[i], 0, bounds[i + 1], H))
        bb = view.convert("L").point(lambda p: 255 if p < 238 else 0).getbbox()
        if bb:
            view = view.crop(bb)                                  # tight to full content, no clip
        scale = (canvas * fill) / view.height
        nw, nh = max(1, int(view.width * scale)), max(1, int(view.height * scale))
        if nw > canvas:
            nh = int(nh * canvas / nw); nw = canvas
        view = view.resize((nw, nh))
        cv = Image.new("RGB", (canvas, canvas), (255, 255, 255))
        cv.paste(view, ((canvas - nw) // 2, (canvas - nh) // 2))
        nm = names[i] if i < len(names) else str(i)
        p = f"{outdir}/_mvc_{nm}.png"; cv.save(p); out[nm] = p
    return out


def main():
    img, name = sys.argv[1], sys.argv[2]
    outdir = f"{OUT}/{name}_mv"; os.makedirs(outdir, exist_ok=True)
    paths = split4(img, outdir)
    print("balance", tripo.balance(), flush=True)
    toks = {n: tripo.upload(p) for n, p in paths.items()}
    print("uploaded", list(toks.keys()), flush=True)
    tid = tripo.multiview_to_model(toks)
    print("task_id", tid, flush=True)
    d = tripo.wait(tid)
    json.dump(d, open(f"{outdir}/{name}_task.json", "w"), indent=1)
    saved = tripo.fetch_outputs(d, outdir, stem=name)
    print("SAVED", json.dumps(saved, indent=1), flush=True)
    print("DONE", name, flush=True)


if __name__ == "__main__":
    main()
