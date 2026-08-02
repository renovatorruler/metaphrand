#set page(width: 8.5in, height: 11in, margin: (x: 0.6in, y: 0.55in))
#set text(font: ("Kohinoor Devanagari", "Helvetica"), size: 11pt, fill: rgb("2e2418"))
#let gold = rgb("c07f00")
#let brown = rgb("46321e")
#let stepnum(n) = box(width: 26pt, height: 26pt, radius: 13pt, fill: gold,
  align(center + horizon, text(fill: white, weight: "bold", size: 15pt)[#n]))

// ---------- COVER ----------
#page[
  #align(center)[
    #v(1.1in)
    #text(size: 40pt, weight: "bold", fill: brown)[कुकु और अक्षर]
    #v(6pt)
    #text(size: 26pt, fill: gold, weight: "bold")[चलो ड्रैगन बनाएँ!]
    #v(2pt)
    #text(size: 17pt)[Let's Draw the Dragons — a step-by-step guide]
    #v(0.5in)
    #grid(columns: 3, gutter: 14pt,
      image("light/sheets_kuku.jpg", height: 2.5in),
      image("light/sheets_furia.jpg", height: 2.5in),
      image("light/sheets_vesper.jpg", height: 2.5in))
    #v(0.35in)
    #block(width: 5.6in)[
      #text(size: 13pt)[Every character here is drawn in *six small steps*, and each step
      adds only one new thing. The shapes on step 1 come from the
      real character art — so if you get the two circles right, the rest follows.]
    ]
  ]
]

// ---------- HOW TO USE ----------
#page[
  #text(size: 24pt, weight: "bold", fill: brown)[छह कदम — The Six Steps]
  #v(10pt)
  #grid(columns: (26pt, 1fr), gutter: 10pt, row-gutter: 13pt,
    stepnum(1), [*आकार — Two shapes.* A big circle for the head, an oval for the body. The grey
      lines mark the middle of the face and where the eyes sit. Press *soft* — these get rubbed out.],
    stepnum(2), [*हिस्से — The extra parts.* The grey blobs show exactly where the horns, ears,
      wings, tail and feet hang off those two shapes. Sketch them as simple lumps. Do not draw
      any detail yet.],
    stepnum(3), [*किनारा — One outline.* Now join it all up with a single line around the whole
      character. Stop here and compare — if the outline is right, everything else is easy.],
    stepnum(4), [*चेहरा — The face.* Eyes first, then the snout and mouth. This is the step that
      makes it *them*, so go slowly.],
    stepnum(5), [*रेखा — The last lines.* Tummy stripes, wing bones, toes, the line inside each ear.],
    stepnum(6), [*रंग — Colour and shade.* Colour it in, then use the 3D trick on the next page.],
  )
  #v(18pt)
  #line(length: 100%, stroke: 1pt + gold)
  #v(10pt)
  #text(size: 20pt, weight: "bold", fill: brown)[हर चीज़ इन आकारों से बनती है]
  #v(2pt)
  #text(size: 12pt)[Everything is made from these five shapes:]
  #v(8pt)
  #grid(columns: 5, gutter: 8pt,
    ..(("circle","गोला\nhead"),("oval","अंडा\nbody"),("teardrop","पंख\nwing"),
       ("triangle","सींग\nhorn / ear"),("sausage","हाथ-पैर\narm / leg / tail")).map(p => align(center)[
      #image("light/steps_shape_" + p.at(0) + ".jpg", width: 1.25in)
      #text(size: 10pt)[#p.at(1)]
    ]))
]

// ---------- THE 3D LESSON ----------
#page[
  #text(size: 24pt, weight: "bold", fill: brown)[इसे 3D कैसे बनाएँ? — Making it look 3D]
  #v(4pt)
  #text(size: 12pt)[Our show is made of *paper cut-outs stacked on top of each other*. That is the
  whole secret. Do these four things to any shape and it lifts off the page:]
  #v(14pt)
  #grid(columns: 4, gutter: 12pt,
    ..(("d3_1","1. सिर्फ़ रेखा","Just the outline — flat."),
       ("d3_2","2. नीचे छाया","Add a soft shadow down-right. Now it is sitting on the paper."),
       ("d3_3","3. ऊपर उजाला","Light band on top, dark band at the bottom, one white dot. Now it is round."),
       ("d3_4","4. काग़ज़ की परतें","Stack a few shapes with a shadow under each — that is our show's look.")
      ).map(p => align(center)[
      #image("light/steps_" + p.at(0) + ".jpg", width: 1.7in)
      #v(3pt)
      #text(size: 11pt, weight: "bold")[#p.at(1)]
      #v(1pt)
      #text(size: 9.5pt)[#p.at(2)]
    ]))
  #v(20pt)
  #block(fill: rgb("f7f2e6"), inset: 14pt, radius: 8pt, width: 100%)[
    #text(size: 13pt, weight: "bold", fill: brown)[याद रखो — Remember]
    #v(4pt)
    #text(size: 12pt)[The light in अक्षर घाटी always comes from the *top-left*. So every shadow
    goes *down and to the right*, and every highlight sits on the *upper-left* of a shape.
    Keep that the same everywhere and your drawing will look like it belongs in the show.]
  ]
]

