"""cinema.audio — story-agnostic multi-voice audio drama.

    scenes -> performance JSON -> ElevenLabs v3 dialogue -> stitched mp3 + timing manifest

Each scene is rendered as ONE continuous dialogue take (so the cast plays off each other,
no per-line voice drift); takes are digest-cached so re-runs only synth what changed; a
manifest (group -> scene, duration) is written for the video assembler.

Generalizes heir_elevenlabs (single-narrator films) and free_ross_audio (multi-character
episodes) into one engine that takes any cast + scenes.
"""
from __future__ import annotations

import hashlib
import json
import os

from . import backends as bk


def build_performance(title: str, cast: dict, scenes: list, out_json: str,
                      gap_ms: int = 700, model: str = "eleven_v3") -> str:
    """cast = {role: (voice_name, voice_id)};  scenes = [(scene_id, [(role, text), ...]), ...].

    A narrator role (e.g. "N") is just another voice — it carries action between lines.
    """
    segs = [{"scene": sid, "frame": sid, "speaker": role, "text": text}
            for sid, lines in scenes for role, text in lines]
    perf = {
        "title": title, "model_id": model, "output_format": "mp3_44100_128",
        "gaps_ms": {"group": gap_ms},
        "cast": {r: {"voice": n, "voice_id": v} for r, (n, v) in cast.items()},
        "segments": segs,
    }
    os.makedirs(os.path.dirname(out_json) or ".", exist_ok=True)
    json.dump(perf, open(out_json, "w"), indent=1)
    print(f"{len(scenes)} scenes, {len(segs)} lines -> {out_json}", flush=True)
    return out_json


def render(perf_json: str, out_mp3: str) -> str:
    """Render the performance: one continuous take per (scene, frame) group, stitched."""
    perf = json.load(open(perf_json))
    cache = os.path.join(os.path.dirname(perf_json) or ".", "segments")
    os.makedirs(cache, exist_ok=True)
    model = perf["model_id"]
    gap = perf.get("gaps_ms", {}).get("group", 700)

    groups: list[dict] = []
    for s in perf["segments"]:
        k = (s.get("scene", "").split("—")[0].strip(), s.get("frame"))
        if groups and groups[-1]["k"] == k:
            groups[-1]["segs"].append(s)
        else:
            groups.append({"k": k, "frame": s.get("frame"), "segs": [s]})

    files, manifest = [], []
    for gi, g in enumerate(groups):
        inputs = [{"text": s["text"], "voice_id": perf["cast"][s["speaker"]]["voice_id"]}
                  for s in g["segs"]]
        dig = hashlib.sha1(json.dumps([inputs, model], sort_keys=True).encode()).hexdigest()[:16]
        path = f"{cache}/grp_{dig}.mp3"
        if not os.path.exists(path):
            open(path, "wb").write(bk.elevenlabs_dialogue(inputs, model))
            print(f"[{gi+1}/{len(groups)}] {g['k'][0]}", flush=True)
        if files:
            files.append(bk.silence(gap, cache))
        files.append(path)
        manifest.append({"group": gi, "scene": g["k"][0], "frame": g["frame"], "path": path,
                         "duration": bk.duration(path),
                         "gap_after_ms": 0 if gi == len(groups) - 1 else gap})
    json.dump(manifest, open(out_mp3.rsplit(".", 1)[0] + ".manifest.json", "w"), indent=1)
    bk.concat_audio(files, out_mp3)
    print(f"\n{len(groups)} takes -> {out_mp3} ({bk.duration(out_mp3)/60:.1f} min)", flush=True)
    return out_mp3
