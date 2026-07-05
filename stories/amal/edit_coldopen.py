"""Run the new cold-open (and the trimmed दृश्य पाँच opening) through the stateful editor."""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
SID = open(f"{D}/.passes/EP1_editor.sid").read().strip()
ctx = open(f"{D}/PASS_CONTEXT.md").read()
full = open(f"{D}/EP1.md").read()
cold = full[full.index("## NEW-COLD-OPEN"):full.index("## दृश्य एक")].strip()

ed = Editor(context=ctx, session_id=SID)
ed.started = True   # resume the existing EP1 session (it remembers the 20 scenes)

prompt = (
 "REVISED cold-open (you saw an earlier version). The director's note this round: carry the whole "
 "opium economy in the farmer's BODY LANGUAGE across two beats. At the government weighment centre he is "
 "in deep reverence — folds his hands like in a temple, poor-mouths the rain, begs the licence not be "
 "cut, takes the receipt in both hands, collects ONE bundle at the cashier window and tucks it away "
 "careful. At the black sale the buyer doesn't even weigh the held-back gum and pays a BUTTLOAD; the "
 "same farmer is now confident — shoves the brick in uncounted, lights a beedi, says he'll have the same "
 "again next time, rides off on his Enfield. The two 'अगली बार' lines deliberately rhyme and mean the "
 "opposite (groveling vs cocky).\n\n"
 "Judge it against the full bar and the held cards. Specifically: (1) does the reverent→confident arc "
 "land by SHOWING (handling of money, posture), or is it told/on-the-nose anywhere? Flag any emotion "
 "wryly or authorial theme-line. (2) does ANY held card leak — Sugna as the killer, opium as the murder "
 "weapon, the train, Ratan's complicity? It must establish only the legal/black economy, nothing about "
 "HOW Leela died. (3) voice / concreteness / clear-pane / dialogue-realism on the Hindi (KHARE, FARMER, "
 "THE BUYER). Return the same JSON.\n\n=== REVISED COLD-OPEN ===\n" + cold)

print(show(ed._parse(ed._claude(prompt, resume=True))))