// ---------- CHARACTER PAGES ----------
#let charpage(id, hindi, eng, stars, note) = page[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    [#text(size: 26pt, weight: "bold", fill: brown)[#hindi]
     #h(8pt) #text(size: 14pt, fill: rgb("8a7355"))[#eng]],
    text(size: 14pt, fill: gold)[#stars])
  #v(1pt)
  #text(size: 10.5pt)[#note]
  #v(8pt)
  #grid(columns: 3, rows: 2, gutter: 8pt,
    ..((1, id + "_s1"), (2, id + "_s2"), (3, id + "_s3"),
       (4, id + "_s4"), (5, id + "_s5"), (6, "light/sheets_" + id))
      .map(p => block(width: 100%, height: 4.05in, stroke: 0.7pt + rgb("d8c9a0"), radius: 6pt, inset: 5pt)[
        #place(top + left, stepnum(p.at(0)))
        #align(center + horizon)[#image(
          if p.at(0) == 6 { p.at(1) + ".jpg" } else { "light/steps_" + p.at(1) + ".jpg" },
          height: 3.6in)]
      ]))
]

#charpage("leda", "लेडा", "Leda", "★☆☆☆☆",
  "Start here! Leda is almost all circles — a big round head, a round tummy, two tiny wings. If you can draw a snowman, you can draw Leda.")
#charpage("castor", "कैस्टर", "Castor", "★☆☆☆☆",
  "Same round shapes as Leda, but give him a wider grin and little spikes down his back.")
#charpage("kalu", "कालू", "Kalu", "★★☆☆☆",
  "No wings, no horns — but watch the floppy ears and the tail. Kalu's head is almost as big as his body.")
#charpage("kuku", "कुकु", "Kuku", "★★☆☆☆",
  "Our hero. The two little horns and the tummy stripes are what make him Kuku. His wings are small — he is the littlest dragon.")
#charpage("vesper", "वैस्पर", "Vesper", "★★★☆☆",
  "Draw his eyes only half-open — he is always a little bit sleepy. His wings are wider than Kuku's.")
#charpage("furia", "फ्यूरिया", "Fyuria", "★★★☆☆",
  "Fyuria stands tall and leans forward, like she is about to run. Big wings, sharp little chin, and a long tail for balance.")
#charpage("mitasur", "मिटासुर", "Mitasur", "★★★☆☆",
  "A round pear shape, big ears like leaves, and those two fat sponge-hands. Do not forget one tooth sticking out!")
#charpage("reechh", "रीछ", "Reechh", "★★★★☆",
  "The bear is one huge oval with a smaller circle on top. All his fur is drawn as little rounded scallops — draw them in rows, like roof tiles.")
#charpage("dadi", "दादी माया", "Dadi Maya", "★★★★★",
  "The hardest one. Dadi is taller and thinner than the kids, with a long neck, a knitted shawl, big wings and spectacles. Save her for last!")

// ---------- TRACING PAGES ----------
#let tracepage(id, hindi) = page[
  #align(center)[
    #text(size: 20pt, weight: "bold", fill: brown)[#hindi #h(6pt) #text(size: 13pt, fill: rgb("8a7355"))[— trace me]]
  ]
  #v(4pt)
  #align(center)[#image("light/steps_" + id + "_trace.jpg", height: 8.4in)]
]
#tracepage("leda", "लेडा")
#tracepage("castor", "कैस्टर")
#tracepage("kalu", "कालू")
#tracepage("kuku", "कुकु")
#tracepage("vesper", "वैस्पर")
#tracepage("furia", "फ्यूरिया")
#tracepage("mitasur", "मिटासुर")
#tracepage("reechh", "रीछ")
#tracepage("dadi", "दादी माया")

// ---------- BACK ----------
#page[
  #align(center + horizon)[
    #text(size: 26pt, weight: "bold", fill: brown)[शाबाश!]
    #v(10pt)
    #text(size: 14pt)[Now draw them somewhere new: कुकु at the मेला, रीछ on the रथ,\
    मिटासुर washing his hands at the नल.]
    #v(20pt)
    #image("light/sheets_kuku.jpg", height: 2.6in)
    #v(14pt)
    #text(size: 12pt, fill: rgb("8a7355"))[अक्षर घाटी — Letter Valley]
  ]
]
