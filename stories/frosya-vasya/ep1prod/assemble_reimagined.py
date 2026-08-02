import subprocess, os
os.makedirs("build", exist_ok=True)
# (clip, trim seconds)
TRACK = [
 ("clips/c_r1_cuff.mp4",       4.0),
 ("clips/c_r2_silhouette.mp4", 6.0),
 ("clips/c_r3_feet.mp4",       4.0),
 ("clips/c_r4_vasya.mp4",      4.5),
 ("clips/c_r5_frosya.mp4",    10.0),
 ("clips/c_r6_zamri.mp4",      3.0),
 ("clips/c_r7_dark.mp4",       7.0),
]
# audio events at absolute seconds: (file, t, volume)
EVENTS = [
 ("sfx/roomtone.wav",          0.0, 0.8),
 ("audio/a02_frosya_tyani.mp3",0.3, 1.0),
 ("audio/a04_vasya_pochemu.mp3",10.2,1.0),
 ("audio/a05_frosya_dom.mp3", 18.8, 1.0),
 ("sfx/creak.wav",            27.6, 0.9),
 ("audio/a08_frosya_zamri.mp3",28.7,1.0),
 ("sfx/boom.wav",             31.5, 1.0),
 ("sfx/dusthiss.wav",         31.8, 0.8),
]
vf="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=24"
parts=[]
for i,(src,T) in enumerate(TRACK):
    seg=f"build/r{i:02d}.mp4"
    subprocess.run(["ffmpeg","-y","-i",src,"-vf",vf,"-t",f"{T}","-an",
        "-c:v","libx264","-pix_fmt","yuv420p","-crf","20",seg,"-loglevel","error"],check=True)
    parts.append(seg); print("seg",i,src.split('/')[-1],T)
with open("build/rlist.txt","w") as f:
    for p in parts: f.write(f"file '{os.path.basename(p)}'\n")
subprocess.run(["ffmpeg","-y","-f","concat","-safe","0","-i","build/rlist.txt","-c","copy",
    "build/rtrack.mp4","-loglevel","error"],check=True)
total=sum(T for _,T in TRACK)
cmd=["ffmpeg","-y","-i","build/rtrack.mp4"]
fc=[]; mix=[]
for n,(wav,t,vol) in enumerate(EVENTS, start=1):
    cmd+=["-i",wav]
    d=int(t*1000)
    fc.append(f"[{n}:a]adelay={d}|{d},volume={vol}[e{n}]"); mix.append(f"[e{n}]")
fc.append("".join(mix)+f"amix=inputs={len(mix)}:normalize=0:duration=longest,atrim=0:{total}[a]")
cmd+=["-filter_complex",";".join(fc),"-map","0:v","-map","[a]","-t",f"{total}",
      "-c:v","copy","-c:a","aac","-b:a","192k","SCENE1_reimagined.mp4","-loglevel","error"]
subprocess.run(cmd,check=True)
d=subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0","SCENE1_reimagined.mp4"],
 capture_output=True,text=True).stdout.strip()
print("SCENE1_reimagined.mp4:",d,"s")
