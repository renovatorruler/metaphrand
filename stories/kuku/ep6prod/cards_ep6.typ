#set page(width: 1280pt, height: 720pt, margin: 0pt, fill: rgb("f7f2e6"))
#set text(font: "Kohinoor Devanagari")
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
#page[#place(center+horizon)[#align(center)[
  #text(size: 44pt, fill: rgb("8a7355"))[आज का अक्षर]
  #v(10pt)
  #text(size: 300pt, fill: gold, weight: "bold")[त]
]]]
#page[#place(center+horizon)[#align(center)[#text(size: 64pt, fill: brown, weight: "bold")[आज के त शब्द] #v(28pt) #text(size: 40pt, fill: rgb("8a7355"))[चलो गिनते हैं!]]]]
#let w(word, pic) = page[
  #place(left + horizon, dx: 70pt)[#align(left)[
    #text(size: 120pt)[#text(fill: gold, weight: "bold")[त] #text(fill: brown, size: 44pt)[ से…]]
    #v(4pt)
    #text(size: 130pt, fill: brown, weight: "bold")[#word]
  ]]
  #place(right + horizon, dx: -60pt)[#box(radius: 24pt, clip: true, stroke: 6pt + brown, image(pic, width: 430pt, height: 430pt, fit: "cover"))]
]
#w([तोता], "wordpics/tota.png")
#w([तालाब], "wordpics/talab.png")
#w([तना], "wordpics/tana.png")
#w([तीन], "wordpics/teen.png")
#w([ताली], "wordpics/taali.png")
#w([तानसेन], "wordpics/tansen.png")
#page[#place(center+horizon)[#align(center)[#text(size: 60pt, fill: brown, weight: "bold")[छह शब्द! शाबाश!] #v(30pt) #text(size: 34pt, fill: rgb("8a7355"))[आज का अक्षर था — #text(fill: gold, weight: "bold")[त]!]]]]
