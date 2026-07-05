"""Resend the corrected दृश्य एक + confirm the three notes are resolved, to converge the ledger."""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
SID = open(f"{D}/.passes/EP1_editor.sid").read().strip()
full = open(f"{D}/EP1.md").read()
sc1 = full[full.index("## दृश्य एक"):full.index("## दृश्य दो")].strip()

ed = Editor(session_id=SID); ed.started = True
prompt = (
 "Revised draft of दृश्य एक + fixes for your three notes. Check ONLY whether they're resolved; don't "
 "re-litigate the denial model you already accepted. (1) The 'not grief, surprise' corrective-definition "
 "is gone — now 'Bherulal sees the uniforms and goes still', the line carries it. (2) Groom age is "
 "unified to 55 EVERYWHERE — दृश्य सात now 'PRATAP, fifty-five', दृश्य नौ 'पचपन', and the bible "
 "(BACKSTORY.md / PLOT.md) updated forty→fifty-five; Daulatram bumped to sixty so the uncle stays older "
 "than the groom. (3) The younger sister is शीला / SHEELA everywhere now — NANHI/नन्ही fully renamed in "
 "NEW-WOMENS-HOUSE, so no two-name tracking. Return JSON; ship if these clear.\n\n"
 "=== दृश्य एक (corrected) ===\n" + sc1)
print(show(ed._parse(ed._claude(prompt, resume=True))))
