"""AMAL title sequence v3 — Malwa cultural elements, dark cinematic, for very-slow animation. -> title_culture/"""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
OUT = "/Users/dusty/dev/brehon-law/stories/amal/title_culture"; os.makedirs(OUT, exist_ok=True)
LOOK = (" Dark cinematic prestige title-sequence still, painterly chiaroscuro, near-black background, "
        "single warm source light; desaturated except warm flame, vermilion red and gold; deep shadow, "
        "atmospheric, soft. Absolutely no text or captions. Malwa, Madhya Pradesh, India.")
SHOTS = [
 ("hand_poppy", "Extreme close-up at first dawn light: a weathered old Indian farmer's hand drifts slowly through a field of white-and-purple poppies, dew on the petals, soft mist, shallow focus, moody low light." + LOOK),
 ("mahakal", "Inside Mahakaleshwar Jyotirlinga temple at Ujjain before dawn during Bhasma Aarti: thick sacred grey ash-smoke drifting through shafts of oil-lamp light around a garlanded dark Shiva lingam, a priest's silhouette, deep devotional shadow." + LOOK),
 ("mata_pujan", "An ancient vermilion-smeared stone Devi goddess idol heaped with marigold garlands and silver foil in a dark shrine, rows of tiny oil lamps, a woman's hands offering flowers, incense smoke rising, devotional." + LOOK),
 ("kumbh", "Simhastha Kumbh at the Shipra river ghats, Ujjain, before dawn: ash-smeared naked Naga sadhus and a vast crowd of silhouettes in heavy mist and lamp-smoke, an ocean of devotees, cinematic wide." + LOOK),
 ("kaal_bhairav", "A fierce black-stone Kaal Bhairav idol smeared with vermilion and silver foil, heaped with marigolds, in a dark Malwa shrine, a priest's hand pouring liquor, oil lamps, smoke curling." + LOOK),
]
for name, prompt in SHOTS:
    out = f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip", name, flush=True); continue
    try: frames.shot(prompt, out, register="photoreal", pro=True); print("done", name, flush=True)
    except Exception as e: print("FAIL", name, str(e)[:150], flush=True)
print("ALL DONE", flush=True)
