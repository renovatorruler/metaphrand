"""Run the rewritten दृश्य एक (Bherulal-in-denial) through the stateful editor."""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
SID = open(f"{D}/.passes/EP1_editor.sid").read().strip()
full = open(f"{D}/EP1.md").read()
sc1 = full[full.index("## दृश्य एक"):full.index("## दृश्य दो")].strip()

ed = Editor(session_id=SID); ed.started = True
prompt = (
 "MAJOR REWRITE of दृश्य एक (scene 1). The old version played the father Bherulal as a vague "
 "'grief + crop-worry' middle that read as confusing/indifferent. The new model: he is in DENIAL "
 "(protecting the investment). He did NOT call the police — someone else did — so his first beat is "
 "genuine SURPRISE; he clings to 'she slipped and fell'; in denial he buries himself in logistics "
 "(crop, wedding date, the engraved wedding utensils) and his brother MOHAN coldly proposes swapping "
 "the dead daughter LEELA for the 12-year-old younger sister SHEELA into the same alliance (engraving "
 "gag, लीला→शीला, 'छोटी तो है ही'). The constable DEVA LAMPSHADES the weirdness; RATAN NAMES it as "
 "सदमा/denial — that's the device that makes the behaviour legible. Despite empathising, Ratan orders "
 "the postmortem; the denial CRACKS and grief floods through ('रहने दो उसे'); ends on 'let's see her "
 "room' into Sc2.\n\n"
 "Judge against the full bar + held cards. (1) Is Bherulal now ONE coherent, legible state (denial), "
 "not the old confusing middle? (2) Do Deva's lampshade + Ratan's naming land it WITHOUT becoming "
 "on-the-nose exposition? (3) HELD CARDS: Bherulal must not name suicide; nothing about the mother "
 "Sugna or opium-as-weapon may surface; 'who called the police' stays an open question. (4) Is the "
 "engraving gag dark-but-legible, and does the grief-crack keep Bherulal HUMAN, not a monster? "
 "(5) voice/concreteness/clear-pane on Mohan/Bherulal/Deva/Ratan. Names now: victim LEELA, younger "
 "sister SHEELA(12), groom PRATAP 55, brother MOHAN. Return JSON.\n\n=== दृश्य एक (REWRITE) ===\n" + sc1)
print(show(ed._parse(ed._claude(prompt, resume=True))))
