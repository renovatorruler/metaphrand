#set page(width: 8.5in, height: 11in, margin: (x: 0.5in, y: 0.5in))
#set text(font: ("Kohinoor Devanagari", "Helvetica"), size: 12pt)
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
#let num(n) = box(width: 30pt, height: 30pt, radius: 15pt, fill: gold,
  align(center + horizon, text(fill: white, weight: "bold", size: 17pt)[#n]))

#page[
  #align(center)[
    #v(1.6in)
    #text(size: 42pt, weight: "bold", fill: brown)[चलो ड्रैगन बनाएँ]
    #v(8pt)
    #text(size: 20pt)[Three steps. That's it.]
    #v(0.7in)
    #grid(columns: 3, gutter: 18pt,
      image("light/steps_kuku_s1.jpg", height: 2.2in),
      image("light/steps_kuku_s3.jpg", height: 2.2in),
      image("light/sheets_kuku.jpg", height: 2.2in))
    #v(0.5in)
    #block(width: 5in)[#text(size: 14pt)[
      #num(1) draw the two shapes lightly · #num(2) draw the edge around them · #num(3) colour it in
    ]]
  ]
]

#let simple(id, hindi, tip) = page[
  #align(center)[#text(size: 30pt, weight: "bold", fill: brown)[#hindi]]
  #v(4pt)
  #align(center)[#text(size: 13pt)[#tip]]
  #v(14pt)
  #grid(columns: 3, gutter: 12pt,
    ..((1, "light/steps_" + id + "_s1.jpg"), (2, "light/steps_" + id + "_s3.jpg"), (3, "light/sheets_" + id + ".jpg"))
      .map(p => block(width: 100%, height: 4.4in, stroke: 0.8pt + rgb("d8c9a0"), radius: 8pt, inset: 6pt)[
        #place(top + left, num(p.at(0)))
        #align(center + horizon)[#image(p.at(1), height: 3.9in)]
      ]))
  #v(16pt)
  #align(center)[#block(width: 6.4in, stroke: 1pt + rgb("d8c9a0"), radius: 8pt, inset: 12pt, height: 3.1in)[
    #align(left)[#text(size: 12pt, fill: rgb("8a7355"))[अब तुम बनाओ — your turn:]]
  ]]
]

#simple("leda", "लेडा", "All circles. Start here.")
#simple("castor", "कैस्टर", "Same as Leda, but with a big grin.")
#simple("kalu", "कालू", "Floppy ears, and a tail that wags.")
#simple("kuku", "कुकु", "Two little horns. Small wings — he is the littlest.")
#simple("vesper", "वैस्पर", "Sleepy eyes, only half open.")
#simple("furia", "फ्यूरिया", "She leans forward, like she is about to run.")
#simple("mitasur", "मिटासुर", "A pear shape, big leaf ears, one tooth showing.")
#simple("reechh", "रीछ", "One big oval, one small circle on top.")
#simple("dadi", "दादी माया", "Long neck, shawl, spectacles. The hardest one!")

#page[
  #align(center)[#text(size: 28pt, weight: "bold", fill: brown)[इसे 3D कैसे बनाएँ?]]
  #v(2pt)
  #align(center)[#text(size: 14pt)[Three things turn a flat drawing into a round one.]]
  #v(28pt)
  #grid(columns: 3, gutter: 16pt,
    ..(("d3_1","flat","Just a circle."),
       ("d3_2","+ shadow","A soft shadow down-right. Now it sits on the paper."),
       ("d3_3","+ light","Light on top, dark at the bottom, one white dot. Now it is a ball.")
      ).map(p => align(center)[
      #image("light/steps_" + p.at(0) + ".jpg", width: 2.1in)
      #v(6pt) #text(size: 14pt, weight: "bold")[#p.at(1)]
      #v(2pt) #text(size: 11pt)[#p.at(2)]
    ]))
  #v(30pt)
  #align(center)[#block(width: 6in)[#text(size: 14pt)[
    Do those three things to *every* shape you draw — the head, the tummy, even each toe —
    and always put the shadow on the *same side*. That is the whole trick.
  ]]]
]
