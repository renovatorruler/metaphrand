import json, os, sys, subprocess
sys.path.insert(0,"/Users/dusty/dev/brehon-law/stories/amal")
from ep2_spotting import SPOTS
D="/Users/dusty/dev/brehon-law/stories/amal"; A=f"{D}/audio"; CUES=f"{A}/ep2_cues"
VOICE=f"{D}/ep2_hindi.mp3"
BOOST=1.6   # instrumentals were inaudible in the blend (over-darkened + too low); lift them and the Rudaali stays as-is
def probe(f):
    return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of",
        "default=nw=1:nk=1",f],capture_output=True,text=True).stdout.strip() or 0)
man=json.load(open(f"{D}/ep2_timing.json"))
scn={}
for s in man["segments"]:
    a,b=s["start"],s["start"]+s["dur"]; sc=s["scene"]
    scn.setdefault(sc,[a,b]); scn[sc][0]=min(scn[sc][0],a); scn[sc][1]=max(scn[sc][1],b)
TOTAL=probe(VOICE)
def cue_path(sc,spec):
    k=spec["kind"]
    if k=="gen": return f"{CUES}/sc{sc:02d}.mp3"
    if k=="have": return f"{A}/{spec['cue']}.mp3"
    if k=="rudaali": return f"{A}/amal_score_rudaali_processed.mp3"
    return None

# build the placement list (only scored scenes whose cue file exists)
place=[]; missing=[]
for sc in sorted(SPOTS):
    spec=SPOTS[sc]
    if spec["kind"]=="silence" or sc not in scn: continue
    cp=cue_path(sc,spec)
    if not cp or not os.path.exists(cp): missing.append(sc); continue
    a,b=scn[sc]; off=spec.get("win",(0,None))[0]
    start=a+off
    clen=probe(cp)
    plen=spec["win"][1] if "win" in spec else (b-a)
    plen=min(plen, clen)                      # never run past the cue
    lvl,lp=spec["lvl"],spec["lp"]
    if spec["kind"]!="rudaali": lvl,lp=round(lvl*BOOST,3),11000  # lift + un-darken: sit audibly behind the voice
    place.append((sc,cp,start,plen,lvl,lp))
print(f"TOTAL={TOTAL:.0f}s  scored+present={len(place)}  missing-cues={missing}")
for sc,cp,start,plen,lvl,lp in place:
    print(f"  sc{sc:02d} @ {start:6.1f}s  len {plen:5.1f}s  lvl {lvl:.2f}")

def build(outfile, picks=None, preview=False):
    # picks: list of (start_in_master, dur) windows to splice for a preview; else full master
    inputs=["-i",VOICE]; fc=[]; mixes=["[0:a]"]
    for i,(sc,cp,start,plen,lvl,lp) in enumerate(place,1):
        inputs+=["-i",cp]; ms=int(start*1000)
        fo=max(plen-3,0.1); fi=min(2.5,plen/3)
        fc.append(f"[{i}:a]aformat=cl=stereo:sample_rates=44100,atrim=0:{plen:.3f},"
                  f"highpass=f=90,lowpass=f={lp},equalizer=f=2500:width_type=o:width=1.8:g=-6,"
                  f"volume={lvl},afade=t=in:st=0:d={fi:.2f},afade=t=out:st={fo:.3f}:d=3,"
                  f"adelay={ms}|{ms}[c{i}]")
        mixes.append(f"[c{i}]")
    fc.append("".join(mixes)+f"amix=inputs={len(place)+1}:normalize=0:dropout_transition=0[mixed]")
    last="[mixed]"
    if preview and picks:
        segs=[]
        for j,(ps,pd) in enumerate(picks):
            fc.append(f"{last}atrim={ps:.2f}:{ps+pd:.2f},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.4,"
                      f"afade=t=out:st={pd-0.6:.2f}:d=0.6[p{j}]"); segs.append(f"[p{j}]")
        fc.append("".join(segs)+f"concat=n={len(picks)}:v=0:a=1[cat]"); last="[cat]"
    fc.append(f"{last}loudnorm=I=-16:TP=-1.5[o]")
    cmd=["ffmpeg","-nostdin","-loglevel","error","-y"]+inputs+["-filter_complex",";".join(fc),
         "-map","[o]","-c:a","libmp3lame","-b:a","192k" if not preview else "160k",outfile]
    subprocess.run(cmd,check=True)
    print("WROTE",outfile,round(os.path.getsize(outfile)/1e6,1),"MB")

if __name__=="__main__":
    build(f"{D}/ep2_scored_master.mp3")
    # representative preview across the palette (scene -> ~22s from a few seconds in)
    show=[1,3,6,11,16,19,36,39]
    picks=[(scn[s][0]+4, 22) for s in show if s in scn]
    build(f"{D}/ep2_score_preview.mp3", picks=picks, preview=True)
