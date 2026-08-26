#set page(width: 1280pt, height: 720pt, margin: 0pt, fill: rgb("f7f2e6"))
#set text(font: "Kohinoor Devanagari")
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
// r1 — the doubled frame: the whole episode in one picture
#page[#place(center + horizon)[#align(center)[
  #text(size: 44pt, fill: rgb("8a7355"))[एक नन्ही साथी — और आवाज़ लंबी!]
  #v(18pt)
  #text(size: 200pt, weight: "bold")[#text(fill: gold)[क] #text(fill: rgb("8a7355"), size: 110pt)[→] #text(fill: gold)[का]]
]]]
// r2..r8 — one card per word lived on screen
#let w(word, pic) = page[
  #place(left + horizon, dx: 70pt)[#align(left)[
    #text(size: 130pt, fill: brown, weight: "bold")[#word]
  ]]
  #place(right + horizon, dx: -60pt)[#box(radius: 24pt, clip: true, stroke: 6pt + brown, image(pic, width: 430pt, height: 430pt, fit: "cover"))]
]
#w([आम], "wordpics/aam.png")
#w([तारा], "wordpics/tara.png")
#w([रात], "wordpics/raat.png")
#w([नाम], "wordpics/naam.png")
#w([काम], "wordpics/kaam.png")
#w([पापा], "wordpics/papa.png")
#page[
  #place(left + horizon, dx: 70pt)[#align(left)[
    #text(size: 130pt, fill: brown, weight: "bold")[माता]
    #v(6pt)
    #text(size: 44pt, fill: rgb("8a7355"))[पापा की माता]
  ]]
  #place(right + horizon, dx: -60pt)[#box(radius: 24pt, clip: true, stroke: 6pt + brown, image("wordpics/mata.png", width: 430pt, height: 430pt, fit: "cover"))]
]
