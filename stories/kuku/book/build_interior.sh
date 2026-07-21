#!/bin/bash
# Book interior build (media tooling; python inline-disposable per repo convention).
cd /Users/dusty/Dev/metaphrand/stories/kuku/book
python3 <<'PY'
# text inside 0.625" (bleed+safety), fonts embedded by typst.
import json, subprocess, os

spreads = json.load(open('book_text.json'))

def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"')

P = []
P.append('''#set page(width: 8.75in, height: 8.75in, margin: 0in)
#set text(font: "ITF Devanagari", size: 21pt, fill: rgb("46321e"))
#let cream = rgb("f7f2e6")
#let textpage(lines) = page(fill: cream)[
  #place(top + right, dx: -0.55in, dy: 0.55in, text(size: 15pt, fill: rgb("c8a45a"))[क])
  #align(center + horizon)[
    #block(width: 6.6in)[
      #for l in lines [
        #par(justify: false, leading: 0.9em)[#align(center)[#l]]
        #v(0.55em)
      ]
    ]
  ]
]
#let artpage(path, overlay: none) = page(fill: cream)[
  #place(top + left, image(path, width: 8.75in, height: 8.75in, fit: "cover"))
  #if overlay != none {
    place(top + left, dx: overlay.at(0), dy: overlay.at(1),
      text(size: overlay.at(2), fill: rgb("ffd246"), stroke: 0.6pt + white)[क])
  }
]
''')
# p1 title
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 44pt, weight: "bold")[कुकु और काला कुत्ता]
    #v(0.4in)
    #text(size: 22pt)[एक क वाली कहानी]
    #v(0.8in)
    #text(size: 80pt, fill: rgb("e0b34c"))[क]
  ]
]''')
# p2 dedication
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 24pt)[फ़ूरिया और वैस्पर के लिए]
    #v(0.5em)
    #text(size: 16pt, fill: rgb("8a7355"))[जिनकी कहानियाँ अभी शुरू हुई हैं]
  ]
]''')
# p3 splash art
P.append('#artpage("bpcover.png")')
# p4..p31: 14 spreads
for n in range(1, 15):
    lines = spreads[str(n)]
    lstr = ', '.join(f'"{esc(l)}"' for l in lines)
    P.append(f'#textpage(({lstr},))')
    overlay = ''
    if n == 3:  P.append('#artpage("bp03.png", overlay: (3.4in, 4.1in, 110pt))')
    elif n == 12: P.append('#artpage("bp12.png", overlay: (3.6in, 2.3in, 120pt))')
    else: P.append(f'#artpage("bp{n:02d}.png")')
# p32 lesson
P.append('''#page(fill: cream)[
  #align(center)[
    #v(0.7in)
    #text(size: 30pt, weight: "bold")[आज का अक्षर]
    #v(0.2in)
    #text(size: 120pt, fill: rgb("e0b34c"))[क]
    #v(0.3in)
    #image("bplesson.png", width: 5.6in)
    #v(0.3in)
    #text(size: 22pt)[क से कुत्ता · क से कान · क से केला]
    #v(0.35in)
    #text(size: 17pt, fill: rgb("8a7355"))[हिंदी का हर अक्षर टोपी पहनता है!]
  ]
]''')
open('interior.typ', 'w').write('\n'.join(P))
r = subprocess.run(['typst', 'compile', 'interior.typ', 'KUKU_BOOK_INTERIOR.pdf'], capture_output=True, text=True)
print(r.stderr[-2000:] if r.returncode else 'OK: KUKU_BOOK_INTERIOR.pdf')
PY
