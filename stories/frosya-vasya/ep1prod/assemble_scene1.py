import subprocess, os
# (clip, vo file or None, segment length seconds)
SEQ = [
 ("n_m_k_f1_haul",    "audio/a02_frosya_tyani.mp3", 10.0),
 ("n_m_k_f2_asks",    "audio/a04_vasya_pochemu.mp3", 8.2),
 ("n_m_k_f3_answers", "audio/a05_frosya_dom.mp3",    9.0),
 ("n_m_k_f4_hears",   None,                          4.0),
 ("n_m_k_f5_zamri",   "audio/a08_frosya_zamri.mp3",  3.5),
 ("n_m_k_f6_dust",    None,                          6.5),
]
os.makedirs("build", exist_ok=True)
parts=[]
for i,(clip,vo,T) in enumerate(SEQ):
    src=f"clips/{clip}.mp4"; out=f"build/s{i:02d}.mp4"
    vf="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=24"
    if vo:
        cmd=["ffmpeg","-y","-i",src,"-i",vo,"-filter_complex",
             f"[0:v]{vf}[v];[1:a]adelay=250|250,apad[a]",
             "-map","[v]","-map","[a]","-t",f"{T}",
             "-c:v","libx264","-pix_fmt","yuv420p","-crf","20","-c:a","aac","-b:a","192k",out,"-loglevel","error"]
    else:
        cmd=["ffmpeg","-y","-i",src,"-f","lavfi","-i","anullsrc=channel_layout=stereo:sample_rate=44100",
             "-filter_complex",f"[0:v]{vf}[v]","-map","[v]","-map","1:a","-t",f"{T}",
             "-c:v","libx264","-pix_fmt","yuv420p","-crf","20","-c:a","aac","-b:a","192k",out,"-loglevel","error"]
    subprocess.run(cmd,check=True); parts.append(out); print(f"seg {i}: {clip} -> {T}s")
with open("build/list2.txt","w") as f:
    for p in parts: f.write(f"file '{os.path.basename(p)}'\n")
subprocess.run(["ffmpeg","-y","-f","concat","-safe","0","-i","build/list2.txt",
                "-c:v","libx264","-pix_fmt","yuv420p","-crf","20","-c:a","aac","-b:a","192k",
                "SCENE1_v2.mp4","-loglevel","error"],check=True)
d=subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0","SCENE1_v2.mp4"],
                 capture_output=True,text=True).stdout.strip()
print("SCENE1_v2.mp4:", d, "s")
