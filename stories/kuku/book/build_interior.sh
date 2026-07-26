#!/bin/bash
# Book interior build v2 — with the क TEACHING SYSTEM: inline gold highlights on every
# क-word in the text + word-pills («क से कुत्ता») on every art page.
cd /Users/dusty/Dev/metaphrand/stories/kuku/book
python3 <<'PY'
import json, subprocess, re

spreads = json.load(open('book_text.json'))

# क word bank incl. inflections; function words (का की के को कि) deliberately excluded.
BANK = ['कुत्ता','कुत्ते','कालू','काला','काले','काली','कान','कानों','कुआँ','कुएँ','कीचड़',
        'कटोरा','कटोरे','कंबल','केला','केले','कबूतर','किताब','काग़ज़','कागज़','काम','कुकु']
# the picturable pill word per spread (primary word → the art label)
PILLS = {1:'कान', 2:'कुत्ता', 3:None, 4:None, 5:'कान', 6:'कीचड़', 7:'केला',
         8:'कटोरा', 9:'कंबल', 10:'कुआँ', 11:'कुआँ', 12:None, 13:'कालू', 14:'किताब'}

PUNCT = '।!?,."\'“”'
def esc(t): return t.replace('\\','\\\\').replace('#','\\#').replace('[','\\[').replace(']','\\]').replace('$','\\$')
def markup(line):
    out=[]
    for tok in line.split(' '):
        core=tok.strip(PUNCT)
        if core in BANK:
            pre=tok[:tok.index(core)]; post=tok[len(pre)+len(core):]
            out.append(f'{esc(pre)}#kw[{esc(core)}]{esc(post)}')
        else:
            out.append(esc(tok))
    return ' '.join(out)

P=[]
P.append('''#set page(width: 8.75in, height: 8.75in, margin: 0in)
#set text(font: "ITF Devanagari", size: 21pt, fill: rgb("46321e"))
#let cream = rgb("f7f2e6")
#let kw(w) = text(fill: rgb("c07f00"), weight: "bold", w)
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
#let wordpill(w) = place(bottom + left, dx: 0.55in, dy: -0.55in,
  block(fill: rgb(255,255,255,225), radius: 14pt, inset: (x: 16pt, y: 10pt),
    text(size: 20pt, fill: rgb("46321e"), weight: "bold")[#text(fill: rgb("c07f00"))[क] #h(2pt) #w]))
#let artpage(path, pill: none, overlay: none) = page(fill: cream)[
  #place(top + left, image(path, width: 8.75in, height: 8.75in, fit: "cover"))
  #if overlay != none {
    place(top + left, dx: overlay.at(0), dy: overlay.at(1),
      text(size: overlay.at(2), fill: rgb("ffd246"), stroke: 0.6pt + white)[क])
  }
  #if pill != none { wordpill(pill) }
]
''')
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 44pt, weight: "bold")[कुकु और काला कुत्ता]
    #v(0.4in)
    #text(size: 22pt)[एक #text(fill: rgb("c07f00"), weight: "bold")[क] वाली कहानी]
    #v(0.8in)
    #text(size: 80pt, fill: rgb("e0b34c"))[क]
  ]
]''')
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 24pt)[फ़ूरिया और वैस्पर के लिए]
    #v(0.5em)
    #text(size: 16pt, fill: rgb("8a7355"))[जिनकी कहानियाँ अभी शुरू हुई हैं]
  ]
]''')
P.append('#artpage("bpcover.jpg")')
for n in range(1, 15):
    lines = spreads[str(n)]
    lstr = ', '.join(f'[{markup(l)}]' for l in lines)
    P.append(f'#textpage(({lstr},))')
    pill = PILLS.get(n)
    pillarg = f'pill: [से {esc(pill)}]' if pill else 'pill: [— आज का अक्षर!]'
    if n == 3:  P.append(f'#artpage("bp03.jpg", {pillarg}, overlay: (3.75in, 5.3in, 120pt))')
    elif n == 12: P.append(f'#artpage("bp12.jpg", {pillarg}, overlay: (1.85in, 1.55in, 120pt))')
    else: P.append(f'#artpage("bp{n:02d}.jpg", {pillarg})')
P.append('''#page(fill: cream)[
  #place(top + center, dy: 0.55in, text(size: 28pt, weight: "bold")[आज का अक्षर])
  #place(top + center, dy: 1.15in, text(size: 84pt, fill: rgb("e0b34c"))[क])
  #place(top + center, dy: 2.9in, image("bplesson.jpg", width: 3.9in))
  #place(top + center, dy: 7.0in, text(size: 21pt)[#kw[क] से कुत्ता · #kw[क] से कान · #kw[क] से केला])
  #place(top + center, dy: 7.6in, text(size: 16pt, fill: rgb("8a7355"))[हिंदी का हर अक्षर टोपी पहनता है!])
]''')
open('interior.typ','w').write('\n'.join(P))
r=subprocess.run(['typst','compile','interior.typ','KUKU_BOOK_INTERIOR.pdf'],capture_output=True,text=True)
print(r.stderr[-1500:] if r.returncode else 'OK: KUKU_BOOK_INTERIOR.pdf')
PY
