#set page(width: 1280pt, height: 720pt, margin: 0pt, fill: rgb("f7f2e6"))
#set text(font: "Kohinoor Devanagari")
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
#let grey = rgb("9a9a9a")
// p1: episode letter title card
#page[#place(center+horizon)[#align(center)[
  #text(size: 44pt, fill: rgb("8a7355"))[आज का अक्षर]
  #v(10pt)
  #text(size: 300pt, fill: gold, weight: "bold")[म]
]]]
// p2: topi comparison card — English M bare, Hindi म wears the hat
#page[#place(center+horizon)[#align(center)[
  #grid(columns: 2, gutter: 140pt,
    align(center)[#text(size: 230pt, fill: grey, weight: "bold")[M] #v(2pt) #text(size: 34pt, fill: grey)[English — बिना टोपी]],
    align(center)[#text(size: 230pt, fill: gold, weight: "bold")[म] #v(2pt) #text(size: 34pt, fill: brown, weight: "bold")[हिंदी — टोपी वाला!]]
  )
]]]
// p3: recap intro
#page[#place(center+horizon)[#align(center)[#text(size: 64pt, fill: brown, weight: "bold")[आज के म शब्द] #v(28pt) #text(size: 40pt, fill: rgb("8a7355"))[चलो गिनते हैं!]]]]
// p4-10: the seven saved words
#let w(word) = page[#place(center+horizon)[#align(center)[
  #text(size: 150pt)[#text(fill: gold, weight: "bold")[म] #text(fill: brown, size: 46pt)[ से…]]
  #v(6pt)
  #text(size: 150pt, fill: brown, weight: "bold")[#word]
]]]
#w[माँ]
#w[मेला]
#w[मिठाई]
#w[मोर]
#w[मछली]
#w[मदद]
#w[माया]
// p11: recap outro
#page[#place(center+horizon)[#align(center)[#text(size: 60pt, fill: brown, weight: "bold")[सात शब्द! शाबाश!] #v(30pt) #text(size: 34pt, fill: rgb("8a7355"))[आज का अक्षर था — #text(fill: gold, weight: "bold")[म]!]]]]
