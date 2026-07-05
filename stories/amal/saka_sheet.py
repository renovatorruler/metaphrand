"""Generate the SAKA warrior's character sheet — locked to RATAN's likeness/build.
The saka warrior IS Ratan (held card); his face is never shown on screen, but the SHEET needs his
real identity + heavy 52-yr build so every saka back-view reads as the same man. Conditioned on the
existing ratan.png portrait, re-dressed as the 1305 last-stand warrior. -> sheets/saka_turnaround.png
"""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import characters

SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"

SAKA = (
 "the SAME man as the reference image — a heavy, weary, jowly ~52-year-old Malwa man with grey-streaked "
 "dark hair and a thick grey-streaked moustache, bags under his eyes, a broad heavy thick-set build — keep "
 "his exact face and his heavy older build. But render him here as a 14th-century (year 1305) Rajput "
 "foot-soldier at his last stand: a coarse hand-woven knee-length cotton tunic / jama in undyed oatmeal, "
 "NO modern uniform of any kind, the cloth torn and soaked dark with blood; bare heavy forearms bloodied to "
 "the elbow; a twisted cloth waist-sash; a heavy worn gold signet ring on one thick finger; an old notched "
 "talwar in hand. Weathered, spent, unbroken. Photorealistic, NOT an illustration, grounded and cinematic."
)

characters.turnaround(f"{SH}/ratan.png", SAKA, f"{SH}/saka_turnaround.png")
print("SAKA SHEET DONE")
