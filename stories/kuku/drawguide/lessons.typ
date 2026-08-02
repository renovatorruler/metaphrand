#set page(width: 8.5in, height: 11in, margin: (x: 0.5in, y: 0.5in))
#set text(font: ("Kohinoor Devanagari", "Helvetica"), size: 11pt, fill: rgb("2e2418"))
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
#let red = rgb("ce3a30")
#let num(n) = box(width: 24pt, height: 24pt, radius: 12pt, fill: gold,
  align(center + horizon, text(fill: white, weight: "bold", size: 13pt)[#n]))

#let lawstrip = block(width: 100%, fill: rgb("f7f2e6"), radius: 8pt, inset: 9pt)[
  #grid(columns: 4, gutter: 10pt,
    ..(("law_contour","घुमाव","the cross curves — that is what makes it look round"),
       ("law_overlap","ढकना","what is in front covers what is behind"),
       ("law_shade","छाया","dark on the side away from the light"),
       ("law_shadow","ज़मीन","a shadow on the ground, under it")
      ).map(p => grid(columns: (auto, 1fr), gutter: 6pt,
        image("light/steps_" + p.at(0) + ".jpg", width: 0.42in),
        [#text(size: 10pt, weight: "bold")[#p.at(1)] \ #text(size: 8.5pt)[#p.at(2)]])))
]

// ---------------- COVER ----------------
#page[
  #align(center)[
    #v(0.9in)
    #text(size: 40pt, weight: "bold", fill: brown)[चलो ड्रैगन बनाएँ]
    #v(6pt)
    #text(size: 19pt)[Let's Draw the Dragons of अक्षर घाटी]
    #v(0.45in)
    #grid(columns: 5, gutter: 6pt,
      ..(1,2,3,5,9).map(i => image("light/steps_kuku_L0" + str(i) + ".jpg", height: 1.5in)))
    #v(0.4in)
    #block(width: 5.9in)[#text(size: 13pt)[
      Every lesson works the same way. Each step adds *one new mark*, and the new mark is always
      *#text(fill: red, weight: "bold")[red]* — everything you already drew turns grey. Never draw
      more than the red bit.
      #v(6pt)
      And in every lesson you practise the same four things that make a drawing look *round instead
      of flat*. They are at the bottom of every page.
    ]]
  ]
]

// ---------------- THE MARKS ----------------
#page[
  #text(size: 23pt, weight: "bold", fill: brown)[पहले — ये छह निशान]
  #v(2pt)
  #text(size: 12.5pt)[First, these six marks. That is the whole alphabet — every character in this
  book is made of nothing else. Practise each one a few times in the space below.]
  #v(16pt)
  #grid(columns: 6, gutter: 8pt,
    ..(("circle","गोला","circle"),("oval","अंडा","oval"),("c","कमान","a C"),
       ("triangle","तिकोन","triangle"),("v","चोटी","a V"),("dot","बिंदु","dot"))
      .map(p => align(center)[
        #image("light/steps_mark_" + p.at(0) + ".jpg", width: 1.05in)
        #text(size: 11pt, weight: "bold")[#p.at(1)] \ #text(size: 9pt)[#p.at(2)]]))
  #v(16pt)
  #block(width: 100%, height: 2.5in, stroke: 1pt + rgb("d8c9a0"), radius: 8pt, inset: 10pt)[
    #text(size: 10pt, fill: rgb("8a7355"))[तुम्हारी बारी — your turn]
  ]
  #v(14pt)
  #text(size: 12.5pt)[Two marks do most of the work: a *circle* for a head and an *oval* for a body.
  Put those two down first, every single time.]
]

// ---------------- WARM-UP: THE BALL ----------------
#page[
  #text(size: 23pt, weight: "bold", fill: brown)[रोज़ का अभ्यास — the warm-up ball]
  #v(2pt)
  #text(size: 12.5pt)[Do this one small drawing before every session. It is only a circle — but by
  the fourth step it is a *ball sitting on a table*, and those four moves are the whole secret of
  drawing in 3D. You will use them on every dragon in this book.]
  #v(18pt)
  #grid(columns: 4, gutter: 14pt,
    ..((1,"k1","एक गोला","Draw a circle. Flat, so far."),
       (2,"k2","घुमाव की रेखाएँ","Two curved lines across it. They bend, and suddenly it is round."),
       (3,"k3","छाया","Pick a light — top-left. Darken the far side and leave a white dot near the light."),
       (4,"k4","ज़मीन की छाया","A soft shadow on the ground, away from the light. Now it is sitting on something."))
      .map(p => align(center)[
        #num(p.at(0))
        #v(4pt)
        #image("light/steps_" + p.at(1) + ".jpg", width: 1.62in)
        #v(4pt)
        #text(size: 11pt, weight: "bold")[#p.at(2)]
        #v(1pt)
        #text(size: 9pt)[#p.at(3)]]))
  #v(20pt)
  #block(width: 100%, fill: rgb("f7f2e6"), radius: 8pt, inset: 12pt)[
    #text(size: 12.5pt)[*The one rule.* Decide where the light is *before* you start, and keep it
    there for the whole drawing. Every shadow on every part — head, tummy, each toe — falls on the
    same side. In अक्षर घाटी the light always comes from the *top-left*.]
  ]
  #v(14pt)
  #block(width: 100%, height: 1.9in, stroke: 1pt + rgb("d8c9a0"), radius: 8pt, inset: 10pt)[
    #text(size: 10pt, fill: rgb("8a7355"))[अपनी गेंद बनाओ — draw your own ball here]
  ]
]

