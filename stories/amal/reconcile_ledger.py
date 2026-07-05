"""Feed the editor the CURRENT (already-fixed) text of its three stale outstanding notes so it
marks them resolved and stops re-raising them every round."""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
SID = open(f"{D}/.passes/EP1_editor.sid").read().strip()
full = open(f"{D}/EP1.md").read()

def scene(a, b): return full[full.index(a):full.index(b)].strip()
wound  = scene("## NEW-RATAN-WOUND",  "## दृश्य सात")
women  = scene("## NEW-WOMENS-HOUSE", "## NEW-PRESSURE")
deva   = scene("## NEW-DEVA-ACTS",    "## दृश्य दस")

ed = Editor(session_id=SID); ed.started = True
prompt = (
 "Ledger reconciliation. Your three outstanding notes were FIXED in the shooting script some drafts ago; "
 "you keep re-raising them only because I've been showing you other scenes. Here are the CURRENT versions "
 "of those exact three scenes. Confirm each note is resolved and CLEAR it from your ledger — do not "
 "re-litigate. (1) NEW-RATAN-WOUND: the farmer now only exchanges 'राम राम' — no Panwar/big-man land line. "
 "(2) NEW-WOMENS-HOUSE: Nanhi is now 'twelve', consistent with Sc7's बारह. (3) NEW-DEVA-ACTS: the "
 "'never once been asked' theme line is gone. Return the JSON with these in resolved_this_round and "
 "outstanding empty if nothing else is broken.\n\n"
 "=== NEW-RATAN-WOUND ===\n" + wound +
 "\n\n=== NEW-WOMENS-HOUSE ===\n" + women +
 "\n\n=== NEW-DEVA-ACTS ===\n" + deva)
print(show(ed._parse(ed._claude(prompt, resume=True))))
