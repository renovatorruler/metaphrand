#!/bin/bash
# Ep2 book interior — «म से माँ» with the म TEACHING SYSTEM (inline gold highlights +
# word-pills), Lulu spec: 8.75in square pages (8.5 trim + 0.125 bleed), 0.5in text safety.
# Current-law build: no टोपी line, फ्यूरिया spelling, माँ theme as the closing thought.
cd /Users/dusty/Dev/metaphrand/stories/kuku/book2
python3 <<'PY'
import json, subprocess

spreads = json.load(open('book2_text.json'))

BANK = ['माँ','मेला','मेले','मिठाई','मिठाइयाँ','मोर','मोरनी','मछली','मछलियाँ','मदद','माया',
        'मटका','मटके','मिटासुर','माशा','म']
PILLS = {1:None, 2:'मेला', 3:None, 4:'मिठाई', 5:'माँ', 6:'माया', 7:None,
         8:None, 9:'मटका', 10:None, 11:'मदद', 12:'मोर', 13:None, 14:'माँ'}

PUNCT = '।!?,."\'“”—…'
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
  #place(top + right, dx: -0.55in, dy: 0.55in, text(size: 15pt, fill: rgb("c8a45a"))[म])
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
    text(size: 20pt, fill: rgb("46321e"), weight: "bold")[#text(fill: rgb("c07f00"))[म] #h(2pt) #w]))
#let artpage(path, pill: none) = page(fill: cream)[
  #place(top + left, image(path, width: 8.75in, height: 8.75in, fit: "cover"))
  #if pill != none { wordpill(pill) }
]
''')
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 44pt, weight: "bold")[म से माँ]
    #v(0.4in)
    #text(size: 22pt)[एक #text(fill: rgb("c07f00"), weight: "bold")[म] वाली कहानी]
    #v(0.8in)
    #text(size: 80pt, fill: rgb("e0b34c"))[म]
  ]
]''')
P.append('''#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 24pt)[फ्यूरिया और वैस्पर के लिए]
    #v(0.5em)
    #text(size: 16pt, fill: rgb("8a7355"))[जिनकी कहानियाँ अभी शुरू हुई हैं]
  ]
]''')
P.append('#artpage("b2cover.jpg")')
for n in range(1, 15):
    lines = spreads[str(n)]
    lstr = ', '.join(f'[{markup(l)}]' for l in lines)
    P.append(f'#textpage(({lstr},))')
    pill = PILLS.get(n)
    pillarg = f'pill: [से {esc(pill)}]' if pill else 'pill: [— आज का अक्षर!]'
    P.append(f'#artpage("b2{n:02d}.jpg", {pillarg})')
P.append('''#page(fill: cream)[
  #place(top + center, dy: 0.55in, text(size: 28pt, weight: "bold")[आज का अक्षर])
  #place(top + center, dy: 1.15in, text(size: 84pt, fill: rgb("e0b34c"))[म])
  #place(top + center, dy: 2.9in, image("b2lesson.jpg", width: 3.9in))
  #place(top + center, dy: 7.0in, text(size: 21pt)[#kw[म] से माँ · #kw[म] से मेला · #kw[म] से मोर])
  #place(top + center, dy: 7.6in, text(size: 16pt, fill: rgb("8a7355"))[माँ तो सबकी होती है — बड़ों की भी!])
]''')
open('interior2.typ','w').write('\n'.join(P))
r=subprocess.run(['typst','compile','interior2.typ','KUKU_BOOK2_INTERIOR.pdf'],capture_output=True,text=True)
print(r.stderr[-1500:] if r.returncode else 'OK: KUKU_BOOK2_INTERIOR.pdf')
PY