// ---------------- LESSONS ----------------
#let lesson(id, hindi, eng, stars, tip, bonus, nsteps) = page[
  #grid(columns: (1fr, auto, auto), gutter: 10pt, align: (left + horizon, right + horizon, right + horizon),
    [#text(size: 25pt, weight: "bold", fill: brown)[#hindi]
     #h(7pt) #text(size: 13pt, fill: rgb("8a7355"))[#eng]
     #v(1pt)
     #text(size: 10.5pt)[#tip]],
    text(size: 13pt, fill: gold)[#stars],
    image("light/sheets_" + id + ".jpg", height: 0.95in))
  #v(7pt)
  #grid(columns: 3, rows: 3, gutter: 7pt,
    ..range(1, nsteps + 1).map(i => block(width: 100%, height: 2.28in,
        stroke: 0.7pt + rgb("d8c9a0"), radius: 6pt, inset: 4pt)[
      #place(top + left, num(i))
      #align(center + horizon)[#image("light/steps_" + id + "_L" + (if i < 10 { "0" } else { "" }) + str(i) + ".jpg", height: 2.0in)]
    ]))
  #v(7pt)
  #block(width: 100%, fill: rgb("fdf7e4"), radius: 6pt, inset: 8pt)[
    #text(size: 11pt)[#text(weight: "bold", fill: red)[और आगे — bonus:] #bonus]
  ]
  #v(6pt)
  #lawstrip
]

#lesson("leda","लेडा","Leda","★☆☆☆☆",
  "All circles. Start here.",
  "Draw Leda looking straight up at the sky — move the eye-line curve near the top of the ball.", 9)
#lesson("castor","कैस्टर","Castor","★☆☆☆☆",
  "Same shapes as Leda, plus a wide grin.",
  "Draw Castor holding a party popper. Overlap it in front of his tummy.", 9)
#lesson("kalu","कालू","Kalu","★★☆☆☆",
  "No wings, no horns — but watch those floppy ears.",
  "Draw Kalu running: tilt the whole body oval forward and bend the legs.", 9)
#lesson("kuku","कुकु","Kuku","★★☆☆☆",
  "Two little horns, small wings — he is the littlest dragon.",
  "Draw Kuku breathing a letter, and let the glow overlap in front of his snout.", 9)
#lesson("vesper","वैस्पर","Vesper","★★★☆☆",
  "Sleepy eyes, only half open.",
  "Draw Vesper asleep. Tilt the ball, close the eyes to two curved lines.", 9)
#lesson("furia","फ्यूरिया","Fyuria","★★★☆☆",
  "She leans forward, like she is about to run.",
  "Draw Fyuria mid-run: lean the egg further and put one wing in front of the other.", 9)
#lesson("mitasur","मिटासुर","Mitasur","★★★☆☆",
  "A pear shape, big leaf ears, one tooth showing.",
  "Draw a mountain of foam on his sponge-hands — shade the underside of every bubble.", 9)
#lesson("reechh","रीछ","Reechh","★★★★☆",
  "One big oval, one small circle on top.",
  "Draw Reechh sitting down and patting his tummy. His arm will overlap his belly.", 9)
#lesson("dadi","दादी माया","Dadi Maya","★★★★★",
  "Long neck, shawl, spectacles. The hardest one — save her for last.",
  "Draw Dadi with her walking stick, and put her wing behind her shawl.", 8)

// ---------------- TRACING ----------------
#let trace(id, hindi) = page[
  #align(center)[#text(size: 19pt, weight: "bold", fill: brown)[#hindi
    #h(6pt) #text(size: 12pt, fill: rgb("8a7355"))[— trace, then draw it again next to it]]]
  #v(3pt)
  #align(center)[#image("light/steps_" + id + "_trace.jpg", height: 8.5in)]
]
#trace("leda","लेडा")
#trace("kalu","कालू")
#trace("kuku","कुकु")
#trace("vesper","वैस्पर")
#trace("furia","फ्यूरिया")
#trace("mitasur","मिटासुर")
#trace("reechh","रीछ")
#trace("dadi","दादी माया")

#page[
  #align(center + horizon)[
    #text(size: 25pt, weight: "bold", fill: brown)[शाबाश!]
    #v(10pt)
    #block(width: 5.4in)[#text(size: 13.5pt)[
      Now stop copying. Put कुकु somewhere he has never been — on the रथ, up a tree, under water.
      You already know how: circle, oval, the parts, one line around it, the face, then light from
      the top-left.
    ]]
    #v(22pt)
    #image("light/sheets_kuku.jpg", height: 2.4in)
    #v(10pt)
    #text(size: 11pt, fill: rgb("8a7355"))[अक्षर घाटी — Letter Valley]
  ]
]
