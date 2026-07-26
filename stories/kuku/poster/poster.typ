#set page(width: 12in, height: 16in, margin: 0pt)
#place(image("poster_art.png", width: 12in, height: 16in, fit: "cover"))
// the three learned letters ride the golden breath-ribbon
#let glyph(g, x, y, s, rot) = place(dx: x, dy: y, rotate(rot)[
  #for off in ((-3pt,0pt),(3pt,0pt),(0pt,-3pt),(0pt,3pt)) {
    place(dx: off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: s, weight: "bold", fill: white)[#g])
  }
  #text(font: "Kohinoor Devanagari", size: s, weight: "bold", fill: rgb("e6a817"))[#g]
])
#glyph([क], 4.2in, 5.5in, 64pt, -12deg)
#glyph([म], 6.45in, 5.3in, 72pt, 8deg)
#glyph([र], 7.3in, 6.0in, 58pt, -6deg)
// title block in the open sky
#place(top + center, dy: 0.75in)[
  #align(center)[
    #for off in ((-5pt,0pt),(5pt,0pt),(0pt,-5pt),(0pt,5pt),(-4pt,-4pt),(4pt,4pt),(-4pt,4pt),(4pt,-4pt)) {
      place(center, dx: off.at(0), dy: off.at(1),
        text(font: "Kohinoor Devanagari", size: 130pt, weight: "bold", fill: white)[कुकु और अक्षर])
    }
    #text(font: "Kohinoor Devanagari", size: 130pt, weight: "bold", fill: rgb("c07f00"))[कुकु और अक्षर]
    #v(0.25in)
    #text(font: "Kohinoor Devanagari", size: 40pt, weight: "semibold", fill: rgb("46321e"))[अक्षर घाटी की कहानियाँ]
  ]
]
